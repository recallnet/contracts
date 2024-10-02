// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {StdUtils} from "forge-std/StdUtils.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript as CreditsDeployer} from "../script/Credits.s.sol";
import {Account as CreditAccount, Credits} from "../src/Credits.sol";
import {Balance, Environment} from "../src/util/Types.sol";

contract CreditsTest is Test, Credits {
    Credits internal credits;
    Vm.Wallet internal wallet;
    Vm.Wallet internal chain;
    uint256 constant mintAmount = 1000 * 10 ** 18;
    uint256 privateKey = StdUtils.bytesToUint(hex"7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6");

    function setUp() public virtual {
        chain = vm.createWallet("chain");
        vm.deal(chain.addr, mintAmount);
        wallet = vm.createWallet(privateKey);
        vm.prank(chain.addr);
        CreditsDeployer creditsDeployer = new CreditsDeployer();
        credits = creditsDeployer.run(Environment.Local);
    }

    function testDecodeAccount() public view {
        bytes memory data = hex"85820181068201831ab33939da1ab8bbcad019021d8201811a6b49d2001a00010769a0";
        CreditAccount memory account = decodeAccount(data);
        assertEq(account.creditFree, 9992999999998199937498);
        assertEq(account.creditCommitted, 1800000000);
        assertEq(account.lastDebitEpoch, 67433);
    }

    // TODO: need to mock the Blobs actor, else, we get an error:` ActorNotFound()`
    // i.e., need integration tests for this because EVM layer doesn't include WASM
    // function testBuyCredit() public {
    //     Balance memory data = credits.buyCredit{value: 1 ether}(wallet.addr);
    //     assertEq(data.creditCommitted, 0x00);
    // }

    // function testApproveCredit() public {
    //     bytes memory data = credits.approveCredit(
    //         0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
    //     );
    //     assertEq(
    //         data,
    //         hex"8456040a15d34aaf54267db7d7c367839aaf71a00a2c6a65f6f6f6"
    //     );
    // }
}
