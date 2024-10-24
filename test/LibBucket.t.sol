// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {Kind, Machine, Query} from "../src/types/BucketTypes.sol";
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
            hex"8281828b18681865186c186c186f182f1877186f1872186c1864849820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a1899061910a4a263666f6f636261726c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616d80"
        );
        assertEq(query.objects[0].key, "hello/world");
        assertEq(query.objects[0].value.hash, "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq");
        assertEq(query.objects[0].value.size, 6);
        assertEq(query.objects[0].value.expiry, 4260);
        assertEq(query.objects[0].value.metadata[0].key, "foo");
        assertEq(query.objects[0].value.metadata[0].value, "bar");
        assertEq(query.objects[0].value.metadata[1].key, "content-type");
        assertEq(query.objects[0].value.metadata[1].value, "application/octet-stream");
        assertEq(query.commonPrefixes.length, 0);

        // 2 objects, 1 common prefixes
        query = LibBucket.decodeQuery(
            hex"8282828b18681865186c186c186f182f1877186f1872186c1864849820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a189906191379a16c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616d828a18681865186c186c186f182f187418651873187484982018b618e1100c185318b918c518f218881878185e18811854187e183b18da18a60e186c182d182518f218b8185418ad184c186518bc186a183118af18b30c191536a16c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616d818c18681865186c186c186f182f1877186f1872186c1864182f"
        );
        assertEq(query.objects[0].key, "hello/world");
        assertEq(query.objects[0].value.hash, "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq");
        assertEq(query.objects[0].value.size, 6);
        assertEq(query.objects[0].value.expiry, 4985);
        assertEq(query.objects[0].value.metadata.length, 1); // Always has `content-type` metadata
        assertEq(query.objects[1].key, "hello/test");
        assertEq(query.objects[1].value.hash, "w3qradctxhc7fcdyl2avi7r33kta43bnexzlqvfnjrs3y2rrv6zq");
        assertEq(query.objects[1].value.size, 12);
        assertEq(query.objects[1].value.expiry, 5430);
        assertEq(query.objects[1].value.metadata.length, 1);
        assertEq(query.commonPrefixes[0], "hello/world/");
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

    function testEncodeAddParams() public pure {
        KeyValue[] memory metadata = new KeyValue[](1);
        metadata[0] = KeyValue({key: "content-type", value: "application/octet-stream"});
        AddParams memory params = AddParams({
            source: "4wx2ocgzy2p42egwp5cwiyjhwzz6wt4elwwrrgoujx7ady5oxm7a",
            key: "hello/world",
            blobHash: "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq",
            size: 6,
            ttl: 0, // Null value
            metadata: metadata,
            overwrite: false
        });
        bytes memory encoded = LibBucket.encodeAddParams(params);
        assertEq(
            encoded,
            hex"87982018e518af18a70818d918c6189f18cd1018d6187f184518641861182718b6187318eb184f1884185d18ad1818189918d4184d18fe0118e318ae18bb183e4b68656c6c6f2f776f726c649820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a189906f6a16c636f6e74656e742d7479706578186170706c69636174696f6e2f6f637465742d73747265616df4"
        );
    }
}
