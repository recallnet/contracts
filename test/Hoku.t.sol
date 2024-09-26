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
}
