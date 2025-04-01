// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Test, Vm} from "forge-std/Test.sol";

import {DeployScript as FaucetDeployer} from "../script/Faucet.s.sol";
import {DeployScript as TokenDeployer} from "../script/Recall.s.sol";
import {Faucet, TryLater} from "../src/token/Faucet.sol";
import {Recall} from "../src/token/Recall.sol";

contract FaucetTest is Test {
    Faucet internal faucet;
    Vm.Wallet internal wallet;
    Vm.Wallet internal wallet2;
    Vm.Wallet internal chain;
    address internal owner;
    uint256 internal constant MINT_AMOUNT = 1000 * 10 ** 18;
    string[] internal keys = ["test1", "test2"];
    Recall internal token;

    function setUp() public virtual {
        chain = vm.createWallet("chain");
        vm.deal(chain.addr, MINT_AMOUNT);
        wallet = vm.createWallet("user");
        wallet2 = vm.createWallet("user2");
        FaucetDeployer faucetDeployer = new FaucetDeployer();
        faucet = faucetDeployer.run(MINT_AMOUNT / 2);
        owner = faucet.owner();
        assertEq(faucet.supply(), MINT_AMOUNT / 2);
    }

    function testDripTransfer() public {
        assertEq(wallet.addr.balance, 0);

        vm.prank(owner);
        faucet.drip(payable(wallet.addr), keys);

        assertEq(faucet.supply(), MINT_AMOUNT / 2 - faucet.dripAmount());
        assertEq(wallet.addr.balance, faucet.dripAmount());
    }

    function testDripTransferNoDelayFail() public {
        vm.prank(owner);
        faucet.drip(payable(wallet.addr), keys);

        vm.expectRevert(TryLater.selector);
        vm.prank(owner);
        faucet.drip(payable(wallet.addr), keys);
    }

    function testDripTransferDelay() public {
        vm.startPrank(owner);
        faucet.drip(payable(wallet.addr), keys);

        vm.warp(block.timestamp + (12 hours));

        faucet.drip(payable(wallet.addr), keys);
        vm.stopPrank();

        assertEq(wallet.addr.balance, 2 * faucet.dripAmount());
    }

    function testFundFaucet() public {
        vm.prank(chain.addr);
        faucet.fund{value: 100}();

        assertEq(faucet.supply(), MINT_AMOUNT / 2 + 100);
    }

    function testUnauthorizedDripFails() public {
        vm.prank(wallet.addr);
        vm.expectRevert(abi.encodeWithSelector(Faucet.UnauthorizedCaller.selector, wallet.addr));
        faucet.drip(payable(wallet2.addr), keys);
    }

    function testAuthorizeCaller() public {
        // Authorize wallet
        vm.prank(owner);
        faucet.authorizeCaller(wallet.addr);

        // Should now be able to drip
        vm.prank(wallet.addr);
        faucet.drip(payable(wallet2.addr), keys);

        assertEq(wallet2.addr.balance, faucet.dripAmount());
    }

    function testDeauthorizeCaller() public {
        // First authorize wallet
        vm.prank(owner);
        faucet.authorizeCaller(wallet.addr);

        // Then deauthorize wallet
        vm.prank(owner);
        faucet.deauthorizeCaller(wallet.addr);

        // Should fail to drip
        vm.prank(wallet.addr);
        vm.expectRevert(abi.encodeWithSelector(Faucet.UnauthorizedCaller.selector, wallet.addr));
        faucet.drip(payable(wallet2.addr), keys);
    }

    function testOnlyOwnerCanAuthorize() public {
        vm.prank(wallet.addr);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, wallet.addr));
        faucet.authorizeCaller(wallet2.addr);
    }

    function testOnlyOwnerCanDeauthorize() public {
        vm.prank(wallet.addr);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, wallet.addr));
        faucet.deauthorizeCaller(wallet2.addr);
    }

    function testOwnerCanAlwaysDrip() public {
        // Owner should be able to drip without being explicitly authorized
        vm.prank(owner);
        faucet.drip(payable(wallet.addr), keys);

        assertEq(wallet.addr.balance, faucet.dripAmount());
    }
}
