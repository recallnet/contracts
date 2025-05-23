// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {DeployScript} from "../script/ValidatorGater.s.sol";

import {InvalidSubnet, NotAuthorized, ValidatorPowerChangeDenied} from "../src/errors/IPCErrors.sol";
import {SubnetID, ValidatorGater} from "../src/token/ValidatorGater.sol";
import {SubnetIDHelper} from "../src/util/SubnetIDHelper.sol";

import {SubnetActorManagerFacetMock} from "./mocks/SubnetActorManagerFacetMock.sol";
import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

contract ValidatorGaterTest is Test {
    using SubnetIDHelper for SubnetID;

    ValidatorGater internal gater;
    SubnetID internal subnet;
    address internal owner = address(1);
    address internal validator1 = address(2);
    address internal validator2 = address(3);
    uint64 internal constant ROOTNET_CHAINID = 123;
    SubnetID internal rootSubnetId = SubnetID(ROOTNET_CHAINID, new address[](0));
    address internal constant SUBNET_ROUTE = address(101);

    function setUp() public {
        DeployScript deployer = new DeployScript();
        gater = deployer.run();

        subnet = rootSubnetId.createSubnetId(SUBNET_ROUTE);
        owner = gater.owner();
        //  Set a subnet
        vm.startPrank(owner);
        gater.setSubnet(subnet);
        vm.stopPrank();
    }

    function testSetSubnet() public view {
        uint64 result = gater.subnet();

        assertEq(result, subnet.root);
    }

    function testApproveValidator() public {
        // Approve a validator's power range
        uint256 minPower = 10;
        uint256 maxPower = 100;

        vm.prank(owner);
        gater.approve(validator1, minPower, maxPower);

        // Verify that the validator's power range is set correctly
        (uint256 min, uint256 max) = gater.allowed(validator1);
        assertEq(min, minPower);
        assertEq(max, maxPower);
    }

    function testRevokeValidator() public {
        // Approve and then revoke the validator's power range
        vm.startPrank(owner);
        gater.approve(validator1, 10, 100);

        gater.revoke(validator1);

        // Ensure the validator's power range is deleted
        (uint256 min, uint256 max) = gater.allowed(validator1);
        assertEq(min, 0);
        assertEq(max, 0);
        vm.stopPrank();
    }

    function testIsAllowValidator() public {
        // Set validator power range
        uint256 minPower = 10;
        uint256 maxPower = 100;

        vm.prank(owner);
        gater.approve(validator1, minPower, maxPower);

        // Check if the validator is allowed within the range
        assertTrue(gater.isAllow(validator1, 50));
        assertFalse(gater.isAllow(validator1, 5)); // Below range
        assertFalse(gater.isAllow(validator1, 101)); // Above range
    }

    function testRevertWhenUnauthorizedApprove() public {
        // Non-owner should not be able to approve a validator
        vm.prank(validator2); // validator2 is not the owner
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", validator2));
        gater.approve(validator1, 10, 100);
    }

    function testInterceptPowerDelta() public {
        uint256 minPower = 10;
        uint256 maxPower = 100;

        vm.prank(owner);
        gater.approve(validator1, minPower, maxPower);

        // Intercept power delta with valid parameters
        vm.startPrank(SUBNET_ROUTE);
        gater.interceptPowerDelta(subnet, validator1, 0, 50);

        // Test invalid power change
        vm.expectRevert(ValidatorPowerChangeDenied.selector);
        gater.interceptPowerDelta(subnet, validator1, 0, 5); // out of range

        // Test invalid subnet
        SubnetID memory wrongSubnet = subnet = rootSubnetId.createSubnetId(address(this));
        vm.expectRevert(InvalidSubnet.selector);
        gater.interceptPowerDelta(wrongSubnet, validator1, 0, 50);
        vm.stopPrank();
    }

    function testUnactiveGater() public {
        // Must be possible to deactivate the gater
        vm.expectRevert();
        gater.setActive(false); // Not the owner
        assertEq(gater.isActive(), true);

        vm.prank(owner);
        gater.setActive(false);
        assertEq(gater.isActive(), false);

        // Test all functions with whenActive modifier
        vm.startPrank(owner);

        // Test approve
        vm.expectRevert(ValidatorGater.ContractNotActive.selector);
        gater.approve(validator1, 10, 10);

        // Test revoke
        vm.expectRevert(ValidatorGater.ContractNotActive.selector);
        gater.revoke(validator1);

        // Test setSubnet
        vm.expectRevert(ValidatorGater.ContractNotActive.selector);
        gater.setSubnet(subnet);

        // Test isAllow
        vm.expectRevert(ValidatorGater.ContractNotActive.selector);
        gater.isAllow(validator1, 100);

        // Test interceptPowerDelta
        vm.expectRevert(ValidatorGater.ContractNotActive.selector);
        gater.interceptPowerDelta(subnet, validator1, 0, 100);

        vm.stopPrank();

        // Verify storage state remains unchanged
        (uint256 min, uint256 max) = gater.allowed(validator1);
        assertEq(min, 0);
        assertEq(max, 0);
    }

    function testSubnetManagerIntegration() public {
        uint256 minStake = 5;
        uint256 maxStake = 100;
        // Deploy SAMf
        SubnetActorManagerFacetMock sa = new SubnetActorManagerFacetMock();

        sa.setValidatorGater(address(gater));
        SubnetID memory saSubnet = rootSubnetId.createSubnetId(address(sa));
        sa.setParentId(rootSubnetId);

        vm.startPrank(owner);
        gater.setSubnet(saSubnet);
        gater.approve(validator1, minStake, maxStake);
        gater.approve(validator2, minStake + 1, maxStake + 1);
        vm.stopPrank();
        // Join
        // Enforce Min Stake constrain
        vm.prank(validator1);
        vm.expectRevert();
        sa.join("", minStake - 1); // Cannot join if less than minimum

        assertEq(sa.getStakeAmount(validator1), 0, "Invalid stake amount after join, expected revert");

        vm.prank(validator1);
        sa.join("", minStake);

        assertEq(sa.getStakeAmount(validator1), minStake, "Invalid stake amount after join");
        // Different validators have different requirements
        vm.prank(validator2);
        vm.expectRevert();
        sa.join("", minStake); // Invalid range for validator #2

        assertEq(
            sa.getStakeAmount(validator2), 0, "Invalid stake amount after join, expected revert for second validator"
        );

        vm.prank(validator2);
        sa.join("", minStake + 1);

        assertEq(sa.getStakeAmount(validator2), minStake + 1, "Invalid stake amount after join for second validator");

        // Stake
        // Enforce Max Stake constrain
        vm.startPrank(validator1);
        sa.stake(maxStake - minStake); // Remaining amount before maxStake

        vm.expectRevert();
        sa.stake(maxStake + 1); // Cannot stake more than max amount

        assertEq(sa.getStakeAmount(validator1), maxStake, "Invalid stake amount after stake");
        // Unstake
        // Enforce Min Stake constrain
        sa.unstake(maxStake - minStake); // Remaining amount before min stake

        vm.expectRevert();
        sa.unstake(1); // The current stake is min Stake so should allow a single token withdraw

        assertEq(sa.getStakeAmount(validator1), minStake, "Invalid stake amount after unstake");
        // Leave
        sa.leave();

        assertEq(sa.getStakeAmount(validator1), 0, "Invalid stake amount after leave");
        vm.stopPrank();
    }
}
