// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript} from "../script/Recall.s.sol";
import {Recall} from "../src/token/Recall.sol";

contract RecallTest is Test {
    Recall internal token;
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

    function testPauserRolePermissions() public {
        address pauser = address(0x789);
        bytes32 pauserRole = token.PAUSER_ROLE();
        bytes32 adminRole = token.ADMIN_ROLE();

        // Grant PAUSER_ROLE to new address
        vm.prank(TESTER);
        token.grantRole(pauserRole, pauser);

        // Pauser can pause
        vm.prank(pauser);
        token.pause();
        assertTrue(token.paused());

        // Pauser cannot unpause (only ADMIN can)
        vm.prank(pauser);
        vm.expectRevert(abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", pauser, adminRole));
        token.unpause();

        // Random address cannot pause
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", user, pauserRole));
        token.pause();

        // Admin can unpause
        vm.prank(TESTER);
        token.unpause();
        assertFalse(token.paused());
    }

    function testRemoveAdminPauserRole() public {
        bytes32 pauserRole = token.PAUSER_ROLE();

        // Initially admin can pause
        vm.prank(TESTER);
        token.pause();
        assertTrue(token.paused());

        // Remove PAUSER_ROLE from admin
        vm.prank(TESTER);
        token.revokeRole(pauserRole, TESTER);

        // Admin can no longer pause after role removal
        vm.prank(TESTER);
        vm.expectRevert(
            abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", TESTER, pauserRole)
        );
        token.pause();
    }
}
