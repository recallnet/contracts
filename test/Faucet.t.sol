// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, Vm} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Faucet, TryLater} from "../src/Faucet.sol";
import {Hoku} from "../src/Hoku.sol";
import {DeployScript} from "../script/Hoku.s.sol";

contract FaucetTest is Test {
    Faucet internal faucet;
    Hoku internal token;
    Vm.Wallet internal wallet;

    function setUp() public virtual {
        DeployScript deployer = new DeployScript();
        token = deployer.run(Hoku.Environment.Local);
        wallet = vm.createWallet("test");
        faucet = new Faucet(IERC20(token));
        vm.prank(address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38));
        token.mint(address(faucet), 1000);
    }

    function test_DripTransfer() public {
        assertEq(token.balanceOf(wallet.addr), 0);

        faucet.drip(wallet.addr, 100);

        assertEq(token.balanceOf(wallet.addr), 100);
    }

    function test_DripTransferNoDelayFail() public {
        faucet.drip(wallet.addr, 100);

        vm.expectRevert(TryLater.selector);
        faucet.drip(wallet.addr, 100);
    }

    function test_DripTransferDelay() public {
        faucet.drip(wallet.addr, 100);

        vm.warp(block.timestamp + (5 minutes));

        faucet.drip(wallet.addr, 100);

        assertEq(token.balanceOf(wallet.addr), 200);
    }
}
