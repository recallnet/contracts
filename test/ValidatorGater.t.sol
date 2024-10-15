// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {ValidatorGater, SubnetID} from "../src/ValidatorGater.sol";
import {SubnetIDHelper} from "../src/lib/SubnetIDHelper.sol";
import {Utilities} from "../src/Utilities.sol";
import {DeployScript} from "../script/ValidatorGater.s.sol";
import {InvalidSubnet, NotAuthorized, ValidatorPowerChangeDenied} from "../src/errors/IPCErrors.sol";
import {SubnetActorManagerFacetMock} from "./mocks/SubnetActorManagerFacetMock.sol";

contract ValidatorGaterTest is Test, Utilities {
    using SubnetIDHelper for SubnetID;

    ValidatorGater internal gater;
    SubnetID subnet;
    address owner = address(1);
    address validator1 = address(2);
    address validator2 = address(3);
    uint64 private constant ROOTNET_CHAINID = 123;
    SubnetID ROOT_SUBNET_ID = SubnetID(ROOTNET_CHAINID, new address[](0));
    address constant SUBNET_ROUTE = address(101);

    function setUp() public {
        DeployScript deployer = new DeployScript();
        gater = deployer.run(Environment.Local);

        subnet = ROOT_SUBNET_ID.createSubnetId(SUBNET_ROUTE);
        owner = gater.owner();
        //  Set a subnet
        vm.prank(owner);
        gater.setSubnet(subnet);
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

    function testFailUnauthorizedApprove() public {
        // Non-owner should not be able to approve a validator
        vm.prank(validator2); // validator2 is not the owner
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
        SubnetID memory wrongSubnet = subnet = ROOT_SUBNET_ID.createSubnetId(address(this));
        vm.expectRevert(InvalidSubnet.selector);
        gater.interceptPowerDelta(wrongSubnet, validator1, 0, 50);
        vm.stopPrank();
    }

    function testUnactiveGater() public {
        address validator = address(4);
        // Must be possible to desactivate the gater
        vm.expectRevert();
        gater.setActive(false);// Not the owner
        assertEq(gater.isActive(), true);

        vm.prank(owner);
        gater.setActive(false);
        assertEq(gater.isActive(), false);


        // Must not execute functions if inactive
        vm.startPrank(owner);
        gater.approve(validator1, 10, 10);

        (uint256 min, uint256 max) = gater.allowed(validator);
        assertEq(min, 0);
        assertEq(max, 0);

        vm.stopPrank();
    }


    function testSubnetManagerIntegration() public {
        uint256 minStake = 5;
        uint256 maxStake = 100;//TODO handle different values for differnt validators
        // Deploy SAMf
        SubnetActorManagerFacetMock sa = new SubnetActorManagerFacetMock();

        sa.setValidatorGater(address(gater));
        SubnetID memory saSubnet = ROOT_SUBNET_ID.createSubnetId(address(sa));
        sa.setParentId(ROOT_SUBNET_ID);

        vm.startPrank(owner);
        gater.setSubnet(saSubnet);
        gater.approve(validator1, minStake, maxStake);
        vm.stopPrank();
        // Join
        // Enforce Min Stake constrain
        vm.prank(validator1);
        vm.expectRevert();
        sa.join("", minStake - 1);// Cannot join if less than minimum

        assertEq(sa.getStakeAmount(validator1), 0, "Invalid stake amount after join, expected revert");

        vm.prank(validator1);
        sa.join("", minStake);

        assertEq(sa.getStakeAmount(validator1), minStake, "Invalid stake amount after join");
    
        // Stake
        // Enforce Max Stake constrain
        vm.startPrank(validator1);
        sa.stake(maxStake - minStake);// Remaining amount before maxStake

        vm.expectRevert();
        sa.stake(maxStake + 1);// Cannot stake more than max amount

        assertEq(sa.getStakeAmount(validator1), maxStake, "Invalid stake amount after stake");
        // Unstake
        // Enforce Min Stake constrain
        sa.unstake(maxStake - minStake);// Remaining amount before min stake

        vm.expectRevert();
        sa.unstake(1);// The current stake is min Stake so should allow a single token withdraw

        assertEq(sa.getStakeAmount(validator1), minStake, "Invalid stake amount after unstake");
        // Leave
        sa.leave();//TODO cehck this one

        assertEq(sa.getStakeAmount(validator1), 0, "Invalid stake amount after leave");
        vm.stopPrank();
    }
}
