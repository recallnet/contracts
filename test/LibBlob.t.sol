// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {
    Account as CreditAccount,
    AddBlobParams,
    Approval,
    Blob,
    BlobStatus,
    BlobTuple,
    CreditApproval,
    SubnetStats,
    Subscriber,
    Subscription,
    SubscriptionGroup
} from "../src/types/BlobTypes.sol";
import {LibBlob} from "../src/wrappers/LibBlob.sol";
import {LibWasm} from "../src/wrappers/LibWasm.sol";

contract LibBlobTest is Test {
    using LibBlob for bytes;

    function testDecodeSubnetStats() public view {
        bytes memory data =
            hex"8d4b000a96b8e6cac7bd69c1f71b000009fffffffff50b520092f2d4180abe5bdab16ef96140000000004c00021142cb3f19fe361000004b0001ece0d8c484fb900000a1647261746584001ab34b9f101a7bc907151a00c097ce0a0600000000";
        SubnetStats memory stats = data.decodeSubnetStats();
        assertEq(stats.balance, 50003999999259732197879);
        assertEq(stats.capacityFree, 10995116277749);
        assertEq(stats.capacityUsed, 11);
        assertEq(stats.creditSold, 50004000000000000000000000000000000000000);
        assertEq(stats.creditCommitted, 2499364000000000000000000);
        assertEq(stats.creditDebited, 9092000000000000000000);
        assertEq(stats.tokenCreditRate, 1000000000000000000000000000000000000);
        assertEq(stats.numAccounts, 10);
        assertEq(stats.numBlobs, 6);
        assertEq(stats.numAdded, 0);
        assertEq(stats.bytesAdded, 0);
        assertEq(stats.numResolving, 0);
        assertEq(stats.bytesResolving, 0);
    }

    function testDecodeAccount() public view {
        // No approvals
        bytes memory data =
            hex"890052000eb194f8e1ae525fd5dcfab0800000000040f6190258a0a01a000151804b00010f0cf064dd59200000";
        CreditAccount memory account = data.decodeAccount();
        assertEq(account.capacityUsed, 0);
        assertEq(account.creditFree, 5000000000000000000000000000000000000000);
        assertEq(account.creditCommitted, 0);
        assertEq(account.creditSponsor, address(0));
        assertEq(account.lastDebitEpoch, 600);
        assertEq(account.approvalsTo.length, 0);
        assertEq(account.approvalsFrom.length, 0);
        assertEq(account.maxTtl, 86400);
        assertEq(account.gasAllowance, 5000000000000000000000);

        // With all fields set: approvals to two different accounts, approvals from one account, and all optionals (set
        // credit limit, gas fee limit, and ttl)
        data =
            hex"891152000eb316287ea5e336f1a66fbd7e21c000004c000135afae88fd38f250000056040a15d34aaf54267db7d7c367839aaf71a00a2c6a65190518a256040a15d34aaf54267db7d7c367839aaf71a00a2c6a65855400047bf19673df52e37f2410011d10000000000045003b9aca001915764b00c941498854fdb20000004056040a9965507d1a55bcc2695c58ba16fb37d819b0a4dc85f6f6f64040a156040a14dc79964da2c08b23698b3d3cc7ca32193d995585f6f6f640401a000151804b00010f28b1d2070cc7ee37";
        account = data.decodeAccount();
        assertEq(account.capacityUsed, 17);
        assertEq(account.creditFree, 5001999999999998531056000000000000000000);
        assertEq(account.creditCommitted, 1462452000000000000000000);
        assertEq(account.creditSponsor, 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
        assertEq(account.lastDebitEpoch, 1304);
        assertEq(account.approvalsTo.length, 2);
        assertEq(account.approvalsFrom.length, 1);
        assertEq(account.maxTtl, 86400);
        assertEq(account.gasAllowance, 5001999999735404424759);
        assertEq(account.approvalsTo[0].addr, 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
        assertEq(account.approvalsTo[0].approval.creditLimit, 100000000000000000000000000000000000000000000);
        assertEq(account.approvalsTo[0].approval.gasFeeLimit, 1000000000);
        assertEq(account.approvalsTo[0].approval.expiry, 5494);
        assertEq(account.approvalsTo[0].approval.creditUsed, 950400000000000000000000);
        assertEq(account.approvalsTo[0].approval.gasFeeUsed, 0);
        assertEq(account.approvalsTo[1].addr, 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
        assertEq(account.approvalsTo[1].approval.creditLimit, 0);
        assertEq(account.approvalsTo[1].approval.gasFeeLimit, 0);
        assertEq(account.approvalsTo[1].approval.expiry, 0);
        assertEq(account.approvalsTo[1].approval.creditUsed, 0);
        assertEq(account.approvalsTo[1].approval.gasFeeUsed, 0);
        assertEq(account.approvalsFrom[0].addr, 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);
        assertEq(account.approvalsFrom[0].approval.creditLimit, 0);
        assertEq(account.approvalsFrom[0].approval.gasFeeLimit, 0);
        assertEq(account.approvalsFrom[0].approval.expiry, 0);
        assertEq(account.approvalsFrom[0].approval.creditUsed, 0);
        assertEq(account.approvalsFrom[0].approval.gasFeeUsed, 0);
    }

    function testEncodeApproveCreditParams() public pure {
        address from = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        address to = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        address[] memory caller = new address[](2);
        caller[0] = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;
        caller[1] = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
        uint256 creditLimit = 12345;
        uint256 gasFeeLimit = 987654321;
        uint64 ttl = 4000;
        bytes memory params = LibBlob.encodeApproveCreditParams(from, to, caller, creditLimit, gasFeeLimit, ttl);
        assertEq(
            params,
            hex"8656040a90f79bf6eb2c4f870365e785982e1f101e93b90656040a15d34aaf54267db7d7c367839aaf71a00a2c6a658256040a976ea74026e726554db657fa54763abd0c3a0aa956040a14dc79964da2c08b23698b3d3cc7ca32193d99554b00029d394a5d630544000045003ade68b1190fa0"
        );
    }

    function testEncodeRevokeCreditParams() public pure {
        address from = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        address to = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        address caller = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        bytes memory params = LibBlob.encodeRevokeCreditParams(from, to, caller);
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
            ttl: 0, // Null value
            from: address(0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045) // vitalik.eth
        });
        bytes memory encoded = LibBlob.encodeAddBlobParams(params);
        assertEq(
            encoded,
            hex"88f69820184518b61888181a18c01848184b1875188418ce18aa18e01838181c1833187218c118b3187118a418a818ea18e9184215189b18aa189a18e618d40e18e49820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a189998200000000000000000000000000000000000000000000000000000000000000000a165696e6e65726006f656040ad8da6bf26964af9d7eed9e03e53415d37aa96045"
        );
    }

    function testEncodeDecodeSubscriptionId() public view {
        // A small key string
        string memory key = "foo";
        bytes memory data = LibBlob.encodeSubscriptionId(key);
        assertEq(data, hex"a165696e6e657263666f6f");
        string memory decoded = LibBlob.decodeSubscriptionId(data);
        assertEq(decoded, key);
        key = "f";
        data = LibBlob.encodeSubscriptionId(key);
        assertEq(data, hex"a165696e6e65726166");
        decoded = LibBlob.decodeSubscriptionId(data);
        assertEq(decoded, key);

        // Max 64 bytes
        key = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
        data = LibBlob.encodeSubscriptionId(key);
        assertEq(
            data,
            hex"a165696e6e6572784061616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161"
        );
        decoded = LibBlob.decodeSubscriptionId(data);
        assertEq(decoded, key);

        // Default case
        key = "";
        data = LibBlob.encodeSubscriptionId(key);
        assertEq(data, hex"a165696e6e657260");
        decoded = LibBlob.decodeSubscriptionId(data);
        assertEq(decoded, "");
    }

    function testDecodeSubscribers() public view {
        // One subscriber
        bytes memory data =
            hex"a1656630313234a17840343564616464393261326161373431383133323638376639613432313439306261643963356161643332656134653937623135356533373739316630306435308519021f1a0001539f982018fd18bb1871185b08188508184418a1183e182b18b518980118cb18a60218bf183b18351118720418fb18f41836188101181b18ef18941839f6f4";
        Subscriber[] memory subscribers = LibBlob.decodeSubscribers(data);
        // Note: tests will always show this as a masked ID address, but in reality, it's a looked up delegated address
        assertEq(subscribers[0].subscriber, 0xFf0000000000000000000000000000000000007C);
        assertEq(
            subscribers[0].subscriptionGroup[0].subscriptionId,
            "45dadd92a2aa7418132687f9a421490bad9c5aad32ea4e97b155e37791f00d50"
        );
        assertEq(subscribers[0].subscriptionGroup[0].subscription.added, 543);
        assertEq(subscribers[0].subscriptionGroup[0].subscription.expiry, 86943);
        assertEq(
            subscribers[0].subscriptionGroup[0].subscription.source,
            "7w5xcwyiqueejij6fo2zqaoluybl6ozvcfzaj67ug2aqcg7psq4q"
        );
        assertEq(subscribers[0].subscriptionGroup[0].subscription.delegate, address(0));
        assertEq(subscribers[0].subscriptionGroup[0].subscription.failed, false);

        // Two subscription groups
        data =
            hex"a1656630313234a2784034316664336363386562303731323262663165356564383562306236393237666236663162336630643662313331326261366531396437646536386366373833851908eb1a00015a6b982018fd18bb1871185b08188508184418a1183e182b18b518980118cb18a60218bf183b18351118720418fb18f41836188101181b18ef18941839f6f47840343564616464393261326161373431383133323638376639613432313439306261643963356161643332656134653937623135356533373739316630306435308519021f1a0001539f982018fd18bb1871185b08188508184418a1183e182b18b518980118cb18a60218bf183b18351118720418fb18f41836188101181b18ef18941839f6f4";
        subscribers = LibBlob.decodeSubscribers(data);
        // Note: tests will always show this as a masked ID address, but in reality, it's a looked up delegated address
        assertEq(subscribers[0].subscriber, 0xFf0000000000000000000000000000000000007C);
        assertEq(
            subscribers[0].subscriptionGroup[0].subscriptionId,
            "41fd3cc8eb07122bf1e5ed85b0b6927fb6f1b3f0d6b1312ba6e19d7de68cf783"
        );
        assertEq(
            subscribers[0].subscriptionGroup[1].subscriptionId,
            "45dadd92a2aa7418132687f9a421490bad9c5aad32ea4e97b155e37791f00d50"
        );

        // // Two different subscribers
        data =
            hex"a2656630313234a2784034316664336363386562303731323262663165356564383562306236393237666236663162336630643662313331326261366531396437646536386366373833851908eb1a00015a6b982018fd18bb1871185b08188508184418a1183e182b18b518980118cb18a60218bf183b18351118720418fb18f41836188101181b18ef18941839f6f47840343564616464393261326161373431383133323638376639613432313439306261643963356161643332656134653937623135356533373739316630306435308519021f1a0001539f982018fd18bb1871185b08188508184418a1183e182b18b518980118cb18a60218bf183b18351118720418fb18f41836188101181b18ef18941839f6f4656630313236a1784033333566316434636333343130646136363562613133336136616339653666656536626334653861356435643239336262333966396465313266303530326438851909881a00015b08982018fd18bb1871185b08188508184418a1183e182b18b518980118cb18a60218bf183b18351118720418fb18f41836188101181b18ef18941839f6f4";
        subscribers = LibBlob.decodeSubscribers(data);
        // Note: tests will always show this as a masked ID address, but in reality, it's a looked up delegated address
        assertEq(subscribers[0].subscriber, 0xFf0000000000000000000000000000000000007C);
        assertEq(subscribers[1].subscriber, 0xFF0000000000000000000000000000000000007e);
    }

    function testDecodeSubscriptionGroup() public view {
        bytes memory data =
            hex"a17840343564616464393261326161373431383133323638376639613432313439306261643963356161643332656134653937623135356533373739316630306435308519021f1a0001539f982018fd18bb1871185b08188508184418a1183e182b18b518980118cb18a60218bf183b18351118720418fb18f41836188101181b18ef18941839f6f4";
        SubscriptionGroup[] memory subscriptionGroup = LibBlob.decodeSubscriptionGroup(data);
        assertEq(
            subscriptionGroup[0].subscriptionId, "45dadd92a2aa7418132687f9a421490bad9c5aad32ea4e97b155e37791f00d50"
        );
        assertEq(subscriptionGroup[0].subscription.added, 543);
        assertEq(subscriptionGroup[0].subscription.expiry, 86943);
        assertEq(subscriptionGroup[0].subscription.source, "7w5xcwyiqueejij6fo2zqaoluybl6ozvcfzaj67ug2aqcg7psq4q");
        assertEq(subscriptionGroup[0].subscription.delegate, address(0));
        assertEq(subscriptionGroup[0].subscription.failed, false);
    }

    function testDecodeSubscription() public view {
        // No delegate
        bytes memory data =
            hex"8519021f1a0001539f982018fd18bb1871185b08188508184418a1183e182b18b518980118cb18a60218bf183b18351118720418fb18f41836188101181b18ef18941839f6f4";
        Subscription memory subscription = LibBlob.decodeSubscription(data);
        assertEq(subscription.added, 543);
        assertEq(subscription.expiry, 86943);
        assertEq(subscription.source, "7w5xcwyiqueejij6fo2zqaoluybl6ozvcfzaj67ug2aqcg7psq4q");
        assertEq(subscription.delegate, address(0));
        assertEq(subscription.failed, false);

        // With delegate
        data =
            hex"85190b911a00015d11982018fd18bb1871185b08188508184418a1183e182b18b518980118cb18a60218bf183b18351118720418fb18f41836188101181b18ef1894183942007df4";
        subscription = LibBlob.decodeSubscription(data);
        assertEq(subscription.added, 2961);
        assertEq(subscription.expiry, 89361);
        assertEq(subscription.source, "7w5xcwyiqueejij6fo2zqaoluybl6ozvcfzaj67ug2aqcg7psq4q");
        // Note: tests will always show this as a masked ID address, but in reality, it's a looked up delegated address
        assertEq(subscription.delegate, 0xFF0000000000000000000000000000000000007D);
        assertEq(subscription.failed, false);
    }

    function testDecodeAddedOrPendingBlobs() public view {
        // Single blob
        bytes memory data =
            hex"81829820182718c118b318c218610518aa0f183a18bc188f0a182c182b18b418af18f8184c18c111188218960618cf187f18c9181818fa18881822188218c9818356040acafeb0ba00000000000000000000000000000000a165696e6e657260982001184518fe18d118ba18fb1518ae184406189318e2186b18e1186518b1189018ee182f18901518250418c4181d187c18b318b3185c18191318ae";
        BlobTuple[] memory blobs = LibBlob.decodeAddedOrPendingBlobs(data);
        assertEq(blobs[0].blobHash, "e7a3hqtbawva6ov4r4fcyk5uv74ezqirqklant37zempvcbcqleq");
        assertEq(blobs[0].sourceInfo[0].subscriber, 0xCafeB0ba00000000000000000000000000000000);
        assertEq(blobs[0].sourceInfo[0].subscriptionId, "");
        assertEq(blobs[0].sourceInfo[0].source, "afc75un27mk24ragsprgxylfwgio4l4qcusqjra5psz3gxazcoxa");
    }

    function testDecodeBlob() public view {
        bytes memory data =
            hex"84069820185818300918d918fc011819188d18b0150818dc186b18c918e618f10a185c18ef189118a3185d1864186d187318a518b718a8181918cd18b0184da1656630313234a17840343564616464393261326161373431383133323638376639613432313439306261643963356161643332656134653937623135356533373739316630306435308519021f1a0001539f982018fd18bb1871185b08188508184418a1183e182b18b518980118cb18a60218bf183b18351118720418fb18f41836188101181b18ef18941839f6f4685265736f6c766564";
        Blob memory blob = LibBlob.decodeBlob(data);
        assertEq(blob.size, 6);
        assertEq(blob.metadataHash, "layatwp4aemy3mavbdogxspg6effz34runowi3ltuw32qgonwbgq");
        assertEq(blob.subscribers.length, 1);
        assertEq(uint8(blob.status), uint8(BlobStatus.Resolved));
    }

    function testDecodeBlobStatus() public view {
        bytes memory status = hex"685265736F6C766564"; // Resolved
        bytes memory decoded = LibWasm.decodeCborStringToBytes(status);
        BlobStatus decodedStatus = LibBlob.decodeBlobStatus(decoded);
        assertEq(uint8(decodedStatus), uint8(BlobStatus.Resolved));
    }

    function testDecodeTokenCreditRate() public view {
        bytes memory data = hex"a1647261746584001ab34b9f101a7bc907151a00c097ce";
        uint256 rate = LibBlob.decodeTokenCreditRate(data);
        assertEq(rate, 1000000000000000000000000000000000000);
    }
}
