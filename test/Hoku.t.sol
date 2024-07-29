// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/Hoku.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HokuTest is Test {
    Hoku public token;
    address public deployer;
    address public user;

    function setUp() public {
        deployer = address(this);
        user = address(0x123);

        token = new Hoku("Hoku", "tHOKU");
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
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user
            )
        );
        token.mint(user, mintAmount);
    }
}
