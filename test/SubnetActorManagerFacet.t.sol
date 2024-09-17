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
    bytes metadata = abi.encodePacked(uncompressedKey, storageCommintment);

    function setUp() public {
        StakingDeployScript deployer = new StakingDeployScript();
        subnetActorManagerFacet = deployer.run(Environment.Local);
        subnetActorManagerFacet.setActiveLimit(10);
        subnetActorManagerFacet.setMinCollateral(100);
        vm.deal(walletAddr, 10 ether);
    }

    function testSetStorageOnJoin() public {
        vm.prank(walletAddr);
        // Expect no revert on this call
        subnetActorManagerFacet.join{value: 1}(metadata); // Call join function with valid collateral and metadata
        
        // Check that the validator has joined
        assertTrue(subnetActorManagerFacet.isValidator(walletAddr), "Validator did not join successfully");
        assertTrue(subnetActorManagerFacet.hasStorage(walletAddr));
        
        assertEq(subnetActorManagerFacet.getTotalStorage(walletAddr), storageCommintment);
        assertEq(subnetActorManagerFacet.getTotalConfirmedStorage(walletAddr), storageCommintment);
    }

    function testSetStorageOnStake() public {
        (uint256 validatorTotalStorage, uint256 validatorConfirmedStorage,uint256 totalConfirmedStorage ) = getStorageValues();

        // Must revert if validator have not joined the subnet
        vm.expectRevert();
        subnetActorManagerFacet.stakeStorage(storageCommintment);


        vm.startPrank(walletAddr);
        subnetActorManagerFacet.join{value: 1}(metadata); // Call join before staking
        subnetActorManagerFacet.stakeStorage{value: 1}(storageCommintment);
        vm.stopPrank();

        assertGt(subnetActorManagerFacet.getTotalStorage(walletAddr),validatorTotalStorage);
        assertGt(subnetActorManagerFacet.getTotalConfirmedStorage(walletAddr),validatorConfirmedStorage);
        assertGt(subnetActorManagerFacet.getSubnetTotalConfirmedStorage(),totalConfirmedStorage);
    }

    function testSetStorageOnLeave() public {
        // Save current storage state
        (uint256 validatorTotalStorage, , uint256 totalConfirmedStorage ) = getStorageValues();

        // Should not allow to leave if address never joined
        vm.expectRevert();
        subnetActorManagerFacet.leave();

        vm.startPrank(walletAddr);
        subnetActorManagerFacet.join{value: 1}(metadata); // Call join before leaving
        subnetActorManagerFacet.leave();
        vm.stopPrank();

        (uint256 newValidatorTotalStorage, uint256 newValidatorConfirmedStorage, uint256 newTotalConfirmedStorage ) = getStorageValues();
        assertEq(newValidatorTotalStorage, 0);
        assertEq(newValidatorConfirmedStorage, 0);
        assertEq(newTotalConfirmedStorage, totalConfirmedStorage - validatorTotalStorage);
    }

    function testSetStorageOnUnstake() public {
        // Example test logic
       // assertEq(validatorsAddresses.length, 3);
    }

    function getStorageValues() internal view returns(uint256, uint256, uint256) {
        uint256 validatorTotalStorage = subnetActorManagerFacet.getTotalStorage(walletAddr);
        uint256 validatorConfirmedStorage = subnetActorManagerFacet.getTotalConfirmedStorage(walletAddr);
        uint256 totalConfirmedStorage = subnetActorManagerFacet.getSubnetTotalConfirmedStorage();

        return (validatorTotalStorage, validatorConfirmedStorage, totalConfirmedStorage);
    }

}