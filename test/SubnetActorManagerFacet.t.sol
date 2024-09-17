// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/staking/LibStaking.sol";
import {Utilities} from "../src/Utilities.sol";
import {StakingDeployScript} from "../script/SubnetActorManagerFacet.s.sol";
import {SubnetActorManagerFacetMock} from "../src/staking/SubnetActorManagerFacetMock.sol";

contract SubnetActorManagerFacetTest is Test, Utilities {

    SubnetActorManagerFacetMock internal subnetActorManagerFacet;
    uint256 constant storageCommintment = 100;
    address walletAddr = vm.createWallet(uint256(keccak256(bytes("1")))).addr;
    uint256 publicKeyX = vm.createWallet(uint256(keccak256(bytes("1")))).publicKeyX;
    uint256 publicKeyY = vm.createWallet(uint256(keccak256(bytes("1")))).publicKeyY;

    bytes uncompressedKey = abi.encodePacked(
            bytes1(0x04),                
            publicKeyX,                 
            publicKeyY                  
        );

    function setUp() public {
        StakingDeployScript deployer = new StakingDeployScript();
        subnetActorManagerFacet = deployer.run(Environment.Local);

        vm.deal(walletAddr, 10 ether);
    }

    function testSetStorageOnJoin() public {
        bytes memory metadata = abi.encodePacked(uncompressedKey, storageCommintment);
        subnetActorManagerFacet.setActiveLimit(10);
        
        vm.prank(walletAddr);
        // Expect no revert on this call
        subnetActorManagerFacet.join{value: 1}(metadata); // Call join function with valid collateral and metadata

        // Check that the validator has joined (you can do this via getters)
        assertTrue(LibStaking.isValidator(walletAddr), "Validator did not join successfully");
    }
/*
    function testSetStorageOnStake() public {
        // Example test logic
        assertEq(validatorsAddresses.length, 3);
    }

    function testSetStorageOnLeave() public {
        // Example test logic
        assertEq(validatorsAddresses.length, 3);
    }

    function testSetStorageOnUnstake() public {
        // Example test logic
        assertEq(validatorsAddresses.length, 3);
    }*/

}