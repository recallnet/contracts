// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "ipc-contracts/lib/LibStaking.sol";

/// TODO general contract documentation
contract Stake {
    using LibStakingReleaseQueue for StakingReleaseQueue;

    StakingReleaseQueue private stakingReleaseQueue;

    // Set the lock duration (in blocks)
    function setLockDuration(uint256 lockDuration) external {
        stakingReleaseQueue.setLockDuration(lockDuration);
    }

    // Add new collateral release
    function addCollateralRelease(address validator, uint256 amount) external {
        stakingReleaseQueue.addNewRelease(validator, amount);
    }

    // Validator claims the released collateral
    function claimCollateral() external returns (uint256) {
        return stakingReleaseQueue.claim(msg.sender);
    }

    // Get the lock duration for collateral release
    function getLockDuration() external view returns (uint256) {
        return stakingReleaseQueue.lockingDuration;
    }

    // Additional functions to extend functionality can go here
}