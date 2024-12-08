// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {DeployScript as HokuDeployScript} from "../script/Hoku.s.sol";
import {DeployScript as ValidatorRewarderDeployScript} from "../script/ValidatorRewarder.s.sol";
import {Hoku} from "../src/Hoku.sol";
import {ValidatorRewarder} from "../src/ValidatorRewarder.sol";
import {SubnetIDHelper} from "../src/lib/SubnetIDHelper.sol";
import {Consensus} from "../src/structs/Activity.sol";
import {SubnetID} from "../src/structs/Subnet.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

// Base contract with common setup and helper functions
abstract contract ValidatorRewarderTestBase is Test {
    using SubnetIDHelper for SubnetID;

    ValidatorRewarder internal rewarder;
    address internal rewarderOwner;
    Hoku internal token;
    address internal subnetActor;

    // Constants
    uint64 internal constant ROOTNET_CHAINID = 123;
    address internal constant SUBNET_ROUTE = address(101);
    uint256 internal constant CHECKPOINT_PERIOD = 600;

    function setUp() public virtual {
        subnetActor = address(0x456);

        // Deploy Hoku token
        HokuDeployScript hokuDeployer = new HokuDeployScript();
        token = hokuDeployer.run("local");

        // Create subnet for initialization
        SubnetID memory subnet = createSubnet();

        // Deploy ValidatorRewarder with initialization params
        ValidatorRewarderDeployScript rewarderDeployer = new ValidatorRewarderDeployScript();
        rewarder = rewarderDeployer.runWithParams("local", address(token), subnet, CHECKPOINT_PERIOD);
        rewarderOwner = rewarder.owner();
        // Grant MINTER_ROLE to Rewarder for Hoku tokens
        vm.startPrank(token.deployer());
        token.grantRole(token.MINTER_ROLE(), address(rewarder));
        vm.stopPrank();

        // Mint initial supply of Hoku tokens to a random address
        vm.startPrank(rewarderOwner);
        token.mint(address(0x888), 1000e18);
        vm.stopPrank();
    }

    // Helper function to create validator data
    function createValidatorData(address validator, uint256 blocksCommitted)
        internal
        pure
        returns (Consensus.ValidatorData memory)
    {
        return Consensus.ValidatorData({validator: validator, blocksCommitted: uint64(blocksCommitted)});
    }

    // Helper function to create subnet
    function createSubnet() internal pure returns (SubnetID memory) {
        SubnetID memory rootSubnet = SubnetID(ROOTNET_CHAINID, new address[](0));
        return rootSubnet.createSubnetId(SUBNET_ROUTE);
    }
}

// Test contract for initial state and basic functionality
contract ValidatorRewarderInitialStateTest is ValidatorRewarderTestBase {
    function testInitialState() public {
        assertTrue(rewarder.isActive());
        assertEq(rewarder.subnet(), createSubnet().root);
        assertEq(address(rewarder.token()), address(token));
        assertEq(rewarder.inflationRate(), rewarder.DEFAULT_INFLATION_RATE());
    }
}

// Test contract for active/pause functionality
contract ValidatorRewarderActiveStateTest is ValidatorRewarderTestBase {
    function testSetActiveNotOwner() public {
        vm.startPrank(address(0x789));
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", address(0x789)));
        rewarder.setActive(true);
        vm.stopPrank();
    }

    function testSetActiveAndPauseAsOwner() public {
        assertTrue(rewarder.isActive());

        vm.startPrank(rewarderOwner);
        rewarder.setActive(false);
        vm.stopPrank();
        assertFalse(rewarder.isActive());

        vm.startPrank(rewarderOwner);
        rewarder.setActive(true);
        vm.stopPrank();
        assertTrue(rewarder.isActive());
    }
}

// Test contract for subnet management
contract ValidatorRewarderSubnetTest is ValidatorRewarderTestBase {
    using SubnetIDHelper for SubnetID;

    function testInitialSubnetSetup() public {
        SubnetID memory expectedSubnet = createSubnet();
        assertEq(rewarder.subnet(), expectedSubnet.root);
        assertEq(rewarder.checkpointPeriod(), CHECKPOINT_PERIOD);
    }

    function testInitializeWithInvalidPeriod() public {
        // Deploy a new instance without initialization
        ValidatorRewarder newRewarder = new ValidatorRewarder();
        SubnetID memory subnet = createSubnet();
        // Try to initialize with invalid period
        vm.expectRevert(abi.encodeWithSelector(ValidatorRewarder.InvalidCheckpointPeriod.selector, 0));
        newRewarder.initialize(
            address(token),
            subnet,
            0 // invalid period
        );
    }

    function testCannotInitializeTwice() public {
        SubnetID memory subnet = createSubnet();

        // The error is now "InvalidInitialization()" in newer OZ versions
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        rewarder.initialize(address(token), subnet, CHECKPOINT_PERIOD);
    }
}

// Token management tests
contract ValidatorRewarderTokenTest is ValidatorRewarderTestBase {
    function testInitialTokenSetup() public {
        assertEq(address(rewarder.token()), address(token));
    }
}

// Inflation rate management tests
contract ValidatorRewarderInflationTest is ValidatorRewarderTestBase {
    function testSetInflationRateNotOwner() public {
        vm.startPrank(address(0x789));
        uint256 newRate = rewarder.DEFAULT_INFLATION_RATE() * 2;
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", address(0x789)));
        rewarder.setInflationRate(newRate);
        vm.stopPrank();
    }

    function testSetInflationRateFromDefault() public {
        // Verify we start with default rate
        assertEq(rewarder.inflationRate(), rewarder.DEFAULT_INFLATION_RATE());

        // Owner can change the rate
        uint256 newRate = rewarder.DEFAULT_INFLATION_RATE() * 2;
        vm.startPrank(rewarderOwner);
        rewarder.setInflationRate(newRate);
        vm.stopPrank();
        assertEq(rewarder.inflationRate(), newRate);
    }

    function testSetInflationRateWhenNotActive() public {
        vm.startPrank(rewarderOwner);
        rewarder.setActive(false);
        vm.stopPrank();

        vm.startPrank(rewarderOwner);
        uint256 oldRate = rewarder.inflationRate();
        uint256 newRate = oldRate * 2;
        rewarder.setInflationRate(newRate);
        vm.stopPrank();

        // Rate should not change when rewarder is not active
        assertEq(rewarder.inflationRate(), oldRate);
    }

    function testSetInflationRateAsOwner() public {
        // Set new inflation rate as owner
        vm.startPrank(rewarderOwner);
        uint256 newRate = rewarder.DEFAULT_INFLATION_RATE() * 2;
        rewarder.setInflationRate(newRate);
        vm.stopPrank();
        assertEq(rewarder.inflationRate(), newRate);
    }
}

// Basic claim notification tests
contract ValidatorRewarderBasicClaimTest is ValidatorRewarderTestBase {
    using SubnetIDHelper for SubnetID;

    function testNotifyValidClaimWhenNotActive() public {
        vm.startPrank(rewarderOwner);
        rewarder.setActive(false);
        vm.stopPrank();

        address claimant = address(0x999);
        Consensus.ValidatorData memory validatorData = createValidatorData(claimant, 100);

        rewarder.notifyValidClaim(createSubnet(), 600, validatorData);
        assertEq(token.balanceOf(claimant), 0);
    }

    function testNotifyValidClaimInvalidSubnet() public {
        SubnetID memory wrongSubnet = SubnetID(ROOTNET_CHAINID, new address[](0)).createSubnetId(address(0x123));

        address claimant = address(0x999);
        Consensus.ValidatorData memory validatorData = createValidatorData(claimant, 10);

        vm.startPrank(subnetActor);
        vm.expectRevert(abi.encodeWithSelector(ValidatorRewarder.SubnetMismatch.selector, wrongSubnet));
        rewarder.notifyValidClaim(wrongSubnet, 10, validatorData);
        vm.stopPrank();
        assertEq(token.balanceOf(claimant), 0);
    }

    function testNotifyValidClaimWrongNotifier() public {
        address claimant = address(0x999);
        Consensus.ValidatorData memory validatorData = createValidatorData(claimant, 50);

        address wrongNotifier = address(0x999);
        vm.startPrank(wrongNotifier);
        vm.expectRevert(abi.encodeWithSelector(ValidatorRewarder.InvalidClaimNotifier.selector, wrongNotifier));
        rewarder.notifyValidClaim(createSubnet(), 600, validatorData);
        vm.stopPrank();
        assertEq(token.balanceOf(claimant), 0);
    }
}

// Complex claim notification tests
contract ValidatorRewarderComplexClaimTest is ValidatorRewarderTestBase {
    function testNotifyValidClaimFirstClaim() public {
        address claimant = address(0x999);
        Consensus.ValidatorData memory validatorData = createValidatorData(claimant, 50);

        uint256 initialSupply = token.totalSupply();

        // Check initial state
        assertTrue(rewarder.isActive());
        assertEq(rewarder.latestClaimableCheckpoint(), 0);
        assertEq(token.balanceOf(address(rewarder)), 0);
        assertEq(token.totalSupply(), initialSupply);

        // First claim
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 1200, validatorData);
        vm.stopPrank();

        // Verify rewards
        assertApproxEqAbs(token.balanceOf(claimant), 77356333746022, 1000);
        assertApproxEqAbs(token.balanceOf(address(rewarder)), 850919671206244, 1000);

        // Verify total inflation
        uint256 totalInflation = token.totalSupply() - initialSupply;
        assertApproxEqAbs(totalInflation, 850919671206244 + 77356333746022, 1000);

        // Verify checkpoint
        assertEq(rewarder.latestClaimableCheckpoint(), 1200);

        // Test invalid next checkpoint
        vm.startPrank(SUBNET_ROUTE);
        vm.expectRevert(abi.encodeWithSelector(ValidatorRewarder.InvalidCheckpointHeight.selector, 2400));
        rewarder.notifyValidClaim(createSubnet(), 2400, validatorData);
        vm.stopPrank();
    }

    function testNotifyValidClaimSubsequentClaims() public {
        address[] memory claimants = new address[](3);
        claimants[0] = address(0x111);
        claimants[1] = address(0x222);
        claimants[2] = address(0x333);

        uint256[] memory blocks = new uint256[](3);
        blocks[0] = 100;
        blocks[1] = 200;
        blocks[2] = 300;

        // First claim
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 1200, createValidatorData(claimants[0], blocks[0]));
        vm.stopPrank();
        assertApproxEqAbs(token.balanceOf(claimants[0]), 154712667492044, 1000);

        // Second claim
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 1200, createValidatorData(claimants[1], blocks[1]));
        vm.stopPrank();
        assertApproxEqAbs(token.balanceOf(claimants[1]), 309425334984088, 1000);

        // Third claim
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 1200, createValidatorData(claimants[2], blocks[2]));
        vm.stopPrank();
        assertApproxEqAbs(token.balanceOf(claimants[2]), 464138002476133, 1000);

        // Verify rewarder is drained
        assertApproxEqAbs(token.balanceOf(address(rewarder)), 0, 1000);
    }

    function testNotifyValidClaimConcurrentClaims() public {
        // Setup claimants
        address[] memory claimants = new address[](3);
        claimants[0] = address(0x111);
        claimants[1] = address(0x222);
        claimants[2] = address(0x333);

        // Each validator commits different number of blocks
        uint256[] memory blocksCommitted = new uint256[](3);
        blocksCommitted[0] = 100; // Validator 1: 100 blocks
        blocksCommitted[1] = 200; // Validator 2: 200 blocks
        blocksCommitted[2] = 300; // Validator 3: 300 blocks
        // Total = 600 blocks (equals CHECKPOINT_PERIOD)

        uint256 initialSupply = token.totalSupply();
        // Reward for committing 100 blocks in a checkpoint period for given inflation rate
        // Reward for 1st validator = totalSupply * INFLATION_RATE * (blocksCommitted / CHECKPOINT_PERIOD)
        uint256 baseReward = 154712667492044;

        // Validator 1 claims for both checkpoints
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 600, createValidatorData(claimants[0], blocksCommitted[0]));
        assertApproxEqAbs(token.balanceOf(claimants[0]), 154712667492044, 1000);

        rewarder.notifyValidClaim(createSubnet(), 1200, createValidatorData(claimants[0], blocksCommitted[0]));
        assertApproxEqAbs(token.balanceOf(claimants[0]), 154712667492044 + 154712811108101, 1000);
        vm.stopPrank();

        // Validator 2 claims for both checkpoints
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 600, createValidatorData(claimants[1], blocksCommitted[1]));
        assertApproxEqAbs(token.balanceOf(claimants[1]), 154712667492044 * 2, 1000);

        rewarder.notifyValidClaim(createSubnet(), 1200, createValidatorData(claimants[1], blocksCommitted[1]));
        assertApproxEqAbs(token.balanceOf(claimants[1]), (154712667492044 * 2) + (154712811108101 * 2), 1000);
        vm.stopPrank();

        // Validator 3 claims for both checkpoints
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 600, createValidatorData(claimants[2], blocksCommitted[2]));
        assertApproxEqAbs(token.balanceOf(claimants[2]), 154712667492044 * 3, 1000);

        rewarder.notifyValidClaim(createSubnet(), 1200, createValidatorData(claimants[2], blocksCommitted[2]));
        assertApproxEqAbs(token.balanceOf(claimants[2]), (154712667492044 * 3) + (154712811108101 * 3), 1000);
        vm.stopPrank();

        // Verify total rewards distributed
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < claimants.length; i++) {
            totalRewards += token.balanceOf(claimants[i]);
        }
        uint256 totalInflation = token.totalSupply() - initialSupply;
        assertApproxEqAbs(totalRewards, totalInflation, 1000);

        // Verify rewarder has no remaining balance
        assertApproxEqAbs(token.balanceOf(address(rewarder)), 0, 1000);
    }
}
