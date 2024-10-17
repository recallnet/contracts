// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {Hoku} from "../src/Hoku.sol";
import {Utilities} from "../src/Utilities.sol";
import {DeployScript} from "../script/Hoku.s.sol";
import {Upgrades, Options} from "@openzeppelin/foundry-upgrades/Upgrades.sol";

contract HokuTest is Test, Utilities {
    Hoku internal token;
    address internal user;
    uint256 constant mintAmount = 1000 * 10 ** 18;
    address constant tester = address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);

    // Update these constants
    string constant destinationChain = "Ethereum";
    bytes constant destinationAddress = abi.encodePacked(address(0x789));

    function setUp() public {
        DeployScript deployer = new DeployScript();
        token = deployer.run("local");

        user = address(0x123);
    }

    function testMinting() public {
        vm.prank(tester);
        token.mint(user, mintAmount);

        assertEq(token.balanceOf(user), mintAmount);
    }

    function testOnlyOwnerCanMint() public {
        // deployer mints to user
        vm.prank(tester);
        token.mint(user, mintAmount);

        assertEq(token.balanceOf(user), mintAmount);
    }

    function testImpersonatorCannotMint() public {
        vm.prank(user); // Impersonate the user
        vm.expectRevert();
        token.mint(user, mintAmount);
    }

    function testPausableTransfer() public {
        vm.prank(tester);
        token.mint(user, mintAmount);

        vm.prank(tester);
        token.pause();

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.transfer(address(0x456), 100);
    }

    function testPausableTransferFrom() public {
        vm.prank(tester);
        token.mint(user, mintAmount);

        vm.prank(user);
        token.approve(address(this), mintAmount);

        vm.prank(tester);
        token.pause();

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.transferFrom(user, address(0x456), 100);
    }

    function testPausableApprove() public {
        vm.prank(tester);
        token.pause();

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.approve(address(0x456), 100);
    }

    function testPausableBurn() public {
        vm.prank(tester);
        token.mint(user, mintAmount);

        vm.prank(tester);
        token.pause();

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.burn(100);
    }

    function testPausableBurnFrom() public {
        vm.prank(tester);
        token.mint(user, mintAmount);

        vm.prank(user);
        token.approve(address(this), mintAmount);

        vm.prank(tester);
        token.pause();

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.burnFrom(user, 100);
    }

    function testPausableMint() public {
        vm.prank(tester);
        token.pause();

        vm.prank(tester);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.mint(user, mintAmount);
    }

    function testPausableInterchainTransfer() public {
        vm.prank(tester);
        token.mint(user, mintAmount);

        vm.prank(tester);
        token.pause();

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.interchainTransfer(destinationChain, destinationAddress, 100, "");
    }

    function testPausableInterchainTransferFrom() public {
        vm.prank(tester);
        token.mint(user, mintAmount);

        vm.prank(user);
        token.approve(address(this), mintAmount);

        vm.prank(tester);
        token.pause();

        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        token.interchainTransferFrom(user, destinationChain, destinationAddress, 100, "");
    }

    function testUnpauseAllowsFunctions() public {
        vm.prank(tester);
        token.pause();

        vm.prank(tester);
        token.unpause();

        // Test that functions work after unpausing
        vm.prank(tester);
        token.mint(user, mintAmount);

        vm.prank(user);
        token.transfer(address(0x456), 100);
    }
}
