// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.23;

import {LibStaking, LibStakingReleaseQueue} from "ipc-contracts/lib/LibStaking.sol";  // Adjust the path according to your folder structure
import {ValidatorSet, StakingReleaseQueue} from "ipc-contracts/structs/Subnet.sol";
import {LibSubnetActorStorage, SubnetActorStorage} from "ipc-contracts/lib/LibSubnetActorStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Open to suggestions on the name TODO
contract Stake {
    using LibStaking for ValidatorSet;
    using LibStakingReleaseQueue for StakingReleaseQueue;

    IERC20 public stakingToken;  // ERC20 token used for staking
    SubnetActorStorage private storageInstance;

    // Constructor to initialize the token and storage
    constructor(IERC20 _stakingToken) {
        stakingToken = _stakingToken;
        storageInstance = LibSubnetActorStorage.appStorage();
    }

    // Allow a validator to deposit collateral in ERC20
    function deposit(address validator, uint256 amount) external {
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // Call library function to record the deposit
        storageInstance.validatorSet.depositWithConfirm(validator, amount);
    }

    // Allow a validator to withdraw collateral (releases locked tokens)
    function withdraw(address validator, uint256 amount) external {
        // Call library function to record the withdrawal
        storageInstance.validatorSet.withdrawWithConfirm(validator, amount);
    }

    // Set the lock duration for collateral release
    function setLockDuration(uint256 lockDuration) external {
        storageInstance.releaseQueue.setLockDuration(lockDuration);
    }

    // Claim released collateral in ERC20
    function claimCollateral() external {
        uint256 amountToClaim = storageInstance.releaseQueue.claim(msg.sender);

        // Transfer the released tokens to the validator
        require(stakingToken.transfer(msg.sender, amountToClaim), "Token transfer failed");
    }

    // Get the power (voting power) of a validator
    function getValidatorPower(address validator) external view returns (uint256) {
        return storageInstance.validatorSet.getPower(validator);
    }

    // Check if a validator is active
    function isActiveValidator(address validator) external view returns (bool) {
        return storageInstance.validatorSet.isActiveValidator(validator);
    }

    // Check the total active validators
    function getTotalActiveValidators() external view returns (uint16) {
        return storageInstance.validatorSet.totalActiveValidators();
    }

    // Get the total confirmed collateral of all validators
    function getTotalConfirmedCollateral() external view returns (uint256) {
        return storageInstance.validatorSet.getTotalConfirmedCollateral();
    }
}