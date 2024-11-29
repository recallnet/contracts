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

/// This is a simple implementation of `IValidatorRewarder`. It makes sure the exact power change
/// request is approved. This is a very strict requirement.
contract ValidatorRewarder is IValidatorRewarder, UUPSUpgradeable, OwnableUpgradeable {
    using SubnetIDHelper for SubnetID;

    bool private _active;

    SubnetID public subnet;
    Hoku public token;

    event ActiveStateChange(bool active, address account);

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        _active = true;
    }

    /// @notice Indicates whether the gate is active or not
    function isActive() external view returns (bool) {
        return _active;
    }

    /// @notice Sets the contract as active or inactive.
    /// @dev Only the owner can change the active state.
    function setActive(bool active) external onlyOwner {
        _active = active;
        emit ActiveStateChange(active, msg.sender);
    }

    modifier whenActive() {
        if (!_active) {
            return; // Skip execution if not active
        }
        _; // Continue with function execution if active
    }

    function setSubnet(SubnetID calldata id) external onlyOwner whenActive {
        require(id.route.length > 0, "root not allowed");
        subnet = id;
    }

    function setToken(Hoku _token) external onlyOwner whenActive {
        token = _token;
    }

    function notifyValidClaim(SubnetID calldata id, uint64 checkpointHeight, Consensus.ValidatorData calldata data)
        external
        override
    {
        require(keccak256(abi.encode(id)) == keccak256(abi.encode(subnet)), "not my subnet");

        address actor = id.route[id.route.length - 1];
        require(actor == msg.sender, "not from subnet");

        uint256 reward = calculateReward(data, checkpointHeight);

        token.mint(data.validator, reward);
    }

    /// @notice The internal method to derive the amount of reward that each validator should receive
    ///         based on their subnet activities
    function calculateReward(Consensus.ValidatorData calldata data, uint64) internal pure returns (uint256) {
        // Reward is the same as blocks mined for convenience.
        return data.blocksCommitted;
    }

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract
    /// @param newImplementation Address of the new implementation contract
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {} // solhint-disable
        // no-empty-blocks
}
