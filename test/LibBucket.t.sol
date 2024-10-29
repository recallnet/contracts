// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {Kind, Machine, Query, Value} from "../src/types/BucketTypes.sol";
import {AddParams, KeyValue, LibBucket} from "../src/util/LibBucket.sol";

contract LibBucketTest is Test {
    function testDecodeQuery() public view {
        // Empty objects, empty common prefixes
        Query memory query = LibBucket.decodeQuery(hex"828080");
        assertEq(query.objects.length, 0);
        assertEq(query.commonPrefixes.length, 0);

        // Empty objects, 1 common prefixes
        query = LibBucket.decodeQuery(hex"8280818618681865186c186c186f182f");
        assertEq(query.objects.length, 0);
        assertEq(query.commonPrefixes[0], "hello/");

        // Empty objects, 2 common prefixes
        query = LibBucket.decodeQuery(hex"8280828618681865186c186c186f182f8718681865186c186c186f1832182f");
        assertEq(query.objects.length, 0);
        assertEq(query.commonPrefixes[0], "hello/");
        assertEq(query.commonPrefixes[1], "hello2/");

        // 1 object (with custom metadata), no common prefixes
        query = LibBucket.decodeQuery(
            hex"8281828b18681865186c186c186f182f1877186f1872186c1864859820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a1899982018a418d0050618e00118bf1841189e18511845183c1836187b18821834187e1518731820183a18281830011618a218bd1218d7189b188e18e3061a00018236a263666f6f636261726c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616d80"
        );
        assertEq(query.objects[0].key, "hello/world");
        assertEq(query.objects[0].value.blobHash, "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq");
        assertEq(query.objects[0].value.recoveryHash, "utiakbxaag7udhsriu6dm64cgr7bk4zahiudaaiwuk6rfv43r3rq");
        assertEq(query.objects[0].value.size, 6);
        assertEq(query.objects[0].value.expiry, 98870);
        assertEq(query.objects[0].value.metadata[0].key, "foo");
        assertEq(query.objects[0].value.metadata[0].value, "bar");
        assertEq(query.objects[0].value.metadata[1].key, "content-type");
        assertEq(query.objects[0].value.metadata[1].value, "application/octet-stream");
        assertEq(query.commonPrefixes.length, 0);

        // 2 objects, 1 common prefixes
        query = LibBucket.decodeQuery(
            hex"8282828b18681865186c186c186f182f1877186f1872186c1864859820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a18999820185818300918d918fc011819188d18b0150818dc186b18c918e618f10a185c18ef189118a3185d1864186d187318a518b718a8181918cd18b0184d061a00018933a16c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616d828a18681865186c186c186f182f187418651873187485982018b618e1100c185318b918c518f218881878185e18811854187e183b18da18a60e186c182d182518f218b8185418ad184c186518bc186a183118af18b3982018d518a5182a187a185d185618501868186d188818f518f81899183018c518a6183218b2188f187b18d018e118bb18411618a4183f185018d21853182f18e20c1a0001891ea16c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616d818c18681865186c186c186f182f1877186f1872186c1864182f"
        );
        assertEq(query.objects[0].key, "hello/world");
        assertEq(query.objects[0].value.blobHash, "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq");
        assertEq(query.objects[0].value.recoveryHash, "layatwp4aemy3mavbdogxspg6effz34runowi3ltuw32qgonwbgq");
        assertEq(query.objects[0].value.size, 6);
        assertEq(query.objects[0].value.expiry, 100659);
        assertEq(query.objects[0].value.metadata.length, 1); // Always has `content-type` metadata
        assertEq(query.objects[1].key, "hello/test");
        assertEq(query.objects[1].value.blobHash, "w3qradctxhc7fcdyl2avi7r33kta43bnexzlqvfnjrs3y2rrv6zq");
        assertEq(query.objects[1].value.recoveryHash, "2wssu6s5kzigq3mi6x4jsmgfuyzlfd332dq3wqiwuq7vbustf7ra");
        assertEq(query.objects[1].value.size, 12);
        assertEq(query.objects[1].value.expiry, 100638);
        assertEq(query.objects[1].value.metadata.length, 1);
        assertEq(query.commonPrefixes[0], "hello/world/");

        // Deleted 1 object, but another object that shares the same key still "exists" with empty data
        query = LibBucket.decodeQuery(hex"8281828b18681865186c186c186f182f1877186f1872186c1864f680");
        assertEq(query.objects.length, 1);
        assertEq(query.objects[0].key, "hello/world");
        assertEq(query.objects[0].value.blobHash, "");
        assertEq(query.objects[0].value.recoveryHash, "");
        assertEq(query.objects[0].value.size, 0);
        assertEq(query.objects[0].value.expiry, 0);
        assertEq(query.objects[0].value.metadata.length, 0);
    }

    function testDecodeList() public view {
        // Empty list (no buckets)
        Machine[] memory machines = LibBucket.decodeList(hex"80");
        assertEq(machines.length, 0);

        // 1 bucket
        machines = LibBucket.decodeList(hex"8183664275636b657455023f08642392fbffeb74b4b1bd28c4856a40d3aaf4a0");
        assertEq(machines.length, 1);
        assertEq(uint8(machines[0].kind), uint8(Kind.Bucket));
        assertEq(machines[0].addr, "t2h4egii4s7p76w5fuwg6srrefnjanhkxuxiew6ha");
        assertEq(machines[0].metadata.length, 0);

        // Multiple buckets (with metadata)
        machines = LibBucket.decodeList(
            hex"8383664275636b657455023f08642392fbffeb74b4b1bd28c4856a40d3aaf4a083664275636b65745502d89df1ae884b2d9d4dee800675fa005b78a138a9a083664275636b65745502770d21925703390a236f68f84ef1d432ca5742c4a163666f6f63626172"
        );
        assertEq(machines.length, 3);
        assertEq(uint8(machines[0].kind), uint8(Kind.Bucket));
        assertEq(machines[0].addr, "t2h4egii4s7p76w5fuwg6srrefnjanhkxuxiew6ha");
        assertEq(machines[0].metadata.length, 0);
        assertEq(uint8(machines[1].kind), uint8(Kind.Bucket));
        assertEq(machines[1].addr, "t23co7dluijmwz2tpoqadhl6qaln4kcofjcp24uby");
        assertEq(machines[1].metadata.length, 0);
        assertEq(uint8(machines[2].kind), uint8(Kind.Bucket));
        assertEq(machines[2].addr, "t2o4gsdesxam4qui3pnd4e54ouglffoqwecfnrdzq");
        assertEq(machines[2].metadata[0].key, "foo");
        assertEq(machines[2].metadata[0].value, "bar");
    }

    function testDecodeValue() public view {
        Value memory value = LibBucket.decodeValue(
            hex"859820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a1899982018a418d0050618e00118bf1841189e18511845183c1836187b18821834187e1518731820183a18281830011618a218bd1218d7189b188e18e3061a00018236a263666f6f636261726c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616d"
        );
        assertEq(value.blobHash, "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq");
        assertEq(value.recoveryHash, "utiakbxaag7udhsriu6dm64cgr7bk4zahiudaaiwuk6rfv43r3rq");
        assertEq(value.size, 6);
        assertEq(value.expiry, 98870);
        assertEq(value.metadata[0].key, "foo");
        assertEq(value.metadata[0].value, "bar");
        assertEq(value.metadata[1].key, "content-type");
        assertEq(value.metadata[1].value, "application/octet-stream");
    }

    function testEncodeAddParams() public pure {
        KeyValue[] memory metadata = new KeyValue[](1);
        metadata[0] = KeyValue({key: "content-type", value: "application/octet-stream"});
        AddParams memory params = AddParams({
            source: "cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq",
            key: "hello/world",
            blobHash: "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq",
            // TODO: update this once the dummy value is replaced with a blake3 hash; it's hardcoded as `[32; 0]`
            recoveryHash: "",
            size: 6,
            ttl: 0, // Null value
            metadata: metadata,
            overwrite: false
        });
        bytes memory encoded = LibBucket.encodeAddParams(params);
        assertEq(
            encoded,
            hex"889820160618a818c918670a18791827184118ef18c818bd18ea1879187918b518cc189b18181827181a18ee18cc100718c418f308189f18dd188418d34b68656c6c6f2f776f726c649820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a18999820000000000000000000000000000000000000000000000000000000000000000006f6a16c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616df4"
        );
    }
}
