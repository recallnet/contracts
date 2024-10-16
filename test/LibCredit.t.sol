// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {Account as CreditAccount, Approvals, SubnetStats} from "../src/types/CreditTypes.sol";
import {LibCredit} from "../src/util/LibCredit.sol";

contract LibCreditTest is Test {
    using LibCredit for bytes;

    function testDecodeSubnetStats() public view {
        bytes memory data =
            hex"8a4b000a9796f236ae8f10000082018200018201810c8201831a8f1000001a96f236ae190a97820181194a2e82018119b4ea010a0100";
        SubnetStats memory stats = data.decodeSubnetStats();
        assertEq(stats.balance, 50020000000000000000000);
        assertEq(stats.capacityFree, 4294967296);
        assertEq(stats.capacityUsed, 12);
        assertEq(stats.creditSold, 50020000000000000000000);
        assertEq(stats.creditCommitted, 18990);
        assertEq(stats.creditDebited, 46314);
        assertEq(stats.creditDebitRate, 1);
        assertEq(stats.numAccounts, 10);
        assertEq(stats.numBlobs, 1);
        assertEq(stats.numResolving, 0);
    }

    function testDecodeAccount() public view {
        bytes memory data = hex"85820181068201831ab33939da1ab8bbcad019021d8201811a6b49d2001a00010769a0";
        CreditAccount memory account = data.decodeAccount();
        assertEq(account.creditFree, 9992999999998199937498);
        assertEq(account.creditCommitted, 1800000000);
        assertEq(account.lastDebitEpoch, 67433);
    }

    function testDecodeApprovals() public view {
        bytes memory data =
            hex"a156040a15d34aaf54267db7d7c367839aaf71a00a2c6a65a156040a23618e81e3f5cdf7f54c3d65f7fbc0abf5b21e8f83f6f6820080";
        Approvals[] memory approvals = data.decodeApprovals();
        assertEq(approvals[0].receiver, 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
        assertEq(approvals[0].approval[0].requiredCaller, 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
        assertEq(approvals[0].approval[0].approval.limit, 0);
        assertEq(approvals[0].approval[0].approval.expiry, 0);
        assertEq(approvals[0].approval[0].approval.committed, 0);

        data =
            hex"a156040a15d34aaf54267db7d7c367839aaf71a00a2c6a65a256040a23618e81e3f5cdf7f54c3d65f7fbc0abf5b21e8f83f6f682008056040a9965507d1a55bcc2695c58ba16fb37d819b0a4dc83f619edf7820080";
        approvals = data.decodeApprovals();
        assertEq(approvals[0].receiver, 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
        assertEq(approvals[0].approval[0].requiredCaller, 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
        assertEq(approvals[0].approval[0].approval.limit, 0);
        assertEq(approvals[0].approval[0].approval.expiry, 0);
        assertEq(approvals[0].approval[0].approval.committed, 0);
        assertEq(approvals[0].approval[1].requiredCaller, 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
        assertEq(approvals[0].approval[1].approval.limit, 0);
        assertEq(approvals[0].approval[1].approval.expiry, 60919);
        assertEq(approvals[0].approval[1].approval.committed, 0);
    }

    function testEncodeApproveCreditParams() public view {
        address from = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        address receiver = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        address requiredCaller = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        uint256 limit = 1000;
        uint64 ttl = 3600;
        bytes memory params = LibCredit.encodeApproveCreditParams(from, receiver, requiredCaller, limit, ttl);
        assertEq(
            params,
            hex"8556040a90f79bf6eb2c4f870365e785982e1f101e93b90656040a15d34aaf54267db7d7c367839aaf71a00a2c6a6556040a15d34aaf54267db7d7c367839aaf71a00a2c6a65811903e8190e10"
        );
    }

    function testEncodeRevokeCreditParams() public view {
        address from = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        address receiver = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        address requiredCaller = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        bytes memory params = LibCredit.encodeRevokeCreditParams(from, receiver, requiredCaller);
        assertEq(
            params,
            hex"8356040a90f79bf6eb2c4f870365e785982e1f101e93b90656040a15d34aaf54267db7d7c367839aaf71a00a2c6a6556040a15d34aaf54267db7d7c367839aaf71a00a2c6a65"
        );
    }
}
