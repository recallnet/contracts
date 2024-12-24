// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {
    Account as CreditAccount,
    AddBlobParams,
    Approval,
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
            hex"8d4b000a968163e7859f54fdc01b000009fffffffffa06520092efd1b8d0cf37be5aa1cae500000000004b00db8d0a662e2c080000004b00046a9b247c2d1ae00000a16472617465820184001ab34b9f101a7bc907151a00c097ce0a0100000000";
        SubnetStats memory stats = data.decodeSubnetStats();
        assertEq(stats.balance, 49999999989967561752000);
        assertEq(stats.capacityFree, 10995116277754);
        assertEq(stats.capacityUsed, 6);
        assertEq(stats.creditSold, 50000000000000000000000000000000000000000);
        assertEq(stats.creditCommitted, 1036800000000000000000000);
        assertEq(stats.creditDebited, 20856000000000000000000);
        assertEq(stats.tokenCreditRate, 1000000000000000000000000000000000000);
        assertEq(stats.numAccounts, 10);
        assertEq(stats.numBlobs, 1);
        assertEq(stats.numResolving, 0);
        assertEq(stats.bytesResolving, 0);
        assertEq(stats.numAdded, 0);
        assertEq(stats.bytesAdded, 0);
    }

    function testDecodeAccount() public view {
        // With approvals to two different accounts and multiple caller allowlists
        bytes memory data =
            hex"87820181068201831aad5c0b401a1ad10cd319010f820181195460f6193840a2782c663431306663786a75766c3275657a3633707636646d36627a766c33727561666379327466766264617a706984f6f68200808256040a976ea74026e726554db657fa54763abd0c3a0aa956040a14dc79964da2c08b23698b3d3cc7ca32193d9955782c66343130667335786b6f716267343474666b746e776b37356669357232787567647563766a64797736686d7184f6f68200808156040aa0ee7a142d267c1f36714e4a8f75612f20a797201a00015180";
        CreditAccount memory account = data.decodeAccount();
        assertEq(account.capacityUsed, 6);
        assertEq(account.creditFree, 5000999983793693264704);
        assertEq(account.creditCommitted, 21600);
        assertEq(account.creditSponsor, address(0));
        assertEq(account.lastDebitEpoch, 14400);
        assertEq(account.approvals[0].to, "f410fcxjuvl2uez63pv6dm6bzvl3ruafcy2tfvbdazpi");
        assertEq(account.approvals[0].approval.limit, 0);
        assertEq(account.approvals[0].approval.expiry, 0);
        assertEq(account.approvals[0].approval.used, 0);
        assertEq(account.approvals[0].approval.callerAllowlist[0], 0x976EA74026E726554dB657fA54763abd0C3a0aa9);
        assertEq(account.approvals[0].approval.callerAllowlist[1], 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);
        assertEq(account.approvals[1].to, "f410fs5xkoqbg44tfktnwk75fi5r2xugducvjdyw6hmq");
        assertEq(account.approvals[1].approval.limit, 0);
        assertEq(account.approvals[1].approval.expiry, 0);
        assertEq(account.approvals[1].approval.used, 0);
        assertEq(account.approvals[1].approval.callerAllowlist[0], 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);
        assertEq(account.maxTtlEpochs, 86400);

        // No approvals
        data = hex"87820181068201831a862266e01a1ad1084719010f820181195460f6194650a01a00015180";
        account = data.decodeAccount();
        assertEq(account.capacityUsed, 6);
        assertEq(account.creditFree, 5000999978793693243104);
        assertEq(account.creditCommitted, 21600);
        assertEq(account.creditSponsor, address(0));
        assertEq(account.lastDebitEpoch, 18000);
        assertEq(account.approvals.length, 0);
        assertEq(account.maxTtlEpochs, 86400);
    }

    function testDecodeApproval() public view {
        bytes memory data =
            hex"a2782c663431306663786a75766c3275657a3633707636646d36627a766c33727561666379327466766264617a706984f6f68200808156040a976ea74026e726554db657fa54763abd0c3a0aa9782c66343130667335786b6f716267343474666b746e776b37356669357232787567647563766a64797736686d7184f6f68200808156040aa0ee7a142d267c1f36714e4a8f75612f20a79720";
        Approval[] memory approval = data.decodeApprovals();
        assertEq(approval[0].to, "f410fcxjuvl2uez63pv6dm6bzvl3ruafcy2tfvbdazpi");
        assertEq(approval[0].approval.limit, 0);
        assertEq(approval[0].approval.expiry, 0);
        assertEq(approval[0].approval.used, 0);
        assertEq(approval[0].approval.callerAllowlist[0], 0x976EA74026E726554dB657fA54763abd0C3a0aa9);
        assertEq(approval[1].to, "f410fs5xkoqbg44tfktnwk75fi5r2xugducvjdyw6hmq");
        assertEq(approval[1].approval.limit, 0);
        assertEq(approval[1].approval.expiry, 0);
        assertEq(approval[1].approval.used, 0);
        assertEq(approval[1].approval.callerAllowlist[0], 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);
    }

    function testDecodeCreditApproval() public view {
        bytes memory data =
            hex"848201811903e8194dbe8200808256040a976ea74026e726554db657fa54763abd0c3a0aa956040a14dc79964da2c08b23698b3d3cc7ca32193d9955";
        CreditApproval memory approval = data.decodeCreditApproval();
        assertEq(approval.limit, 1000);
        assertEq(approval.expiry, 19902);
        assertEq(approval.used, 0);
        assertEq(approval.callerAllowlist[0], 0x976EA74026E726554dB657fA54763abd0C3a0aa9);

        data = hex"84f6f6820080f6";
        approval = data.decodeCreditApproval();
        assertEq(approval.limit, 0);
        assertEq(approval.expiry, 0);
        assertEq(approval.used, 0);
        assertEq(approval.callerAllowlist.length, 0);
    }

    function testEncodeApproveCreditParams() public pure {
        address from = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        address to = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        address[] memory caller = new address[](2);
        caller[0] = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
        caller[1] = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;
        uint256 limit = 1000;
        uint64 ttl = 3600;
        bytes memory params = LibBlob.encodeApproveCreditParams(from, to, caller, limit, ttl);
        assertEq(
            params,
            hex"8556040a90f79bf6eb2c4f870365e785982e1f101e93b90656040a15d34aaf54267db7d7c367839aaf71a00a2c6a658256040a14dc79964da2c08b23698b3d3cc7ca32193d995556040a976ea74026e726554db657fa54763abd0c3a0aa9811903e8190e10"
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
            ttl: 0 // Null value
        });
        bytes memory encoded = LibBlob.encodeAddBlobParams(params);
        assertEq(
            encoded,
            hex"87f69820184518b61888181a18c01848184b1875188418ce18aa18e01838181c1833187218c118b3187118a418a818ea18e9184215189b18aa189a18e618d40e18e49820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a189998200000000000000000000000000000000000000000000000000000000000000000a165696e6e65726006f6"
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
            hex"a1782c66343130667364337a7835786c667268796f6133663436637a716c71376361706a686f6967686d7a61676171a1784066616134333038396435643466366264383265346133623137306633353663613235386361396636336638386438336130383334353465653765393966633536861901021a00015282f4982018a018531418ce189d18fd1318300c18f218b618ef18b518d0189818a005188f18eb188618b218a4185b185f18d8184f18c11875187d188918d518a5f6f4";
        Subscriber[] memory subscribers = LibBlob.decodeSubscribers(data);
        assertEq(subscribers[0].subscriber, "f410fsd3zx5xlfrhyoa3f46czqlq7capjhoighmzagaq");
        assertEq(
            subscribers[0].subscriptionGroup[0].subscriptionId,
            "faa43089d5d4f6bd82e4a3b170f356ca258ca9f63f88d83a083454ee7e99fc56"
        );
        assertEq(subscribers[0].subscriptionGroup[0].subscription.added, 258);
        assertEq(subscribers[0].subscriptionGroup[0].subscription.expiry, 86658);
        assertEq(subscribers[0].subscriptionGroup[0].subscription.autoRenew, false);
        assertEq(
            subscribers[0].subscriptionGroup[0].subscription.source,
            "ubjrjtu57ujtadhsw3x3lueyuacy724gwksfwx6yj7axk7mj2wsq"
        );
        assertEq(subscribers[0].subscriptionGroup[0].subscription.delegate.origin, address(0));
        assertEq(subscribers[0].subscriptionGroup[0].subscription.delegate.caller, address(0));
        assertEq(subscribers[0].subscriptionGroup[0].subscription.failed, false);

        // Two subscription groups
        data =
            hex"a1782c66343130667364337a7835786c667268796f6133663436637a716c71376361706a686f6967686d7a61676171a278403537303535653366663334663366613730303165396439613733633465613932616435623832333564636563373162363035396337613535326366336264613086190d6c1a00015eecf4982018a018531418ce189d18fd1318300c18f218b618ef18b518d0189818a005188f18eb188618b218a4185b185f18d8184f18c11875187d188918d518a5f6f4784066616134333038396435643466366264383265346133623137306633353663613235386361396636336638386438336130383334353465653765393966633536861901021a00015282f4982018a018531418ce189d18fd1318300c18f218b618ef18b518d0189818a005188f18eb188618b218a4185b185f18d8184f18c11875187d188918d518a5f6f4";
        subscribers = LibBlob.decodeSubscribers(data);
        assertEq(subscribers[0].subscriber, "f410fsd3zx5xlfrhyoa3f46czqlq7capjhoighmzagaq");
        assertEq(
            subscribers[0].subscriptionGroup[0].subscriptionId,
            "57055e3ff34f3fa7001e9d9a73c4ea92ad5b8235dcec71b6059c7a552cf3bda0"
        );
        assertEq(
            subscribers[0].subscriptionGroup[1].subscriptionId,
            "faa43089d5d4f6bd82e4a3b170f356ca258ca9f63f88d83a083454ee7e99fc56"
        );

        // Two different subscribers
        data =
            hex"a2782c66343130667364337a7835786c667268796f6133663436637a716c71376361706a686f6967686d7a61676171a178406661613433303839643564346636626438326534613362313730663335366361323538636139663633663838643833613038333435346565376539396663353686190ea31a00016023f4982018a018531418ce189d18fd1318300c18f218b618ef18b518d0189818a005188f18eb188618b218a4185b185f18d8184f18c11875187d188918d518a5f6f4782c663431306674667376613769326b77366d65326b346c6335626e367a7833616d33626a673436367667376a69a178406164663637663836393937383035383834346135623066636135313562613031323364626161393730373462363062333033353166626165663364363636636686190ec91a00016049f4982018a018531418ce189d18fd1318300c18f218b618ef18b518d0189818a005188f18eb188618b218a4185b185f18d8184f18c11875187d188918d518a5f6f4";
        subscribers = LibBlob.decodeSubscribers(data);
        assertEq(subscribers[0].subscriber, "f410fsd3zx5xlfrhyoa3f46czqlq7capjhoighmzagaq");
        assertEq(subscribers[1].subscriber, "f410ftfsva7i2kw6me2k4lc5bn6zx3am3bjg466vg7ji");
    }

    function testDecodeSubscriptionGroup() public view {
        bytes memory data =
            hex"a1784066616134333038396435643466366264383265346133623137306633353663613235386361396636336638386438336130383334353465653765393966633536861901021a00015282f4982018a018531418ce189d18fd1318300c18f218b618ef18b518d0189818a005188f18eb188618b218a4185b185f18d8184f18c11875187d188918d518a5f6f4";
        SubscriptionGroup[] memory subscriptionGroup = LibBlob.decodeSubscriptionGroup(data);
        assertEq(
            subscriptionGroup[0].subscriptionId, "faa43089d5d4f6bd82e4a3b170f356ca258ca9f63f88d83a083454ee7e99fc56"
        );
        assertEq(subscriptionGroup[0].subscription.added, 258);
        assertEq(subscriptionGroup[0].subscription.expiry, 86658);
        assertEq(subscriptionGroup[0].subscription.autoRenew, false);
        assertEq(subscriptionGroup[0].subscription.source, "ubjrjtu57ujtadhsw3x3lueyuacy724gwksfwx6yj7axk7mj2wsq");
        assertEq(subscriptionGroup[0].subscription.delegate.origin, address(0));
        assertEq(subscriptionGroup[0].subscription.delegate.caller, address(0));
        assertEq(subscriptionGroup[0].subscription.failed, false);
    }

    function testDecodeSubscription() public view {
        // No delegate
        bytes memory data =
            hex"8619045e19126ef59820184e1871182818b3189318920f011876188d189a182318c5189b185c18910b18f418cc18961876183518b6187a185c0418a318a2185f18ac18af1825f6f4";
        Subscription memory subscription = LibBlob.decodeSubscription(data);
        assertEq(subscription.added, 1118);
        assertEq(subscription.expiry, 4718);
        assertEq(subscription.autoRenew, true);
        assertEq(subscription.source, "jzysrm4tsihqc5untir4lg24sef7jtewoy23m6s4asr2ex5mv4sq");
        assertEq(subscription.delegate.origin, address(0));
        assertEq(subscription.delegate.caller, address(0));
        assertEq(subscription.failed, false);

        // With delegate
        data =
            hex"86191a54192864f59820184e1871182818b3189318920f011876188d189a182318c5189b185c18910b18f418cc18961876183518b6187a185c0418a318a2185f18ac18af18258256040aa0ee7a142d267c1f36714e4a8f75612f20a7972056040a11c81c1a7979cdd309096d1ea53f887ea9f8d14df4";
        subscription = LibBlob.decodeSubscription(data);
        assertEq(subscription.added, 6740);
        assertEq(subscription.expiry, 10340);
        assertEq(subscription.autoRenew, true);
        assertEq(subscription.source, "jzysrm4tsihqc5untir4lg24sef7jtewoy23m6s4asr2ex5mv4sq");
        assertEq(subscription.delegate.origin, 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);
        assertEq(subscription.delegate.caller, 0x11c81c1A7979cdd309096D1ea53F887EA9f8D14d);
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

    function testDecodeBlobStatus() public view {
        bytes memory status = hex"685265736F6C766564"; // Resolved
        bytes memory decoded = LibWasm.decodeCborStringToBytes(status);
        BlobStatus decodedStatus = LibBlob.decodeBlobStatus(decoded);
        assertEq(uint256(decodedStatus), uint256(BlobStatus.Resolved));
    }

    function testDecodeTokenCreditRate() public view {
        bytes memory data = hex"a16472617465820184001ab34b9f101a7bc907151a00c097ce";
        uint256 rate = LibBlob.decodeTokenCreditRate(data);
        assertEq(rate, 1000000000000000000000000000000000000);
    }
}
