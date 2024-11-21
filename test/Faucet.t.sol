// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript as FaucetDeployer} from "../script/Faucet.s.sol";
import {DeployScript as TokenDeployer} from "../script/Hoku.s.sol";
import {Faucet, TryLater} from "../src/token/Faucet.sol";
import {Hoku} from "../src/token/Hoku.sol";

contract FaucetTest is Test {
    Faucet internal faucet;
    Vm.Wallet internal wallet;
    Vm.Wallet internal chain;
    address internal constant TESTER = address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);
    string internal constant KEY = "test";
    uint256 internal constant MINT_AMOUNT = 1000 * 10 ** 18;

    function setUp() public virtual {
        chain = vm.createWallet("chain");
        vm.deal(chain.addr, MINT_AMOUNT);
        wallet = vm.createWallet("user");
        FaucetDeployer faucetDeployer = new FaucetDeployer();
        faucet = faucetDeployer.run(MINT_AMOUNT / 2);
        owner = faucet.owner();
        assertEq(faucet.supply(), MINT_AMOUNT / 2);
    }

    function testDripTransfer() public {
        assertEq(wallet.addr.balance, 0);

        vm.prank(owner);
        faucet.drip(payable(wallet.addr), KEY);

        assertEq(faucet.supply(), MINT_AMOUNT / 2 - faucet.dripAmount());
        assertEq(wallet.addr.balance, faucet.dripAmount());
    }

    function testDripTransferNoDelayFail() public {
        vm.prank(owner);
        faucet.drip(payable(wallet.addr), KEY);

        vm.expectRevert(TryLater.selector);
        vm.prank(owner);
        faucet.drip(payable(wallet.addr), KEY);
    }

    function testDripTransferDelay() public {
        vm.startPrank(owner);
        faucet.drip(payable(wallet.addr), KEY);

        vm.warp(block.timestamp + (5 minutes));
        
        faucet.drip(payable(wallet.addr), KEY);
        vm.stopPrank();

        assertEq(wallet.addr.balance, 2 * faucet.dripAmount());
    }

    function testFundFaucet() public {
        vm.prank(chain.addr);
        faucet.fund{value: 100}();

        assertEq(faucet.supply(), MINT_AMOUNT / 2 + 100);
    }
}
