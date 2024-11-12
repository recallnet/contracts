// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {
    Account as CreditAccount,
    AddBlobParams,
    Approvals,
    BlobTuple,
    SubnetStats,
    SubscriptionGroup
} from "../src/types/BlobTypes.sol";
import {LibBlob} from "../src/util/LibBlob.sol";
import {LibWasm} from "../src/util/LibWasm.sol";

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

    function testEncodeDecodeSubscriptionId() public view {
        // A small key string
        string memory key = "foo";
        bytes memory data = LibBlob.encodeSubscriptionId(key);
        assertEq(data, hex"a1634b6579831866186f186f");
        string memory decoded = LibBlob.decodeSubscriptionId(data);
        assertEq(decoded, key);

        // Max 255 bytes
        key =
            "foofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoo";
        data = LibBlob.encodeSubscriptionId(key);
        assertEq(
            data,
            hex"a1634b657998ff1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f"
        );
        decoded = LibBlob.decodeSubscriptionId(data);
        assertEq(decoded, key);

        // Default case
        key = "";
        data = LibBlob.encodeSubscriptionId(key);
        assertEq(data, hex"6744656661756c74");
        decoded = LibBlob.decodeSubscriptionId(data);
        assertEq(decoded, "Default");
    }

    function testDecodeSubscribers() public view {
        // One subscriber
        bytes memory data =
            hex"a156040a90f79bf6eb2c4f870365e785982e1f101e93b906a26744656661756c74861903d1192b8cf59820181a187918eb18c1051858185b188518a518ba18a5187a18d018b1182118fc18ec189d189b185418eb0c18ef18ea18f7189e0f1866185411185818aef6f4a1634b6579982018a118a7182203183b184c184d18b0186e18c918c018a718e01899186f1821184d18a4189b187318f318df18c0187618e61518d002182918d4184118d086190f77191d87f59820181a187918eb18c1051858185b188518a518ba18a5187a18d018b1182118fc18ec189d189b185418eb0c18ef18ea18f7189e0f1866185411185818aef6f4";
        SubscriptionGroup[] memory subscribers = LibBlob.decodeSubscribers(data);
        assertEq(subscribers[0].subscriber, 0x90F79bf6EB2c4f870365E785982E1f101E93b906);
        assertEq(subscribers[0].subscriptionId, "Default");
        assertEq(subscribers[0].added, 977);
        assertEq(subscribers[0].expiry, 11148);
        assertEq(subscribers[0].autoRenew, true);
        assertEq(subscribers[0].source, "dj46xqiflbnyljn2uv5nbmjb7twj3g2u5mgo72xxtyhwmvarlcxa");
        assertEq(subscribers[0].delegateOrigin, address(0));
        assertEq(subscribers[0].delegateCaller, address(0));
        assertEq(subscribers[0].failed, false);

        // // Two subscribers
        // data =
        //     hex"a256040a90f79bf6eb2c4f870365e785982e1f101e93b906a26744656661756c74861903d1192b8cf59820181a187918eb18c1051858185b188518a518ba18a5187a18d018b1182118fc18ec189d189b185418eb0c18ef18ea18f7189e0f1866185411185818aef6f4a1634b6579982018a118a7182203183b184c184d18b0186e18c918c018a718e01899186f1821184d18a4189b187318f318df18c0187618e61518d002182918d4184118d086190f77192b98f59820181a187918eb18c1051858185b188518a518ba18a5187a18d018b1182118fc18ec189d189b185418eb0c18ef18ea18f7189e0f1866185411185818aef6f456040a976ea74026e726554db657fa54763abd0c3a0aa9a16744656661756c7486191d9c192bacf59820181a187918eb18c1051858185b188518a518ba18a5187a18d018b1182118fc18ec189d189b185418eb0c18ef18ea18f7189e0f1866185411185818aef6f4";
        // subscribers = LibBlob.decodeSubscribers(data);
        // assertEq(subscribers[0].subscriber, 0x90F79bf6EB2c4f870365E785982E1f101E93b906);
        // assertEq(subscribers[0].subscriptionId, "Default");
        // assertEq(subscribers[1].subscriber, 0x976EA74026E726554dB657fA54763abd0C3a0aa9);
        // assertEq(subscribers[1].subscriptionId, "Default");
    }

    function testDecodeSubscription() public view {
        // No delegate
        bytes memory data =
            hex"8619045e19126ef59820184e1871182818b3189318920f011876188d189a182318c5189b185c18910b18f418cc18961876183518b6187a185c0418a318a2185f18ac18af1825f6f4";
        SubscriptionGroup memory subscription = LibBlob.decodeSubscription(data);
        assertEq(subscription.added, 1118);
        assertEq(subscription.expiry, 4718);
        assertEq(subscription.autoRenew, true);
        assertEq(subscription.source, "jzysrm4tsihqc5untir4lg24sef7jtewoy23m6s4asr2ex5mv4sq");
        assertEq(subscription.delegateOrigin, address(0));
        assertEq(subscription.delegateCaller, address(0));
        assertEq(subscription.failed, false);

        // With delegate
        data =
            hex"86191a54192864f59820184e1871182818b3189318920f011876188d189a182318c5189b185c18910b18f418cc18961876183518b6187a185c0418a318a2185f18ac18af18258256040aa0ee7a142d267c1f36714e4a8f75612f20a7972056040a11c81c1a7979cdd309096d1ea53f887ea9f8d14df4";
        subscription = LibBlob.decodeSubscription(data);
        assertEq(subscription.added, 6740);
        assertEq(subscription.expiry, 10340);
        assertEq(subscription.autoRenew, true);
        assertEq(subscription.source, "jzysrm4tsihqc5untir4lg24sef7jtewoy23m6s4asr2ex5mv4sq");
        assertEq(subscription.delegateOrigin, 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);
        assertEq(subscription.delegateCaller, 0x11c81c1A7979cdd309096D1ea53F887EA9f8D14d);
        assertEq(subscription.failed, false);
    }

    function testDecodePendingBlobs() public view {
        bytes memory data =
            hex"8182982018a1189d18c605187b1818188c18bd186718ea1839186618fd188d182c18a2188318f4185a187718d9185c182d18a51861189318ca189818d0187b183c18a7818356040a90f79bf6eb2c4f870365e785982e1f101e93b906a1634b657998201837182f183318e505188d18d7081870184d18d718de18180c185e183318f51857189a18c518b1187518781845184418b718a7183f182b189c18b018be9820181a187918eb18c1051858185b188518a518ba18a5187a18d018b1182118fc18ec189d189b185418eb0c18ef18ea18f7189e0f1866185411185818ae";
        BlobTuple[] memory blobs = LibBlob.decodePendingBlobs(data);
        assertEq(blobs[0].blobHash, "ugo4mbl3dcgl2z7khftp3djmukb7iwtx3foc3jlbspfjrud3hstq");
        assertEq(blobs[0].sourceInfo.subscriber, 0x90F79bf6EB2c4f870365E785982E1f101E93b906);
        assertEq(
            bytes(blobs[0].sourceInfo.subscriptionId),
            hex"372f33e5058dd708704dd7de180c5e33f5579ac5b175784544b7a73f2b9cb0be"
        );
        assertEq(blobs[0].sourceInfo.source, "dj46xqiflbnyljn2uv5nbmjb7twj3g2u5mgo72xxtyhwmvarlcxa");
    }
}
