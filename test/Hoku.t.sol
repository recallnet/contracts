// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {Hoku} from "../src/Hoku.sol";
import {DeployScript} from "../script/Hoku.s.sol";
import {Upgrades, Options} from "@openzeppelin/foundry-upgrades/Upgrades.sol";

contract HokuTest is Test {
    Hoku internal token;
    address internal user;
    address internal testerAddress;

    function setUp() public {
        testerAddress = address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);
        DeployScript deployer = new DeployScript();
        token = deployer.run(Hoku.Environment.Local);

        user = address(0x123);
    }

    function testMinting() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        vm.prank(testerAddress);
        token.mint(user, mintAmount);

        assertEq(token.balanceOf(user), mintAmount);
    }

    function testOnlyOwnerCanMint() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        // deployer mints to user
        vm.prank(testerAddress);
        token.mint(user, mintAmount);

        assertEq(token.balanceOf(user), mintAmount);
    }

    function testImpersonatorCannotMint() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        vm.prank(user); // Impersonate the user
        vm.expectRevert();
        token.mint(user, mintAmount);
    }
}
