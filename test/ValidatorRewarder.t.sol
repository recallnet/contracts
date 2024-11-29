// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {ValidatorRewarder} from "../src/ValidatorRewarder.sol";
import {Hoku} from "../src/Hoku.sol";
import {DeployScript} from "../script/Hoku.s.sol";
import {SubnetID} from "../src/structs/Subnet.sol";
import {Consensus} from "../src/structs/Activity.sol";
import {SubnetIDHelper} from "../src/lib/SubnetIDHelper.sol";


contract ValidatorRewarderTest is Test {
    using SubnetIDHelper for SubnetID;
    ValidatorRewarder internal rewarder;
    Hoku internal token;
    address internal owner;
    address internal validator;
    address internal subnetActor;
    
    // Constants for testing
    uint64 private constant ROOTNET_CHAINID = 123;
    SubnetID subnet;
    SubnetID ROOT_SUBNET_ID = SubnetID(ROOTNET_CHAINID, new address[](0));    
    address constant SUBNET_ROUTE = address(101);
    uint64 constant CHECKPOINT_HEIGHT = 1000;
    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        owner = address(this);
        validator = address(0x123);
        subnetActor = address(0x456);
    
        // Deploy Hoku token using the deploy script
        DeployScript deployer = new DeployScript();
        token = deployer.run("local");
    
        // Deploy and initialize ValidatorRewarder
        rewarder = new ValidatorRewarder();
        rewarder.initialize();

        // Setup subnet
        subnet = ROOT_SUBNET_ID.createSubnetId(SUBNET_ROUTE);                    
        rewarder.setSubnet(subnet);

        // Get the deployer address which has the admin role
        address tokenDeployer = token.deployer();
        
        // Impersonate the deployer to grant MINTER_ROLE to rewarder
        vm.startPrank(tokenDeployer);
        token.grantRole(MINTER_ROLE, address(rewarder));
        vm.stopPrank();

        // Set token in rewarder
        rewarder.setToken(token);
    }

    function testInitialState() public {
        assertTrue(rewarder.isActive());
        assertEq(rewarder.owner(), address(this));
    }

    function testSetToken() public {
        rewarder.setToken(token);
        assertEq(address(rewarder.token()), address(token));
    }

    function testSetSubnet() public {
        uint64 result = rewarder.subnet();
        assertEq(result, subnet.root);
    }

    function testSetSubnetInvalidId() public {
        vm.expectRevert("root not allowed");
        rewarder.setSubnet(ROOT_SUBNET_ID);
    }

    function testNotifyValidClaim() public {
        // Setup subnet
        rewarder.setSubnet(subnet);

        // Setup token
        rewarder.setToken(token);

        // Create validator data
        Consensus.ValidatorData memory validatorData = Consensus.ValidatorData({
            validator: validator,
            blocksCommitted: 50
        });
                
        // Call notifyValidClaim as subnet actor
        vm.prank(subnet.route[0]);
        rewarder.notifyValidClaim(subnet, CHECKPOINT_HEIGHT, validatorData);

        // Check if validator received tokens (reward should equal blocksCommitted)
        assertEq(token.balanceOf(validator), 50);
    }

    function testNotifyValidClaimWrongSubnet() public {
        // Create a different subnet with same chain ID but different route
        address wrongRoute = address(0x789);
        SubnetID memory wrongSubnet = ROOT_SUBNET_ID.createSubnetId(wrongRoute);

        // Create validator data
        Consensus.ValidatorData memory validatorData = Consensus.ValidatorData({
            validator: validator,
            blocksCommitted: 50
        });

        // Call notifyValidClaim with wrong subnet - should fail
        vm.prank(wrongRoute);  // Impersonate the wrong subnet's actor
        vm.expectRevert("not my subnet");
        rewarder.notifyValidClaim(wrongSubnet, CHECKPOINT_HEIGHT, validatorData);

        // Verify no tokens were minted
        assertEq(token.balanceOf(validator), 0);
    }

    function testNotifyValidClaimWrongCaller() public {
        // Create validator data
        Consensus.ValidatorData memory validatorData = Consensus.ValidatorData({
            validator: validator,
            blocksCommitted: 50
        });

        // Call notifyValidClaim with wrong caller (not the subnet actor)
        address wrongCaller = address(0x999);
        vm.prank(wrongCaller);
        vm.expectRevert("not from subnet");
        rewarder.notifyValidClaim(subnet, CHECKPOINT_HEIGHT, validatorData);

        // Verify no tokens were minted
        assertEq(token.balanceOf(validator), 0);
    }

    function testSetActiveAndPause() public {
        assertTrue(rewarder.isActive());
        
        rewarder.setActive(false);
        assertFalse(rewarder.isActive());
        
        rewarder.setActive(true);
        assertTrue(rewarder.isActive());
    }

    function testSetActiveNotOwner() public {
        vm.prank(address(0x789));
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", address(0x789))
        );
        rewarder.setActive(false);
    }
} 