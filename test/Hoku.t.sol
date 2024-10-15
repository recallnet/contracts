// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Options, Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript} from "../script/Hoku.s.sol";
import {Hoku} from "../src/Hoku.sol";
import {Environment} from "../src/types/CommonTypes.sol";

contract HokuTest is Test {
    Hoku internal token;
    address internal user;
    uint256 constant mintAmount = 1000 * 10 ** 18;
    address constant tester = address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);

    function setUp() public {
        DeployScript deployer = new DeployScript();
        token = deployer.run(Environment.Foundry);

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
