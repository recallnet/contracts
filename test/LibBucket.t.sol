// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {CreateBucketParams, Kind, Machine, ObjectState, ObjectValue, Query} from "../src/types/BucketTypes.sol";
import {AddObjectParams, KeyValue, LibBucket} from "../src/wrappers/LibBucket.sol";

contract LibBucketTest is Test {
    function testEncodeQueryParams() public pure {
        // All default values
        string memory prefix = "";
        string memory delimiter = "/";
        string memory startKey = "";
        uint64 limit = 0;
        bytes memory encoded = LibBucket.encodeQueryParams(prefix, delimiter, startKey, limit);
        assertEq(encoded, hex"8440412ff600");

        // With a prefix
        prefix = "hello/";
        encoded = LibBucket.encodeQueryParams(prefix, delimiter, startKey, limit);
        assertEq(encoded, hex"844668656c6c6f2f412ff600");

        // With a start key
        prefix = "";
        startKey = "hello/world";
        encoded = LibBucket.encodeQueryParams(prefix, delimiter, startKey, limit);
        assertEq(encoded, hex"8440412f8b18681865186c186c186f182f1877186f1872186c186400");
    }

    // Note: this is the underlying decoding in `queryObjects`
    function testDecodeQuery() public view {
        // Empty objects, empty common prefixes, null next key
        Query memory query = LibBucket.decodeQuery(hex"838080f6");
        assertEq(query.objects.length, 0);
        assertEq(query.commonPrefixes.length, 0);
        assertEq(query.nextKey, "");

        // Empty objects, 1 common prefixes, null next key
        query = LibBucket.decodeQuery(hex"8380818618681865186c186c186f182ff6");
        assertEq(query.objects.length, 0);
        assertEq(query.commonPrefixes[0], "hello/");
        assertEq(query.nextKey, "");

        // Empty objects, 2 common prefixes, null next key
        query = LibBucket.decodeQuery(hex"8380828618681865186c186c186f182f8718681865186c186c186f1832182ff6");
        assertEq(query.objects.length, 0);
        assertEq(query.commonPrefixes[0], "hello/");
        assertEq(query.commonPrefixes[1], "hello2/");
        assertEq(query.nextKey, "");

        // 1 object (with custom metadata), no common prefixes nor next key
        query = LibBucket.decodeQuery(
            hex"8381828b18681865186c186c186f182f1877186f1872186c1864a364686173689820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a18996473697a6506686d65746164617461a263666f6f636261726c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616d80f6"
        );
        assertEq(query.objects[0].key, "hello/world");
        assertEq(query.objects[0].state.blobHash, "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq");
        assertEq(query.objects[0].state.size, 6);
        assertEq(query.objects[0].state.metadata[0].key, "foo");
        assertEq(query.objects[0].state.metadata[0].value, "bar");
        assertEq(query.objects[0].state.metadata[1].key, "content-type");
        assertEq(query.objects[0].state.metadata[1].value, "application/octet-stream");
        assertEq(query.commonPrefixes.length, 0);
        assertEq(query.nextKey, "");

        // 2 objects, 1 common prefixes, null next key
        query = LibBucket.decodeQuery(
            hex"8382828b18681865186c186c186f182f1877186f1872186c1864a364686173689820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a18996473697a6506686d65746164617461a16c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616d828a18681865186c186c186f182f1874186518731874a36468617368982018b618e1100c185318b918c518f218881878185e18811854187e183b18da18a60e186c182d182518f218b8185418ad184c186518bc186a183118af18b36473697a650c686d65746164617461a16c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616d818c18681865186c186c186f182f1877186f1872186c1864182ff6"
        );
        assertEq(query.objects[0].key, "hello/world");
        assertEq(query.objects[0].state.blobHash, "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq");
        assertEq(query.objects[0].state.size, 6);
        assertEq(query.objects[0].state.metadata.length, 1); // Always has `content-type` metadata
        assertEq(query.objects[1].key, "hello/test");
        assertEq(query.objects[1].state.blobHash, "w3qradctxhc7fcdyl2avi7r33kta43bnexzlqvfnjrs3y2rrv6zq");
        assertEq(query.objects[1].state.size, 12);
        assertEq(query.objects[1].state.metadata.length, 1);
        assertEq(query.commonPrefixes[0], "hello/world/");
        assertEq(query.nextKey, "");

        // Query with `hello/test/` as next key; 1 object, 1 common prefix, null next key
        query = LibBucket.decodeQuery(
            hex"8381828a18681865186c186c186f182f1874186518731874a36468617368982018b618e1100c185318b918c518f218881878185e18811854187e183b18da18a60e186c182d182518f218b8185418ad184c186518bc186a183118af18b36473697a650c686d65746164617461a16c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616d818c18681865186c186c186f182f1877186f1872186c1864182ff6"
        );
        assertEq(query.objects[0].key, "hello/test");
        assertEq(query.objects[0].state.blobHash, "w3qradctxhc7fcdyl2avi7r33kta43bnexzlqvfnjrs3y2rrv6zq");
        assertEq(query.objects[0].state.size, 12);
        assertEq(query.objects[0].state.metadata.length, 1);
        assertEq(query.commonPrefixes[0], "hello/world/");
        assertEq(query.nextKey, "");
    }

    // Note: this is the underlying decoding in `getObject`
    function testDecodeObjectValue() public view {
        bytes memory data =
            hex"859820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a18999820184a18d5189d1883189718f91849185318ce18ab1618d2182d18c618e718b1187018ae03187a185b188518c6189a186c18af18fc18ff18c918e318ac0306197260a263666f6f636261726c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616d";
        ObjectValue memory value = LibBucket.decodeObjectValue(data);
        assertEq(value.blobHash, "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq");
        assertEq(value.recoveryHash, "jlkz3a4x7fevhtvlc3jc3rxhwfyk4a32loc4ngtmv76p7spdvqbq");
        assertEq(value.size, 6);
        assertEq(value.expiry, 29280);
        assertEq(value.metadata[0].key, "foo");
        assertEq(value.metadata[0].value, "bar");
        assertEq(value.metadata[1].key, "content-type");
        assertEq(value.metadata[1].value, "application/octet-stream");
    }

    function testDecodeList() public view {
        // Empty list (no buckets)
        Machine[] memory machines = LibBucket.decodeList(hex"80");
        assertEq(machines.length, 0);

        // 1 bucket
        machines = LibBucket.decodeList(hex"8183664275636b65744300ed01a0");
        assertEq(machines.length, 1);
        assertEq(uint8(machines[0].kind), uint8(Kind.Bucket));
        assertEq(machines[0].addr, 0xFf000000000000000000000000000000000000ed);
        assertEq(machines[0].metadata.length, 0);

        // Multiple buckets (with metadata)
        machines = LibBucket.decodeList(
            hex"8383664275636b65744300ed01a083664275636b65744300ee01a083664275636b65744300ef01a165616c69617363666f6f"
        );
        assertEq(machines.length, 3);
        assertEq(uint8(machines[0].kind), uint8(Kind.Bucket));
        assertEq(machines[0].addr, 0xFf000000000000000000000000000000000000ed);
        assertEq(machines[0].metadata.length, 0);
        assertEq(uint8(machines[1].kind), uint8(Kind.Bucket));
        assertEq(machines[1].addr, 0xFF000000000000000000000000000000000000EE);
        assertEq(machines[1].metadata.length, 0);
        assertEq(uint8(machines[2].kind), uint8(Kind.Bucket));
        assertEq(machines[2].addr, 0xFf000000000000000000000000000000000000Ef);
        assertEq(machines[2].metadata[0].key, "alias");
        assertEq(machines[2].metadata[0].value, "foo");
    }

    function testEncodeAddObjectParams() public pure {
        KeyValue[] memory metadata = new KeyValue[](1);
        metadata[0] = KeyValue({key: "content-type", value: "application/octet-stream"});
        AddObjectParams memory params = AddObjectParams({
            source: "cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq",
            key: "hello/world",
            blobHash: "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq",
            // TODO: update this once the dummy value is replaced with a blake3 hash; it's hardcoded as `[32; 0]`
            recoveryHash: "",
            size: 6,
            ttl: 0, // Null value
            metadata: metadata,
            overwrite: false,
            from: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
        });
        bytes memory encoded = LibBucket.encodeAddObjectParams(params);
        assertEq(
            encoded,
            hex"899820160618a818c918670a18791827184118ef18c818bd18ea1879187918b518cc189b18181827181a18ee18cc100718c418f308189f18dd188418d34b68656c6c6f2f776f726c649820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a18999820000000000000000000000000000000000000000000000000000000000000000006f6a16c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616df456040a90f79bf6eb2c4f870365e785982e1f101e93b906"
        );
    }

    function testEncodeCreateBucketParams() public pure {
        CreateBucketParams memory params = CreateBucketParams({
            owner: 0x90F79bf6EB2c4f870365E785982E1f101E93b906,
            kind: Kind.Bucket,
            metadata: new KeyValue[](0)
        });
        bytes memory encoded = LibBucket.encodeCreateBucketParams(params);
        assertEq(encoded, hex"8356040a90f79bf6eb2c4f870365e785982e1f101e93b906664275636b6574a0");
    }

    function testEncodeDeleteObjectParams() public pure {
        bytes memory encoded =
            LibBucket.encodeDeleteObjectParams("hello/world", 0x90F79bf6EB2c4f870365E785982E1f101E93b906);
        assertEq(encoded, hex"824b68656c6c6f2f776f726c6456040a90f79bf6eb2c4f870365e785982e1f101e93b906");
    }

    function testEncodeUpdateObjectMetadataParams() public pure {
        KeyValue[] memory metadata = new KeyValue[](1);
        metadata[0] = KeyValue("alias", "foo");
        bytes memory encoded = LibBucket.encodeUpdateObjectMetadataParams(
            "hello/world", metadata, 0x90F79bf6EB2c4f870365E785982E1f101E93b906
        );
        assertEq(
            encoded, hex"834b68656c6c6f2f776f726c64a165616c69617363666f6f56040a90f79bf6eb2c4f870365e785982e1f101e93b906"
        );
    }
}
