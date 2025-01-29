// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {InvalidSubnet, NotAuthorized, ValidatorPowerChangeDenied} from "../errors/IPCErrors.sol";
import {IValidatorGater} from "../interfaces/IValidatorGater.sol";

import {SubnetID} from "../types/CommonTypes.sol";
import {SubnetIDHelper} from "../util/SubnetIDHelper.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/// The power range that an approved validator can have.
/// @dev Using uint128 for min/max to pack them into a single storage slot
struct PowerRange {
    uint128 min;
    uint128 max;
}

/// This is a simple implementation of `IValidatorGater`. It makes sure the exact power change
/// request is approved. This is a very strict requirement.
contract ValidatorGater is IValidatorGater, UUPSUpgradeable, OwnableUpgradeable {
    using SubnetIDHelper for SubnetID;

    bool private _active;

    SubnetID public subnet;
    mapping(address => PowerRange) public allowed;
    // New active status and who was the owner at change time

    event ActiveStateChange(bool active, address account);

    error InvalidRouteLength();
    error InvalidRouteAddress(address invalidAddress);
    error ContractNotActive();

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
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
            revert ContractNotActive();
        }
        _;
    }

    function setSubnet(SubnetID calldata id) external onlyOwner whenActive {
        if (id.route.length == 0) {
            revert InvalidRouteLength();
        }

        for (uint256 i = 0; i < id.route.length; i++) {
            if (id.route[i] == address(0)) {
                revert InvalidRouteAddress(address(0));
            }
        }

        subnet = id;
    }

    function isAllow(address validator, uint256 power) public view whenActive returns (bool isAllowed) {
        PowerRange memory range = allowed[validator];
        isAllowed = range.min <= power && power <= range.max;
    }

    /// Only owner can approve the validator join request
    function approve(address validator, uint256 minPower, uint256 maxPower) external onlyOwner whenActive {
        allowed[validator] = PowerRange({min: uint128(minPower), max: uint128(maxPower)});
    }

    /// Revoke approved power range
    function revoke(address validator) external onlyOwner whenActive {
        delete allowed[validator];
    }

    function interceptPowerDelta(SubnetID memory id, address validator, uint256, /*prevPower*/ uint256 newPower)
        external
        view
        override
        whenActive
    {
        // unstake has checks to avoid newPower being zero, therefore zero means its leaving the network
        if (newPower == 0) return;

        SubnetID memory targetSubnet = subnet;

        if (!id.equals(targetSubnet)) {
            revert InvalidSubnet();
        }

        if (msg.sender != targetSubnet.getAddress()) {
            revert NotAuthorized(msg.sender);
        }

        if (!isAllow(validator, newPower)) {
            revert ValidatorPowerChangeDenied();
        }
    }

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract
    /// @param newImplementation Address of the new implementation contract
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {} // solhint-disable
        // no-empty-blocks
}
