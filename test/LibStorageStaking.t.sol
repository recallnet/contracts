// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/staking/LibStorageStaking.sol";
import "../src/staking/LibSubnetActorStorage.sol";
import "../src/staking/LibStaking.sol";
import "../src/staking/LibStakingChangeLog.sol";
import "../src/staking/Subnet.sol"; // Import required structs like ValidatorSet, Validator, etc.

contract LibStorageStakingTest is Test {
    using LibStorageStaking for ValidatorSet;
    using LibStorageStaking for SubnetActorStorage;
    
    ValidatorInfo validator1;
    ValidatorInfo validator2;
    Validator [2]validators;

    address constant validatorAddress1 = address(0x1);
    address constant validatorAddress2 = address(0x2);
    uint256 validator1Storage = 100;
    uint256 validator2Storage = 200;
    uint256 totalValidatorsStorage = validator1Storage + validator1Storage;
    //TODO make this set up match others in project
    function setUp() public {
        // Initialize Validator structs and ValidatorSet.
        initializeValidatorsInfo(validatorAddress1, validatorAddress2);
        SubnetActorStorage storage s =  LibSubnetActorStorage.appStorage();
        //Setting manually
        s.genesisValidators.push(validators[0]);
        s.genesisValidators.push(validators[1]);
        // Set individual validator entries in the mapping
        s.validatorSet.validators[validatorAddress1] = validator1;
        s.validatorSet.validators[validatorAddress2] = validator2;
        
        // Set the totalConfirmedStorage field
        s.validatorSet.totalConfirmedStorage = totalValidatorsStorage;
    }


    function initializeValidatorsInfo(address v1, address v2) public {
        uint256 weight = 700;
        // Initialize ValidatorInfo objects with empty metadata...for now
        validator1 = ValidatorInfo({
            federatedPower: 1000,
            confirmedCollateral: weight,
            totalCollateral: 800,
            metadata: "",  // TODO
            totalStorage: validator1Storage,
            confirmedStorage: validator1Storage
        });

        validators[0] = Validator(weight,v1,"",validator1Storage);

        validator2 = ValidatorInfo({
            federatedPower: 1500,
            confirmedCollateral: weight,
            totalCollateral: 1200,
            metadata: "",  // TODO
            totalStorage: validator2Storage,
            confirmedStorage: validator2Storage
        });
        validators[1] = Validator(weight,v2,"",validator2Storage);
    }

    function testGetTotalConfirmedStorage() public view {
        SubnetActorStorage storage s = LibSubnetActorStorage.appStorage();
        uint256 totalStorage = LibStorageStaking.getTotalConfirmedStorage(s.validatorSet);
        assertEq(totalStorage, totalValidatorsStorage);
    }

    function testTotalValidatorStorage() public view {
        uint256 storage1 = LibStorageStaking.totalValidatorStorage(validatorAddress1);
        assertEq(storage1, validator1Storage);// set appStorage first

        uint256 storage2 = LibStorageStaking.totalValidatorStorage(validatorAddress2);
        assertEq(storage2, validator2Storage);
    }

    function testHasStorage() public view {
        bool hasStorage1 = LibStorageStaking.hasStorage(validatorAddress1);
        assertTrue(hasStorage1);

        bool hasStorage2 = LibStorageStaking.hasStorage(validatorAddress2);
        assertTrue(hasStorage2);

        bool hasStorage3 = LibStorageStaking.hasStorage(address(0x3)); // Non-existent validator
        assertFalse(hasStorage3);
    }

    function testCommitStorage() public {
        SubnetActorStorage storage s = LibSubnetActorStorage.appStorage();
        uint256 newStorage = 500;
        // Before storage commit
        uint256 initialStorage = s.validatorSet.validators[validatorAddress1].totalStorage;
        assertEq(initialStorage, validator1Storage);

        // Commit storage
        LibStorageStaking.commitStorage(validatorAddress1, newStorage);

        // After storage commit
        uint256 committedStorage = s.validatorSet.validators[validatorAddress1].totalStorage;
        assertEq(committedStorage, validator1Storage + newStorage);
    }

    function testCommitStorageWithConfirm() public {
        SubnetActorStorage storage s = LibSubnetActorStorage.appStorage();
        uint256 newStorage = 1000;
        uint256 total = validator1Storage + newStorage;
        // Commit and confirm storage for validatorAddress1
        LibStorageStaking.commitStorageWithConfirm(validatorAddress1, newStorage);

        // Check total and confirmed storage
        uint256 totalStorage = s.validatorSet.validators[validatorAddress1].totalStorage;
        uint256 confirmedStorage = s.validatorSet.validators[validatorAddress1].confirmedStorage;
        assertEq(totalStorage, total);
        assertEq(confirmedStorage, total);
    }
}
