// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Staking} from "../src/Staking.sol";
import {Hoku} from "../src/Hoku.sol";
import {DeployScript} from "../script/Hoku.s.sol";

contract FaucetTest is Test {
    Staking internal staking;
    Hoku internal token;
    Vm.Wallet internal wallet;
    uint256 constant balance = 1000 * 1e18;

    function setUp() public virtual {
        DeployScript deployer = new DeployScript();
        token = deployer.run(Hoku.Environment.Local);
        wallet = vm.createWallet("test");
        staking = new Staking(IERC20(token));
        vm.prank(address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38));
        token.mint(wallet.addr, balance);
    }

    function test_Stake() public {
        assertEq(token.balanceOf(wallet.addr), balance);

        vm.prank(wallet.addr);
        token.approve(address(staking), 1000);

        vm.prank(wallet.addr);
        staking.deposit(500);

        assertEq(token.balanceOf(wallet.addr), balance - 500);
        assertEq(staking.rewards(wallet.addr), 0);
    }

    function test_StakeRewards() public {
        assertEq(token.balanceOf(wallet.addr), balance);

        vm.prank(wallet.addr);
        token.approve(address(staking), 1000);

        vm.warp(block.timestamp + 1 hours);
        vm.prank(wallet.addr);
        staking.deposit(500);

        assertEq(token.balanceOf(wallet.addr), balance - 500);

        vm.warp(block.timestamp + 2 hours);

        assertEq(staking.rewards(wallet.addr), 1);
    }
}
