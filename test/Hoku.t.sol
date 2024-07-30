// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/Hoku.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract HokuTest is Test {
    Hoku public token;
    address public deployer;
    address public user;

    function setUp() public {
        // Deploy proxy
        address proxy = Upgrades.deployUUPSProxy(
            "Hoku.sol",
            abi.encodeCall(Hoku.initialize, ("Hoku", "tHOKU"))
        );

        deployer = address(this);
        user = address(0x123);

        // Deploy the implementation contract
        token = Hoku(proxy);
    }

    function testMinting() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        token.mint(user, mintAmount);

        assertEq(token.balanceOf(user), mintAmount);
    }

    function testOnlyOwnerCanMint() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        // deployer mints to user
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
