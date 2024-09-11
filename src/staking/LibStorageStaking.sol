// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.23;

import {ValidatorSet, Validator} from "./Subnet.sol";
import {LibSubnetActorStorage, SubnetActorStorage} from "./LibSubnetActorStorage.sol";

library LibStorageStaking {

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

       /* s.changeSet.depositRequest(validator, totalStorage);
        s.validatorSet.recordDeposit(validator, totalStorage);*/
    }

    // TODO: A Withdraw commitment function.
}