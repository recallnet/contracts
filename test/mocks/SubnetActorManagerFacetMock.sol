// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {IValidatorGater} from "../../src/interfaces/IValidatorGater.sol";

import {SubnetIDHelper} from "../../src/lib/SubnetIDHelper.sol";
import {SubnetID} from "../../src/structs/Subnet.sol";

/// A simplified mock of the Subnet Actor Manager Facet, where any power change can occur (join, stake, unstake, leave).
/// All security checks were removed due to them not being relevant for the workflow being tested.
contract SubnetActorManagerFacetMock {
    using SubnetIDHelper for SubnetID;

    address validatorGater;
    mapping(address => uint256) validatorsStake;
    SubnetID parentId;

    function getStakeAmount(address validator) public view returns (uint256) {
        return validatorsStake[validator];
    }

    function setValidatorGater(address gater) external {
        validatorGater = gater;
    }

    function setParentId(SubnetID calldata id) external {
        parentId = id;
    }

    /// @notice method that allows a validator to join the subnet.
    ///         If the total confirmed collateral of the subnet is greater
    ///         or equal to minimum activation collateral as a result of this operation,
    ///         then  subnet will be registered.
    /// @param amount The amount of collateral provided as stake
    function join(bytes calldata, uint256 amount) external payable {
        gateValidatorPowerDelta(msg.sender, 0, amount);
        validatorsStake[msg.sender] = amount;
    }

    /// @notice method that allows a validator to increase its stake.
    ///         If the total confirmed collateral of the subnet is greater
    ///         or equal to minimum activation collateral as a result of this operation,
    ///         then  subnet will be registered.
    /// @param amount The amount of collateral provided as stake
    function stake(uint256 amount) external payable {
        uint256 collateral = getStakeAmount(msg.sender);
        gateValidatorPowerDelta(msg.sender, collateral, collateral + amount);
        validatorsStake[msg.sender] += amount;
    }

    /// @notice method that allows a validator to unstake a part of its collateral from a subnet.
    /// @dev `leave` must be used to unstake the entire stake.
    /// @param amount The amount to unstake.
    function unstake(uint256 amount) external {
        uint256 collateral = getStakeAmount(msg.sender);
        gateValidatorPowerDelta(msg.sender, collateral, collateral - amount);
        validatorsStake[msg.sender] -= amount;
    }

    /// @notice method that allows a validator to leave the subnet.
    function leave() external {
        uint256 collateral = getStakeAmount(msg.sender);
        gateValidatorPowerDelta(msg.sender, collateral, 0);
        validatorsStake[msg.sender] = 0;
    }

    /// @notice Performs validator gating, i.e. checks if the validator power update is actually allowed.
    /// In the real contract this function belongs to the LibSubnetActor library
    function gateValidatorPowerDelta(address validator, uint256 oldPower, uint256 newPower) internal {
        // zero address means no gating needed
        if (validatorGater == address(0)) {
            return;
        }

        SubnetID memory id = parentId.createSubnetId(address(this));
        IValidatorGater(validatorGater).interceptPowerDelta(id, validator, oldPower, newPower);
    }
}
