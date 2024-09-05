// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {Stake} from "../src/Stake.sol";

/// TODO update comments
contract StakeTest is Test {
    Stake private stakeContract;
    address private validator = address(0x1234);  // Example validator address
    uint256 private initialAmount = 1 ether;      // Example collateral amount
    uint256 private lockDuration = 10;            // Example lock duration

    function setUp() public {
        // Deploy the Stake contract
        stakeContract = new Stake();

        // Set the lock duration to a predefined value
        stakeContract.setLockDuration(lockDuration);
    }

    function testSetLockDuration() public {
        // Check that the lock duration is set correctly
        uint256 returnedDuration = stakeContract.getLockDuration();
        assertEq(returnedDuration, lockDuration, "Lock duration should be correctly set");
    }

    function testAddCollateralRelease() public {
        // Add a collateral release for the validator
        stakeContract.addCollateralRelease(validator, initialAmount);

        // Fast forward time to after the lock duration
        vm.roll(block.number + lockDuration + 1);

        // The validator should be able to claim the collateral
        vm.prank(validator);
        uint256 claimedAmount = stakeContract.claimCollateral();

        // Assert that the claimed amount matches the initial amount
        assertEq(claimedAmount, initialAmount, "The claimed amount should match the initially added collateral");
    }

    function testClaimBeforeLockDuration() public {
        // Add a collateral release for the validator
        stakeContract.addCollateralRelease(validator, initialAmount);

        // Attempt to claim collateral before the lock duration ends
        vm.prank(validator);
        vm.expectRevert();  // Expect the transaction to revert because it's too early to claim
        stakeContract.claimCollateral();
    }

    function testClaimAfterLockDuration() public {
        // Add a collateral release for the validator
        stakeContract.addCollateralRelease(validator, initialAmount);

        // Fast forward time to after the lock duration
        vm.roll(block.number + lockDuration + 1);

        // Claim the collateral
        vm.prank(validator);
        uint256 claimedAmount = stakeContract.claimCollateral();

        // Assert that the claimed amount matches the initially added collateral
        assertEq(claimedAmount, initialAmount, "The claimed amount should match the initially added collateral");
    }
}