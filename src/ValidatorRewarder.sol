// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {InvalidSubnet, NotAuthorized, ValidatorPowerChangeDenied} from "./errors/IPCErrors.sol";
import {IValidatorRewarder} from "./interfaces/IValidatorRewarder.sol";

import {Hoku} from "./Hoku.sol";
import {SubnetIDHelper} from "./lib/SubnetIDHelper.sol";
import {Consensus} from "./structs/Activity.sol";
import {SubnetID} from "./structs/Subnet.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";

/// @title ValidatorRewarder
/// @notice This contract is responsible for distributing rewards to validators.
/// @dev The rewarder is responsible for distributing the inflation to the validators.
/// @dev The rewarder is called by the subnet actor when a validator claims rewards.
contract ValidatorRewarder is IValidatorRewarder, UUPSUpgradeable, OwnableUpgradeable {
    using SubnetIDHelper for SubnetID;

    // ========== STATE VARIABLES ==========

    /// @notice Indicates whether the rewarder is active or not
    bool private _active;

    /// @notice The subnet that this rewarder is responsible for
    SubnetID public subnet;

    /// @notice The token that this rewarder mints
    Hoku public token;

    /// @notice The latest checkpoint height that rewards can be claimed for
    uint64 public latestClaimedCheckpoint;

    /// @notice The inflation rate for the subnet
    /// @dev The rate is expressed as a decimal*1e18.
    /// @dev For example 5% APY is 0.0000928276004952% yield per checkpoint period.
    /// @dev This is expressed as 928_276_004_952 or 0.000000928276004952*1e18.
    uint256 public inflationRate;

    /// @notice The bottomup checkpoint period for the subnet.
    /// @dev The checkpoint period is set when the subnet is created.
    uint256 public checkpointPeriod;

    /// @notice The supply of HOKU tokens at each checkpoint
    mapping(uint64 => uint256) public checkpointToSupply;

    // ========== EVENTS & ERRORS ==========

    event ActiveStateChange(bool active, address account);

    error SubnetMismatch(SubnetID id);
    error InvalidClaimNotifier(address notifier);
    error InvalidCheckpointHeight(uint64 claimedCheckpointHeight);
    error InvalidCheckpointPeriod(uint256 period);

    // ========== INITIALIZER ==========

    /// @notice Initializes the rewarder
    /// @param hokuToken The address of the HOKU token contract
    function initialize(address hokuToken) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        _active = true;
        token = Hoku(hokuToken);
    }

    /// @notice Sets the subnet and checkpoint period
    /// @dev Only the owner can set the subnet and period
    /// @param subnetId The subnet ID
    /// @param period The bottomup checkpoint period for the subnet
    function setSubnet(SubnetID calldata subnetId, uint256 period) external onlyOwner {
        if (period == 0) {
            revert InvalidCheckpointPeriod(period);
        }
        subnet = subnetId;
        checkpointPeriod = period;
    }

    // ========== PUBLIC FUNCTIONS ==========

    /// @notice Modifier to ensure the contract is active
    modifier whenActive() {
        if (!_active) {
            return; // Skip execution if not active
        }
        _; // Continue with function execution if active
    }

    /// @notice Indicates whether the gate is active or not
    function isActive() external view returns (bool) {
        return _active;
    }

    /// @notice Sets the contract as active or inactive.
    /// @dev Only the owner can change the active state.
    /// @param active The new active state
    function setActive(bool active) external onlyOwner {
        _active = active;
        emit ActiveStateChange(active, msg.sender);
    }

    /// @notice Sets the inflation rate for the subnet.
    /// @dev Only the owner can set the inflation rate, and only when the contract is active
    /// @param rate The new inflation rate
    function setInflationRate(uint256 rate) external onlyOwner whenActive {
        inflationRate = rate;
    }

    /// @notice Notifies the rewarder that a validator has claimed a reward.
    /// @dev Only the subnet actor can notify the rewarder, and only when the contract is active.
    /// @param id The subnet that the validator belongs to
    /// @param claimedCheckpointHeight The height of the checkpoint that the validator is claiming for
    /// @param data The validator data for the claimed checkpoint
    function notifyValidClaim(
        SubnetID calldata id,
        uint64 claimedCheckpointHeight,
        Consensus.ValidatorData calldata data
    ) external override whenActive {
        // Check that the rewarder is responsible for the subnet that the validator is claiming rewards for
        if (keccak256(abi.encode(id)) != keccak256(abi.encode(subnet))) {
            revert SubnetMismatch(id);
        }

        // Check that the caller is the subnet actor for the subnet that the validator is claiming rewards for
        if (id.route[id.route.length - 1] != msg.sender) {
            revert InvalidClaimNotifier(msg.sender);
        }

        // When the supply for the checkpoint is 0, it means that this is the first claim
        // for this checkpoint.
        // In this case we will set the supply for the checkpoint and
        // calculate the inflation and mint the rewards to the rewarder and the first claimant.
        // Otherwise, we know the supply for the checkpoint.
        // We will calculate the rewards and transfer them to the other claimants for this checkpoint.
        uint256 supplyAtCheckpoint = checkpointToSupply[claimedCheckpointHeight];
        if (supplyAtCheckpoint == 0) {
            // Check that the checkpoint height is valid.
            if (!validateCheckpointHeight(claimedCheckpointHeight)) {
                revert InvalidCheckpointHeight(claimedCheckpointHeight);
            }

            // Get the current supply of HOKU tokens
            uint256 currentSupply = token.totalSupply();

            // Set the supply for the checkpoint
            checkpointToSupply[claimedCheckpointHeight] = currentSupply;
            // Calculate the inflation amount for __this__ checkpoint
            uint256 supplyDelta = calculateInflationForCheckpoint(currentSupply);
            // Calculate the validator's share of the inflation for __this__ checkpoint
            uint256 validatorShare = calculateValidatorShare(data.blocksCommitted, supplyDelta);
            // Mint the supply delta minus current validator's share to the Rewarder
            token.mint(address(this), supplyDelta - validatorShare);
            // Mint the validator's share to the validator
            token.mint(data.validator, validatorShare);
            // Update the latest claimable checkpoint.
            latestClaimedCheckpoint = claimedCheckpointHeight;
        } else {
            // Calculate the supply delta for the checkpoint
            uint256 supplyDelta = calculateInflationForCheckpoint(supplyAtCheckpoint);
            // Calculate the validator's share of the supply delta
            uint256 validatorShare = calculateValidatorShare(data.blocksCommitted, supplyDelta);
            // Transfer the validator's share of the supply delta to the validator
            token.transfer(data.validator, validatorShare);
        }
    }

    // ========== INTERNAL FUNCTIONS ==========

    /// @notice The internal method to calculate the supply delta for a checkpoint
    /// @param supply The token supply at the checkpoint
    /// @return The supply delta, i.e. the amount of new tokens minted for the checkpoint
    function calculateInflationForCheckpoint(uint256 supply) internal view returns (uint256) {
        UD60x18 supplyFixed = ud(supply);
        UD60x18 inflationRateFixed = ud(inflationRate);
        UD60x18 result = supplyFixed.mul(inflationRateFixed);
        return result.unwrap();
    }

    /// @notice The internal method to calculate the validator's share of the supply delta
    /// @param blocksCommitted The number of blocks committed by the validator
    /// @param supplyDelta The supply delta, i.e. the amount of new tokens minted for the checkpoint
    /// @return The validator's share of the supply delta
    function calculateValidatorShare(uint256 blocksCommitted, uint256 supplyDelta) internal view returns (uint256) {
        UD60x18 blocksFixed = ud(blocksCommitted);
        UD60x18 deltaFixed = ud(supplyDelta);
        UD60x18 periodFixed = ud(checkpointPeriod);
        UD60x18 share = blocksFixed.div(periodFixed);
        UD60x18 result = share.mul(deltaFixed);
        return result.unwrap();
    }

    /// @notice Validates that the claimed checkpoint height is valid
    /// @param claimedCheckpointHeight The height of the checkpoint that the validator is claiming for
    /// @return True if the checkpoint height is valid, false otherwise
    /// @dev When the latest claimable checkpoint is not set (0), it means that _this_ is the first ever claim.
    /// @dev In this case we need not check that the claimed checkpoint is in the future.
    /// @dev Otherwise, we must ensure that the claimed checkpoint is in the future.
    function validateCheckpointHeight(uint64 claimedCheckpointHeight) internal view returns (bool) {
        if (latestClaimedCheckpoint == 0) {
            return true;
        }
        return claimedCheckpointHeight == latestClaimedCheckpoint + checkpointPeriod;
    }

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract
    /// @param newImplementation Address of the new implementation contract
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {} // solhint-disable
        // no-empty-blocks
}
