// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {IValidatorRewarder} from "../interfaces/IValidatorRewarder.sol";

import {Consensus, SubnetID} from "../types/CommonTypes.sol";
import {SubnetIDHelper} from "../util/SubnetIDHelper.sol";
import {Recall} from "./Recall.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";

/// @title ValidatorRewarder
/// @notice This contract is responsible for distributing rewards to validators.
/// @dev The rewarder is responsible for distributing the inflation to the validators.
/// @dev The rewarder is called by the subnet actor when a validator claims rewards.
contract ValidatorRewarder is IValidatorRewarder, UUPSUpgradeable, OwnableUpgradeable {
    using SubnetIDHelper for SubnetID;
    using SafeERC20 for Recall;

    // ========== STATE VARIABLES ==========

    /// @notice Indicates whether the rewarder is active or not
    bool private _active;

    /// @notice The subnet that this rewarder is responsible for
    SubnetID public subnet;

    /// @notice The token that this rewarder mints
    Recall public token;

    /// @notice The bottomup checkpoint period for the subnet.
    /// @dev The checkpoint period is set when the subnet is created.
    uint256 public checkpointPeriod;

    /// @notice The number of blocks required to generate 1 new HOKU token (with 18 decimals)
    uint256 public constant BLOCKS_PER_TOKEN = 3;

    // ========== EVENTS & ERRORS ==========

    event ActiveStateChange(bool active, address account);
    event SubnetUpdated(SubnetID subnet, uint256 checkpointPeriod);
    /// @notice Emitted when a validator claims their rewards for a checkpoint
    /// @param checkpointHeight The height of the checkpoint for which rewards are claimed
    /// @param validator The address of the validator claiming rewards
    /// @param amount The amount of tokens claimed as reward
    event RewardsClaimed(uint64 indexed checkpointHeight, address indexed validator, uint256 amount);

    error SubnetMismatch(SubnetID id);
    error InvalidClaimNotifier(address notifier);
    error InvalidCheckpointHeight(uint64 claimedCheckpointHeight);
    error InvalidCheckpointPeriod(uint256 period);
    error InvalidTokenAddress(address token);
    error InvalidValidatorAddress(address validator);
    error ContractNotActive();

    // ========== INITIALIZER ==========

    /// @notice Initializes the rewarder
    /// @param recallToken The address of the RECALL token contract
    function initialize(address recallToken) public initializer {
        if (recallToken == address(0)) {
            revert InvalidTokenAddress(recallToken);
        }
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        _active = true;
        token = Recall(recallToken);
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
        emit SubnetUpdated(subnetId, period);
    }

    // ========== PUBLIC FUNCTIONS ==========

    /// @notice Modifier to ensure the contract is active
    modifier whenActive() {
        if (!_active) {
            revert ContractNotActive();
        }
        _;
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
        if (data.validator == address(0)) {
            revert InvalidValidatorAddress(data.validator);
        }
        // Check that the rewarder is responsible for the subnet that the validator is claiming rewards for
        if (keccak256(abi.encode(id)) != keccak256(abi.encode(subnet))) {
            revert SubnetMismatch(id);
        }

        // Check that the caller is the subnet actor for the subnet that the validator is claiming rewards for
        if (id.route[id.route.length - 1] != msg.sender) {
            revert InvalidClaimNotifier(msg.sender);
        }

        // Check that the checkpoint height is valid
        if (!validateCheckpointHeight(claimedCheckpointHeight)) {
            revert InvalidCheckpointHeight(claimedCheckpointHeight);
        }

        // Calculate rewards for this checkpoint
        uint256 newTokens = calculateNewTokensForCheckpoint();
        uint256 validatorShare = calculateValidatorShare(data.blocksCommitted, newTokens);

        // Mint the validator's share directly
        token.mint(data.validator, validatorShare);
        emit RewardsClaimed(claimedCheckpointHeight, data.validator, validatorShare);
    }

    // ========== INTERNAL FUNCTIONS ==========

    /// @notice Calculates the total number of new tokens to be minted for a checkpoint
    /// @return The number of new tokens to be minted (in base units with 18 decimals)
    function calculateNewTokensForCheckpoint() internal view returns (uint256) {
        UD60x18 blocksPerToken = ud(BLOCKS_PER_TOKEN);
        UD60x18 period = ud(checkpointPeriod);
        UD60x18 oneToken = ud(1 ether);
        
        // Calculate (checkpointPeriod * 1 ether) / BLOCKS_PER_TOKEN using fixed-point math
        return period.mul(oneToken).div(blocksPerToken).unwrap();
    }

    /// @notice The internal method to calculate the validator's share of the new tokens
    /// @param blocksCommitted The number of blocks committed by the validator
    /// @param totalNewTokens The total number of new tokens for the checkpoint
    /// @return The validator's share of the new tokens
    function calculateValidatorShare(uint256 blocksCommitted, uint256 totalNewTokens) internal view returns (uint256) {
        UD60x18 blocks = ud(blocksCommitted);
        UD60x18 tokens = ud(totalNewTokens);
        UD60x18 period = ud(checkpointPeriod);
        UD60x18 share = blocks.div(period);
        UD60x18 result = share.mul(tokens);
        return result.unwrap();
    }

    /// @notice Validates that the claimed checkpoint height is valid
    /// @param claimedCheckpointHeight The height of the checkpoint that the validator is claiming for
    /// @return True if the checkpoint height is valid, false otherwise
    /// @dev Ensures the checkpoint height is a multiple of the checkpoint period
    function validateCheckpointHeight(uint64 claimedCheckpointHeight) internal view returns (bool) {
        return claimedCheckpointHeight > 0 && claimedCheckpointHeight % checkpointPeriod == 0;
    }

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract
    /// @param newImplementation Address of the new implementation contract
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {} // solhint-disable
        // no-empty-blocks
}
