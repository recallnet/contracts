// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {DeployScript as RecallDeployScript} from "../script/Recall.s.sol";
import {DeployScript as ValidatorRewarderDeployScript} from "../script/ValidatorRewarder.s.sol";
import {Recall} from "../src/token/Recall.sol";
import {BottomUpCheckpoint, ISubnetActorGetter, ValidatorRewarder} from "../src/token/ValidatorRewarder.sol";

import {Consensus, SubnetID} from "../src/types/CommonTypes.sol";
import {SubnetIDHelper} from "../src/util/SubnetIDHelper.sol";
import {Test} from "forge-std/Test.sol";

// Mock implementation of the ISubnetActorGetter interface for testing
contract MockSubnetActor is ISubnetActorGetter {
    mapping(uint256 => BottomUpCheckpoint) internal checkpoints;

    function setCheckpoint(uint256 epoch, uint64 blocksCommitted) external {
        checkpoints[epoch].activity.consensus.stats.totalNumBlocksCommitted = blocksCommitted;
    }

    function bottomUpCheckpointAtEpoch(uint256 epoch)
        external
        view
        override
        returns (bool exists, BottomUpCheckpoint memory checkpoint)
    {
        if (checkpoints[epoch].activity.consensus.stats.totalNumBlocksCommitted > 0) {
            return (true, checkpoints[epoch]);
        }

        // Default to returning checkpoint data with the epoch as the number of blocks
        BottomUpCheckpoint memory defaultCheckpoint;
        defaultCheckpoint.activity.consensus.stats.totalNumBlocksCommitted = 600; // Default to CHECKPOINT_PERIOD
        return (true, defaultCheckpoint);
    }
}

// Base contract with common setup and helper functions
abstract contract ValidatorRewarderTestBase is Test {
    using SubnetIDHelper for SubnetID;

    ValidatorRewarder internal rewarder;
    address internal rewarderOwner;
    Recall internal token;
    address internal subnetActor;
    MockSubnetActor internal mockSubnetActor;

    // Constants
    uint64 internal constant ROOTNET_CHAINID = 123;
    address internal constant SUBNET_ROUTE = address(101);
    uint256 internal constant INFLATION_RATE = 928_276_004_952;

    function setUp() public virtual {
        // Deploy mock subnet actor
        mockSubnetActor = new MockSubnetActor();
        subnetActor = address(mockSubnetActor);

        // Override the SUBNET_ROUTE for tests
        vm.etch(SUBNET_ROUTE, address(mockSubnetActor).code);

        // Deploy Recall token
        RecallDeployScript recallDeployer = new RecallDeployScript();
        token = recallDeployer.run();

        // Create subnet for initialization
        SubnetID memory subnet = createSubnet();

        // Deploy ValidatorRewarder with initialization params
        ValidatorRewarderDeployScript rewarderDeployer = new ValidatorRewarderDeployScript();
        rewarder = rewarderDeployer.run(address(token));
        rewarderOwner = rewarder.owner();

        // Grant MINTER_ROLE to Rewarder for Recall tokens
        vm.startPrank(token.deployer());
        token.grantRole(token.MINTER_ROLE(), address(rewarder));
        vm.stopPrank();

        // Set up rewarder configuration
        vm.startPrank(rewarderOwner);
        rewarder.setSubnet(subnet);
        vm.stopPrank();

        // Set up checkpoint data for tests
        MockSubnetActor(SUBNET_ROUTE).setCheckpoint(600, 600);
        MockSubnetActor(SUBNET_ROUTE).setCheckpoint(1200, 600);
        MockSubnetActor(SUBNET_ROUTE).setCheckpoint(1800, 600);

        // Mint initial supply of Recall tokens to a random address
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
    function testInitialState() public view {
        assertTrue(rewarder.isActive());
        assertEq(rewarder.subnet(), createSubnet().root);
        assertEq(address(rewarder.token()), address(token));
        assertEq(rewarder.BLOCKS_PER_TOKEN(), 3);
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

    function testInitialSubnetSetup() public view {
        SubnetID memory expectedSubnet = createSubnet();
        assertEq(rewarder.subnet(), expectedSubnet.root);
    }

    function testSetSubnetNotOwner() public {
        SubnetID memory subnet = createSubnet();
        vm.startPrank(address(0x789));
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", address(0x789)));
        rewarder.setSubnet(subnet);
        vm.stopPrank();
    }

    function testCannotInitializeTwice() public {
        // The error is now "InvalidInitialization()" in newer OZ versions
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        rewarder.initialize(address(token));
    }
}

// Token management tests
contract ValidatorRewarderTokenTest is ValidatorRewarderTestBase {
    function testInitialTokenSetup() public view {
        assertEq(address(rewarder.token()), address(token));
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

        vm.expectRevert(ValidatorRewarder.ContractNotActive.selector);
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

    function testNotifyValidClaimWhenTokenPaused() public {
        // Setup test data
        address claimant = address(0x999);
        Consensus.ValidatorData memory validatorData = createValidatorData(claimant, 100);
        uint256 initialSupply = token.totalSupply();
        uint256 initialClaimantBalance = token.balanceOf(claimant);

        // Pause the token
        vm.startPrank(token.deployer());
        token.pause();
        vm.stopPrank();

        // Try to claim rewards
        vm.startPrank(SUBNET_ROUTE);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        rewarder.notifyValidClaim(createSubnet(), 600, validatorData);
        vm.stopPrank();

        // Verify no tokens were minted
        assertEq(token.totalSupply(), initialSupply, "Total supply should not change");
        assertEq(token.balanceOf(claimant), initialClaimantBalance, "Claimant balance should not change");
    }

    function testNotifyValidClaimWhenTokenPausedSubsequentClaim() public {
        // First make a successful claim while token is not paused
        address claimant = address(0x999);
        Consensus.ValidatorData memory validatorData = createValidatorData(claimant, 100);

        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 600, validatorData);
        vm.stopPrank();

        // Record balances before pausing
        uint256 supplyBeforePause = token.totalSupply();
        uint256 claimantBalanceBeforePause = token.balanceOf(claimant);

        // Pause the token
        vm.startPrank(token.deployer());
        token.pause();
        vm.stopPrank();

        // Try to make another claim
        vm.startPrank(SUBNET_ROUTE);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        rewarder.notifyValidClaim(createSubnet(), 1200, validatorData);
        vm.stopPrank();

        // Verify no tokens were transferred
        assertEq(token.totalSupply(), supplyBeforePause, "Total supply should not change");
        assertEq(token.balanceOf(claimant), claimantBalanceBeforePause, "Claimant balance should not change");
    }
}

// Complex claim notification tests
contract ValidatorRewarderComplexClaimTest is ValidatorRewarderTestBase {
    function testNotifyValidClaimSingleValidator() public {
        address claimant = address(0x999);
        Consensus.ValidatorData memory validatorData = createValidatorData(claimant, 300);

        uint256 initialSupply = token.totalSupply();

        // Claim at checkpoint 600
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 600, validatorData);
        vm.stopPrank();

        // For 600 blocks checkpoint period:
        // Total new tokens = 600/3 = 200
        // Validator committed 300/600 blocks = 50% of blocks
        // Expected reward = 200 * 0.5 = 100
        uint256 expectedReward = 100 ether;
        assertApproxEqAbs(token.balanceOf(claimant), expectedReward, 1000);
        assertEq(token.totalSupply() - initialSupply, expectedReward);
    }

    function testNotifyValidClaimMultipleValidators() public {
        address[] memory claimants = new address[](3);
        claimants[0] = address(0x111);
        claimants[1] = address(0x222);
        claimants[2] = address(0x333);

        uint256[] memory blocks = new uint256[](3);
        blocks[0] = 100; // 1/6 of blocks
        blocks[1] = 200; // 1/3 of blocks
        blocks[2] = 300; // 1/2 of blocks

        uint256 initialSupply = token.totalSupply();

        // All validators claim for the same checkpoint
        vm.startPrank(SUBNET_ROUTE);
        for (uint256 i = 0; i < claimants.length; i++) {
            rewarder.notifyValidClaim(createSubnet(), 600, createValidatorData(claimants[i], blocks[i]));
        }
        vm.stopPrank();

        // Total new tokens = 600/3 = 200
        // Validator 1 should get: 200 * (100/600) ≈ 33.33
        // Validator 2 should get: 200 * (200/600) ≈ 66.67
        // Validator 3 should get: 200 * (300/600) = 100
        assertApproxEqAbs(token.balanceOf(claimants[0]), 33333333333333333333, 1000);
        assertApproxEqAbs(token.balanceOf(claimants[1]), 66666666666666666666, 1000);
        assertApproxEqAbs(token.balanceOf(claimants[2]), 100000000000000000000, 1000);

        // Total minted should be 200
        assertApproxEqAbs(token.totalSupply() - initialSupply, 200 ether, 1000);
    }

    function testNotifyValidClaimMultipleCheckpoints() public {
        address claimant = address(0x999);
        Consensus.ValidatorData memory validatorData = createValidatorData(claimant, 300);

        uint256 initialSupply = token.totalSupply();

        // Claim for three consecutive checkpoints
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 600, validatorData);
        rewarder.notifyValidClaim(createSubnet(), 1200, validatorData);
        rewarder.notifyValidClaim(createSubnet(), 1800, validatorData);
        vm.stopPrank();

        // For each checkpoint:
        // Total new tokens = 600/3 = 200
        // Validator committed 300/600 blocks = 50% of blocks
        // Expected reward per checkpoint = 200 * 0.5 = 100
        // Total expected for 3 checkpoints = 300
        uint256 expectedTotalReward = 300 ether;
        assertApproxEqAbs(token.balanceOf(claimant), expectedTotalReward, 1000);
        assertEq(token.totalSupply() - initialSupply, expectedTotalReward);
    }

    // Test for checkpoint periods smaller than 600 blocks
    function testSmallerCheckpointPeriods() public {
        address claimant1 = address(0x999);
        address claimant2 = address(0x998);

        // Define checkpoint sizes to test
        uint64 checkpointSize = 300;

        // Validator commits all blocks
        uint256 initialSupply = token.totalSupply();

        // Setup test environment
        uint64 checkpointHeight = 1000; // Unique checkpoint heights

        // Set mock to return the correct blocks for this checkpoint
        MockSubnetActor(SUBNET_ROUTE).setCheckpoint(checkpointHeight, checkpointSize);

        // Create validator that committed 100% of blocks
        Consensus.ValidatorData memory validatorData1 = createValidatorData(claimant1, checkpointSize / 2);
        Consensus.ValidatorData memory validatorData2 = createValidatorData(claimant2, checkpointSize / 2);

        // Capture balance before claim
        uint256 balanceBefore1 = token.balanceOf(claimant1);
        uint256 balanceBefore2 = token.balanceOf(claimant2);

        // Claim rewards
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), checkpointHeight, validatorData1);
        rewarder.notifyValidClaim(createSubnet(), checkpointHeight, validatorData2);
        vm.stopPrank();

        // Expected tokens for full participation
        // Tokens = blocks / BLOCKS_PER_TOKEN
        // uint256 expectedReward = ;
        uint256 actualReward1 = token.balanceOf(claimant1) - balanceBefore1;
        uint256 actualReward2 = token.balanceOf(claimant2) - balanceBefore2;

        // Verify rewards
        assertEq(actualReward1, actualReward2);
        assertEq(actualReward1, 50 ether);
        assertEq(actualReward2, 50 ether);
        assertEq(token.totalSupply() - initialSupply, 100 ether);
    }

    // Test for checkpoint periods with partial validator participation
    function testSmallerCheckpointPeriodsWithPartialParticipation() public {
        address claimant = address(0x999);

        // Define checkpoint sizes to test
        uint64 checkpointSize = 300;
        uint256 initialSupply = token.totalSupply();

        // Setup test environment
        uint64 checkpointHeight = 2000;
        uint64 blocksInCheckpoint = checkpointSize;
        uint64 blocksCommitted = blocksInCheckpoint / 2; // 50% participation

        // Set mock to return the correct blocks for this checkpoint
        MockSubnetActor(SUBNET_ROUTE).setCheckpoint(checkpointHeight, blocksInCheckpoint);

        // Create validator that committed 50% of blocks
        Consensus.ValidatorData memory validatorData = createValidatorData(claimant, blocksCommitted);
        uint256 balanceBefore = token.balanceOf(claimant);

        // Claim rewards
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), checkpointHeight, validatorData);
        vm.stopPrank();

        // Expected tokens for 50% participation
        // Total tokens = blocksInCheckpoint / BLOCKS_PER_TOKEN
        // Validator share = Total tokens * (blocksCommitted / blocksInCheckpoint)
        uint256 expectedReward = 50 ether;
        uint256 actualReward = token.balanceOf(claimant) - balanceBefore;
        assertEq(actualReward, expectedReward);
        assertEq(token.totalSupply() - initialSupply, 50 ether);
    }
}
