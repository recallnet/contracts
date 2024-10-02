// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript as FaucetDeployer} from "../script/Faucet.s.sol";
import {DeployScript as TokenDeployer} from "../script/Hoku.s.sol";
import {Faucet, TryLater} from "../src/Faucet.sol";
import {Hoku} from "../src/Hoku.sol";
import {Environment} from "../src/util/Types.sol";

contract FaucetTest is Test {
    Faucet internal faucet;
    Vm.Wallet internal wallet;
    Vm.Wallet internal chain;
    address constant tester = address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);
    uint256 constant mintAmount = 1000 * 10 ** 18;

    function setUp() public virtual {
        chain = vm.createWallet("chain");
        vm.deal(chain.addr, mintAmount);
        wallet = vm.createWallet("user");
        vm.prank(chain.addr);
        FaucetDeployer faucetDeployer = new FaucetDeployer();
        faucet = faucetDeployer.run(Environment.Local, mintAmount / 2);
        assertEq(faucet.supply(), mintAmount / 2);
    }

    function test_DripTransfer() public {
        assertEq(wallet.addr.balance, 0);

        faucet.drip(payable(wallet.addr));

        assertEq(faucet.supply(), mintAmount / 2 - faucet.dripAmount());
        assertEq(wallet.addr.balance, faucet.dripAmount());
    }

    function test_DripTransferNoDelayFail() public {
        faucet.drip(payable(wallet.addr));

        vm.expectRevert(TryLater.selector);
        faucet.drip(payable(wallet.addr));
    }

    function test_DripTransferDelay() public {
        faucet.drip(payable(wallet.addr));

        vm.warp(block.timestamp + (5 minutes));

        faucet.drip(payable(wallet.addr));

        assertEq(wallet.addr.balance, 2 * faucet.dripAmount());
    }

    function test_FundFaucet() public {
        vm.prank(chain.addr);
        faucet.fund{value: 100}();

        assertEq(faucet.supply(), mintAmount / 2 + 100);
    }
}
