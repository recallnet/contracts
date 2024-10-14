// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {IValidatorGater} from "./interfaces/IValidatorGater.sol";
import {InvalidSubnet, NotAuthorized, ValidatorPowerChangeDenied} from "./errors/IPCErrors.sol";
import {SubnetID} from "./structs/Subnet.sol";
import {SubnetIDHelper} from "./lib/SubnetIDHelper.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

/// The power range that an approved validator can have.
struct PowerRange {
    uint256 min;
    uint256 max;
}
// TODO add notice to all functions
/// This is a simple implementation of `IValidatorGater`. It makes sure the exact power change
/// request is approved. This is a very strict requirement.

contract ValidatorGater is IValidatorGater, Ownable {
    using SubnetIDHelper for SubnetID;

    bool private _active;

    SubnetID public subnet;
    mapping(address => PowerRange) public allowed;
    // New active status and who was the owner at change time

    event ActiveStateChange(bool active, address account);

    constructor() Ownable(msg.sender) {
        _active = true;
    }

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
        subnet = id;
    }

    function isAllow(address validator, uint256 power) public view whenActive returns (bool) {
        PowerRange memory range = allowed[validator];
        return range.min <= power && power <= range.max;
    }

    /// Only owner can approve the validator join request
    function approve(address validator, uint256 minPower, uint256 maxPower) external onlyOwner whenActive {
        allowed[validator] = PowerRange({min: minPower, max: maxPower});
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
}
