// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {Account as CreditAccount, AddBlobParams, Approvals, SubnetStats} from "../src/types/BlobTypes.sol";
import {LibBlob} from "../src/util/LibBlob.sol";

contract LibBlobTest is Test {
    using LibBlob for bytes;

    function testDecodeSubnetStats() public view {
        bytes memory data =
            hex"8a4b000a9796f236ae8f10000082018200018201810c8201831a8f1000001a96f236ae190a97820181194a2e82018119b4ea010a0100";
        SubnetStats memory stats = data.decodeSubnetStats();
        assertEq(stats.balance, 50020000000000000000000);
        assertEq(stats.capacityTotal, 4294967296);
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
        assertEq(approvals[0].approval[0].approval.used, 0);

        data =
            hex"a156040a15d34aaf54267db7d7c367839aaf71a00a2c6a65a256040a23618e81e3f5cdf7f54c3d65f7fbc0abf5b21e8f83f6f682008056040a9965507d1a55bcc2695c58ba16fb37d819b0a4dc83f619edf7820080";
        approvals = data.decodeApprovals();
        assertEq(approvals[0].receiver, 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
        assertEq(approvals[0].approval[0].requiredCaller, 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
        assertEq(approvals[0].approval[0].approval.limit, 0);
        assertEq(approvals[0].approval[0].approval.expiry, 0);
        assertEq(approvals[0].approval[0].approval.used, 0);
        assertEq(approvals[0].approval[1].requiredCaller, 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
        assertEq(approvals[0].approval[1].approval.limit, 0);
        assertEq(approvals[0].approval[1].approval.expiry, 60919);
        assertEq(approvals[0].approval[1].approval.used, 0);
    }

    function testEncodeApproveCreditParams() public pure {
        address from = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        address receiver = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        address requiredCaller = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        uint256 limit = 1000;
        uint64 ttl = 3600;
        bytes memory params = LibBlob.encodeApproveCreditParams(from, receiver, requiredCaller, limit, ttl);
        assertEq(
            params,
            hex"8556040a90f79bf6eb2c4f870365e785982e1f101e93b90656040a15d34aaf54267db7d7c367839aaf71a00a2c6a6556040a15d34aaf54267db7d7c367839aaf71a00a2c6a65811903e8190e10"
        );
    }

    function testEncodeRevokeCreditParams() public pure {
        address from = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        address receiver = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        address requiredCaller = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        bytes memory params = LibBlob.encodeRevokeCreditParams(from, receiver, requiredCaller);
        assertEq(
            params,
            hex"8356040a90f79bf6eb2c4f870365e785982e1f101e93b90656040a15d34aaf54267db7d7c367839aaf71a00a2c6a6556040a15d34aaf54267db7d7c367839aaf71a00a2c6a65"
        );
    }

    function testEncodeAddBlobParams() public pure {
        AddBlobParams memory params = AddBlobParams({
            sponsor: address(0),
            source: "iw3iqgwajbfxlbgovlqdqhbtola3g4nevdvosqqvtovjvzwub3sa",
            blobHash: "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq",
            // TODO: update this once the dummy value is replaced with a blake3 hash; it's hardcoded as `[32; 0]`
            metadataHash: "",
            subscriptionId: "",
            size: 6,
            ttl: 0 // Null value
        });
        bytes memory encoded = LibBlob.encodeAddBlobParams(params);
        assertEq(
            encoded,
            hex"87f69820184518b61888181a18c01848184b1875188418ce18aa18e01838181c1833187218c118b3187118a418a818ea18e9184215189b18aa189a18e618d40e18e49820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a1899982000000000000000000000000000000000000000000000000000000000000000006744656661756c7406f6"
        );
    }
}
