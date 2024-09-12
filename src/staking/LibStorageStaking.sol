// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.23;

import {ValidatorSet, Validator} from "./Subnet.sol";
import {LibSubnetActorStorage, SubnetActorStorage} from "./LibSubnetActorStorage.sol";

library LibStorageStaking {

    // =============== Getters =============

    /// @notice Getter for total storage committed by all validators in a subnet.
    /// @param validators The subnet validators set.
    function getTotalStorage(ValidatorSet storage validators) internal view returns(uint256 totalStorage) {
        totalStorage = validators.totalConfirmedStorage;
    }

    /// @notice Gets the total storage committed by the validator.
    /// @param validator The address to check for storage amount.
    function totalValidatorStorage(address validator) internal view returns (uint256) {
        SubnetActorStorage storage s = LibSubnetActorStorage.appStorage();
        return s.validatorSet.validators[validator].totalStorage;
    }

    /// @notice Checks if the validator has committed storage before.
    /// @param validator The address to check for storage status.
    /// @return A boolean indicating whether the validator has committed storage.
    function hasStorage(address validator) internal view returns (bool) {
        SubnetActorStorage storage s = LibSubnetActorStorage.appStorage();

        return s.validatorSet.validators[validator].totalStorage != 0;
    }

    /// @notice Commit the storage. 
    function commitStorage(address validator, uint256 totalStorage) internal {
        SubnetActorStorage storage s = LibSubnetActorStorage.appStorage();

        s.changeSet.commitStorageRequest(validator, totalStorage);
        s.validatorSet.recordStorageDeposit(validator, totalStorage);
        revert(validator != address(0) && totalStorage > 0,"Function not implemented yet");
    }

    /// @notice Confirm the deposit directly without going through the confirmation process
    function commitStorageWithConfirm(address validator, uint256 totalStorage) internal {
        SubnetActorStorage storage s = LibSubnetActorStorage.appStorage();

        // record deposit that updates the total commited storage
        s.validatorSet.recordStorageDeposit(validator, totalStorage);
        // confirm deposit that updates the confirmed commited storage
        s.validatorSet.confirmStorageDeposit(validator, totalStorage);

        if (!s.bootstrapped) {
            // add to initial validators avoiding duplicates if it
            // is a genesis validator.
            bool alreadyValidator;
            uint256 length = s.genesisValidators.length;
            for (uint256 i; i < length; ) {
                if (s.genesisValidators[i].addr == validator) {
                    alreadyValidator = true;
                    break;
                }
                unchecked {
                    ++i;
                }
            }
            if (!alreadyValidator) {//TODO here
                uint256 storageAmount = s.validatorSet.validators[validator].confirmedStorage;
                Validator memory val = Validator({
                    addr: validator,
                    weight: collateral,
                    metadata: s.validatorSet.validators[validator].metadata
                });
                s.genesisValidators.push(val);
            }
        }
    }

    // TODO: A Withdraw commitment function.

    /***********************************************************************
    * Internal helper functions, should not be called by external functions
    ***********************************************************************/

    /// @notice Validator increases its total storage committed by amount.
    function recordStorageDeposit(ValidatorSet storage validators, address validator, uint256 amount) internal {
        validators.validators[validator].totalStorage += amount;
    }

    function confirmStorageDeposit(ValidatorSet storage self, address validator, uint256 amount) internal {
        uint256 newCommittedStorage = self.validators[validator].confirmedStorage + amount;
        self.validators[validator].confirmedStorage = newCommittedStorage;

        self.totalConfirmedStorage += amount;

        increaseReshuffle({self: self, maybeActive: validator, newPower: newCommittedStorage});
    }
}