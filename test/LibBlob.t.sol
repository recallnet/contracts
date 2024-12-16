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
    Subscription
} from "../src/types/BlobTypes.sol";
import {LibBlob} from "../src/wrappers/LibBlob.sol";
import {LibWasm} from "../src/wrappers/LibWasm.sol";

contract LibBlobTest is Test {
    using LibBlob for bytes;

    function testDecodeSubnetStats() public view {
        bytes memory data =
            hex"8d4b000a969d255e0cca0800008201821a4876e7fa17820181068201831aca0800001a9d255e0c190a968201811954608201811a000158b8010a0100000000";
        SubnetStats memory stats = data.decodeSubnetStats();
        assertEq(stats.balance, 50002000000000000000000);
        assertEq(stats.capacityFree, 99999999994);
        assertEq(stats.capacityUsed, 6);
        assertEq(stats.creditSold, 50002000000000000000000);
        assertEq(stats.creditCommitted, 21600);
        assertEq(stats.creditDebited, 88248);
        assertEq(stats.blobCreditsPerByteBlock, 1);
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
        Subscriber[] memory subscribers = LibBlob.decodeSubscribers(data);
        assertEq(subscribers[0].subscriber, 0x90F79bf6EB2c4f870365E785982E1f101E93b906);
        assertEq(subscribers[0].subscriptionGroup[0].subscriptionId, "Default");
        assertEq(subscribers[0].subscriptionGroup[0].subscription.added, 977);
        assertEq(subscribers[0].subscriptionGroup[0].subscription.expiry, 11148);
        assertEq(subscribers[0].subscriptionGroup[0].subscription.autoRenew, true);
        assertEq(
            subscribers[0].subscriptionGroup[0].subscription.source,
            "dj46xqiflbnyljn2uv5nbmjb7twj3g2u5mgo72xxtyhwmvarlcxa"
        );
        assertEq(subscribers[0].subscriptionGroup[0].subscription.delegate.origin, address(0));
        assertEq(subscribers[0].subscriptionGroup[0].subscription.delegate.caller, address(0));
        assertEq(subscribers[0].subscriptionGroup[0].subscription.failed, false);

        // Two subscribers
        data =
            hex"a256040a90f79bf6eb2c4f870365e785982e1f101e93b906a26744656661756c74861903d1192b8cf59820181a187918eb18c1051858185b188518a518ba18a5187a18d018b1182118fc18ec189d189b185418eb0c18ef18ea18f7189e0f1866185411185818aef6f4a1634b6579982018a118a7182203183b184c184d18b0186e18c918c018a718e01899186f1821184d18a4189b187318f318df18c0187618e61518d002182918d4184118d086190f77192b98f59820181a187918eb18c1051858185b188518a518ba18a5187a18d018b1182118fc18ec189d189b185418eb0c18ef18ea18f7189e0f1866185411185818aef6f456040a976ea74026e726554db657fa54763abd0c3a0aa9a16744656661756c7486191d9c192bacf59820181a187918eb18c1051858185b188518a518ba18a5187a18d018b1182118fc18ec189d189b185418eb0c18ef18ea18f7189e0f1866185411185818aef6f4";
        subscribers = LibBlob.decodeSubscribers(data);
        assertEq(subscribers[0].subscriber, 0x90F79bf6EB2c4f870365E785982E1f101E93b906);
        assertEq(subscribers[0].subscriptionGroup[0].subscriptionId, "Default");
        assertEq(subscribers[1].subscriber, 0x976EA74026E726554dB657fA54763abd0C3a0aa9);
        assertEq(subscribers[1].subscriptionGroup[0].subscriptionId, "Default");
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
            hex"8182982018a1189d18c605187b1818188c18bd186718ea1839186618fd188d182c18a2188318f4185a187718d9185c182d18a51861189318ca189818d0187b183c18a7818356040a90f79bf6eb2c4f870365e785982e1f101e93b906a1634b657998201837182f183318e505188d18d7081870184d18d718de18180c185e183318f51857189a18c518b1187518781845184418b718a7183f182b189c18b018be9820181a187918eb18c1051858185b188518a518ba18a5187a18d018b1182118fc18ec189d189b185418eb0c18ef18ea18f7189e0f1866185411185818ae";
        BlobTuple[] memory blobs = LibBlob.decodeAddedOrPendingBlobs(data);
        assertEq(blobs[0].blobHash, "ugo4mbl3dcgl2z7khftp3djmukb7iwtx3foc3jlbspfjrud3hstq");
        assertEq(blobs[0].sourceInfo[0].subscriber, 0x90F79bf6EB2c4f870365E785982E1f101E93b906);
        assertEq(
            bytes(blobs[0].sourceInfo[0].subscriptionId),
            hex"372f33e5058dd708704dd7de180c5e33f5579ac5b175784544b7a73f2b9cb0be"
        );
        assertEq(blobs[0].sourceInfo[0].source, "dj46xqiflbnyljn2uv5nbmjb7twj3g2u5mgo72xxtyhwmvarlcxa");

        // Two different blobs, one of which has multiple subscribers
        data =
            hex"828298201618e218f118210318a518b7183d18a818a3186f187618b318b018f01897182318e9051718501879186a18bd183a1118561895186d182c18901896818356040acafeb0ba00000000000000000000000000000000a1634b65798618681865186c186c186f18329820181a181e182118dc18db1874185e18e118c318331018521850189a183d18ce1618b8181e18b2184e1718c518f718bf185618b418df1838184b18a9187d8298201835182918be18d018931887186d185b183718e618a90b18c518a4182918201841187a18f1185e182d188e15186a0418f31838181818e318fc185618ce828356040acafeb0ba00000000000000000000000000000000a1634b65798518681865186c186c186f982018b3188f18be18aa1847041837189218ab186a18c51881183118a3184f18a2183d18441820185818fa18780918471867189a18de1818182a183018d518338356040acafeb0ba000000000000000000000000000000006744656661756c7498201846185a185418ed18bd18b817021823186e18d918e018e218511888187518f2031845182918e11829186e188618271853188718650c188e18bb18b2";
        blobs = LibBlob.decodeAddedOrPendingBlobs(data);
        assertEq(blobs[0].blobHash, "c3rpciiduw3t3kfdn53lhmhqs4r6sbixkb4wvpj2cfljk3jmscla");
        assertEq(blobs[0].sourceInfo[0].subscriber, 0xCafeB0ba00000000000000000000000000000000);
        assertEq(bytes(blobs[0].sourceInfo[0].subscriptionId), bytes("hello2"));
        assertEq(blobs[0].sourceInfo[0].source, "dipcdxg3orpodqztcbjfbgr5zyllqhvsjyl4l557k22n6oclvf6q");

        assertEq(blobs[1].blobHash, "guu35uetq5wvwn7gvef4ljbjebaxv4k6fwhbk2qe6m4bry74k3ha");
        assertEq(blobs[1].sourceInfo[0].subscriber, 0xCafeB0ba00000000000000000000000000000000);
        assertEq(bytes(blobs[1].sourceInfo[0].subscriptionId), bytes("hello"));
        assertEq(blobs[1].sourceInfo[0].source, "woh35kshaq3zfk3kywatdi2pui6uiicy7j4asr3htlpbqkrq2uzq");

        assertEq(blobs[1].blobHash, "guu35uetq5wvwn7gvef4ljbjebaxv4k6fwhbk2qe6m4bry74k3ha");
        assertEq(blobs[1].sourceInfo[1].subscriber, 0xCafeB0ba00000000000000000000000000000000);
        assertEq(bytes(blobs[1].sourceInfo[1].subscriptionId), bytes("Default"));
        assertEq(blobs[1].sourceInfo[1].source, "iznfj3n5xalqei3o3hqoeumioxzagrjj4euw5brhkodwkdeoxoza");
    }

    function testDecodeBlobStatus() public view {
        bytes memory status = hex"685265736F6C766564"; // Resolved
        bytes memory decoded = LibWasm.decodeCborStringToBytes(status);
        BlobStatus decodedStatus = LibBlob.decodeBlobStatus(decoded);
        assertEq(uint256(decodedStatus), uint256(BlobStatus.Resolved));
    }
}
