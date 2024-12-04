// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Options, Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript} from "../script/Hoku.s.sol";
import {Hoku} from "../src/Hoku.sol";

contract HokuTest is Test {
    Hoku internal token;
    address internal user;
    uint256 internal constant MINT_AMOUNT = 1000 * 10 ** 18;
    address internal constant TESTER = address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);

    // Update these constants
    string internal constant DESTINATION_CHAIN = "Ethereum";
    bytes internal constant DESTINATION_ADDRESS = abi.encodePacked(address(0x789));

    function setUp() public {
        DeployScript deployer = new DeployScript();
        token = deployer.run("local");

        user = address(0x123);
    }

    function testMinting() public {
        vm.prank(TESTER);
        token.mint(user, MINT_AMOUNT);

        assertEq(token.balanceOf(user), MINT_AMOUNT);
    }

    function testOnlyOwnerCanMint() public {
        // deployer mints to user
        vm.prank(TESTER);
        token.mint(user, MINT_AMOUNT);

        assertEq(token.balanceOf(user), MINT_AMOUNT);
    }

    function testImpersonatorCannotMint() public {
        vm.prank(user); // Impersonate the user
        vm.expectRevert();
        token.mint(user, MINT_AMOUNT);
    }

    function testPausableTransfer() public {
        vm.prank(TESTER);
        token.mint(user, MINT_AMOUNT);

        vm.prank(TESTER);
        token.pause();

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.transfer(address(0x456), 100);
    }

    function testPausableTransferFrom() public {
        vm.prank(TESTER);
        token.mint(user, MINT_AMOUNT);

        vm.prank(user);
        token.approve(address(this), MINT_AMOUNT);

        vm.prank(TESTER);
        token.pause();

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.transferFrom(user, address(0x456), 100);
    }

    function testPausableApprove() public {
        vm.prank(TESTER);
        token.pause();

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.approve(address(0x456), 100);
    }

    function testPausableBurn() public {
        vm.prank(TESTER);
        token.mint(user, MINT_AMOUNT);

        vm.prank(TESTER);
        token.pause();

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.burn(100);
    }

    function testPausableBurnFrom() public {
        vm.prank(TESTER);
        token.mint(user, MINT_AMOUNT);

        vm.prank(user);
        token.approve(address(this), MINT_AMOUNT);

        vm.prank(TESTER);
        token.pause();

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.burnFrom(user, 100);
    }

    function testPausableMint() public {
        vm.prank(TESTER);
        token.pause();

        vm.prank(TESTER);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.mint(user, MINT_AMOUNT);
    }

    function testPausableInterchainTransfer() public {
        vm.prank(TESTER);
        token.mint(user, MINT_AMOUNT);

        vm.prank(TESTER);
        token.pause();

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.interchainTransfer(DESTINATION_CHAIN, DESTINATION_ADDRESS, 100, "");
    }

    function testPausableInterchainTransferFrom() public {
        vm.prank(TESTER);
        token.mint(user, MINT_AMOUNT);

        vm.prank(user);
        token.approve(address(this), MINT_AMOUNT);

        vm.prank(TESTER);
        token.pause();

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.interchainTransferFrom(user, DESTINATION_CHAIN, DESTINATION_ADDRESS, 100, "");
    }

    function testUnpauseAllowsFunctions() public {
        vm.prank(TESTER);
        token.pause();

        vm.prank(TESTER);
        token.unpause();

        // Test that functions work after unpausing
        vm.prank(TESTER);
        token.mint(user, MINT_AMOUNT);

        vm.prank(user);
        token.transfer(address(0x456), 100);
    }
}
