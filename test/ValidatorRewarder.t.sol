// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {DeployScript as RecallDeployScript} from "../script/Recall.s.sol";
import {DeployScript as ValidatorRewarderDeployScript} from "../script/ValidatorRewarder.s.sol";
import {Recall} from "../src/token/Recall.sol";
import {ValidatorRewarder} from "../src/token/ValidatorRewarder.sol";

import {Consensus, SubnetID} from "../src/types/CommonTypes.sol";
import {SubnetIDHelper} from "../src/util/SubnetIDHelper.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

// Base contract with common setup and helper functions
abstract contract ValidatorRewarderTestBase is Test {
    using SubnetIDHelper for SubnetID;

    ValidatorRewarder internal rewarder;
    address internal rewarderOwner;
    Recall internal token;
    address internal subnetActor;

    // Constants
    uint64 internal constant ROOTNET_CHAINID = 123;
    address internal constant SUBNET_ROUTE = address(101);
    uint256 internal constant CHECKPOINT_PERIOD = 600;
    uint256 internal constant INFLATION_RATE = 928_276_004_952;

    function setUp() public virtual {
        subnetActor = address(0x456);

        // Deploy Recall token
        RecallDeployScript recallDeployer = new RecallDeployScript();
        token = recallDeployer.run("local");

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
        rewarder.setSubnet(subnet, 600);
        vm.stopPrank();

        // Mint initial supply of Recall tokens to a random address
        vm.startPrank(rewarderOwner);
        token.mint(address(0x888), 1000e18);
        // Set subnet
        rewarder.setSubnet(subnet, 600);
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
        assertEq(rewarder.INFLATION_RATE(), 928_276_004_952);
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
        assertEq(rewarder.checkpointPeriod(), CHECKPOINT_PERIOD);
    }

    function testInitializeWithInvalidPeriod() public {
        // Deploy a new instance without initialization
        ValidatorRewarder newRewarder = new ValidatorRewarder();
        SubnetID memory subnet = createSubnet();

        // Initialize with token
        newRewarder.initialize(address(token));

        // Try to set subnet with invalid period
        vm.expectRevert(abi.encodeWithSelector(ValidatorRewarder.InvalidCheckpointPeriod.selector, 0));
        newRewarder.setSubnet(subnet, 0);
    }

    function testSetSubnetNotOwner() public {
        SubnetID memory subnet = createSubnet();
        vm.startPrank(address(0x789));
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", address(0x789)));
        rewarder.setSubnet(subnet, CHECKPOINT_PERIOD);
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
        uint256 initialRewarderBalance = token.balanceOf(address(rewarder));
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

        // Verify no tokens were minted or transferred
        assertEq(token.totalSupply(), initialSupply, "Total supply should not change");
        assertEq(token.balanceOf(address(rewarder)), initialRewarderBalance, "Rewarder balance should not change");
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
        uint256 rewarderBalanceBeforePause = token.balanceOf(address(rewarder));
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
        assertEq(token.balanceOf(address(rewarder)), rewarderBalanceBeforePause, "Rewarder balance should not change");
        assertEq(token.balanceOf(claimant), claimantBalanceBeforePause, "Claimant balance should not change");
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
        assertEq(rewarder.latestClaimedCheckpoint(), 0);
        assertEq(token.balanceOf(address(rewarder)), 0);
        assertEq(token.totalSupply(), initialSupply);

        // First claim: should be at checkpoint 600 (checkpoint period)
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 600, validatorData);
        vm.stopPrank();

        // Verify rewards
        assertApproxEqAbs(token.balanceOf(claimant), 77356333746022, 1000);
        assertApproxEqAbs(token.balanceOf(address(rewarder)), 850919671206244, 1000);

        // Verify total inflation
        uint256 totalInflation = token.totalSupply() - initialSupply;
        assertApproxEqAbs(totalInflation, 850919671206244 + 77356333746022, 1000);

        // Verify checkpoint
        assertEq(rewarder.latestClaimedCheckpoint(), 600);

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

        // First claim: should be at checkpoint 600 (checkpoint period)
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 600, createValidatorData(claimants[0], blocks[0]));
        vm.stopPrank();
        assertApproxEqAbs(token.balanceOf(claimants[0]), 154712667492044, 1000);

        // Second claim
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 600, createValidatorData(claimants[1], blocks[1]));
        vm.stopPrank();
        assertApproxEqAbs(token.balanceOf(claimants[1]), 309425334984088, 1000);

        // Third claim
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 600, createValidatorData(claimants[2], blocks[2]));
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

    function testNotifyValidClaimMustBeSequential() public {
        address claimant = address(0x999);
        Consensus.ValidatorData memory validatorData = createValidatorData(claimant, 50);

        // Try to claim for checkpoint 1200 before 600
        vm.startPrank(SUBNET_ROUTE);
        vm.expectRevert(abi.encodeWithSelector(ValidatorRewarder.InvalidCheckpointHeight.selector, 1200));
        rewarder.notifyValidClaim(createSubnet(), 1200, validatorData);
        vm.stopPrank();

        // First claim must be at checkpoint 600
        vm.startPrank(SUBNET_ROUTE);
        vm.expectRevert(abi.encodeWithSelector(ValidatorRewarder.InvalidCheckpointHeight.selector, 300));
        rewarder.notifyValidClaim(createSubnet(), 300, validatorData);
        vm.stopPrank();

        // Correct sequence: first claim at 600
        vm.startPrank(SUBNET_ROUTE);
        rewarder.notifyValidClaim(createSubnet(), 600, validatorData);
        assertEq(rewarder.latestClaimedCheckpoint(), 600);

        // Then claim at 1200
        rewarder.notifyValidClaim(createSubnet(), 1200, validatorData);
        assertEq(rewarder.latestClaimedCheckpoint(), 1200);
        vm.stopPrank();
    }
}
