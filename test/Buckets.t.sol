// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {StdUtils} from "forge-std/StdUtils.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript as BucketsDeployer} from "../script/Buckets.s.sol";
import {Buckets} from "../src/Buckets.sol";
import {Kind, Machine, Query} from "../src/types/BucketTypes.sol";
import {Environment} from "../src/types/CommonTypes.sol";

// TODO: add integration tests once it's possible in CI
contract BucketsTest is Test, Buckets {
    Buckets internal buckets;

    function setUp() public virtual {
        BucketsDeployer bucketsDeployer = new BucketsDeployer();
        buckets = bucketsDeployer.run(Environment.Foundry);
    }

    function testDecodeQuery() public view {
        // Empty objects, empty common prefixes
        Query memory query = decodeQuery(hex"828080");
        assertEq(query.objects.length, 0);
        assertEq(query.commonPrefixes.length, 0);

        // Empty objects, 1 common prefixes
        query = decodeQuery(hex"8280818618681865186c186c186f182f");
        assertEq(query.objects.length, 0);
        assertEq(query.commonPrefixes[0], "hello/");

        // Empty objects, 2 common prefixes
        query = decodeQuery(hex"8280828618681865186c186c186f182f8718681865186c186c186f1832182f");
        assertEq(query.objects.length, 0);
        assertEq(query.commonPrefixes[0], "hello/");
        assertEq(query.commonPrefixes[1], "hello2/");

        // 1 object (with metadata), no common prefixes
        query = decodeQuery(
            hex"8281828b18681865186c186c186f182f1877186f1872186c1864849820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a1899061a00018ba5a163666f6f6362617280"
        );
        assertEq(query.objects[0].key, "hello/world");
        assertEq(query.objects[0].value.hash, "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq");
        assertEq(query.objects[0].value.size, 6);
        assertEq(query.objects[0].value.expiry, 101285);
        assertEq(query.objects[0].value.metadata[0].key, "foo");
        assertEq(query.objects[0].value.metadata[0].value, "bar");
        assertEq(query.commonPrefixes.length, 0);

        // 2 objects, 1 common prefixes
        query = decodeQuery(
            hex"8282828b18681865186c186c186f182f1877186f1872186c1864849820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a1899061a00018596a0828a18681865186c186c186f182f187418651873187484982018b618e1100c185318b918c518f218881878185e18811854187e183b18da18a60e186c182d182518f218b8185418ad184c186518bc186a183118af18b30c1a00018644a0818c18681865186c186c186f182f1877186f1872186c1864182f"
        );
        assertEq(query.objects[0].key, "hello/world");
        assertEq(query.objects[0].value.hash, "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq");
        assertEq(query.objects[0].value.size, 6);
        assertEq(query.objects[0].value.expiry, 99734);
        assertEq(query.objects[0].value.metadata.length, 0);
        assertEq(query.objects[1].key, "hello/test");
        assertEq(query.objects[1].value.hash, "w3qradctxhc7fcdyl2avi7r33kta43bnexzlqvfnjrs3y2rrv6zq");
        assertEq(query.objects[1].value.size, 12);
        assertEq(query.objects[1].value.expiry, 99908);
        assertEq(query.objects[1].value.metadata.length, 0);
        assertEq(query.commonPrefixes[0], "hello/world/");

        // 2 objects with "deleted" (null) value, no common prefixes
        query = decodeQuery(
            hex"8282828b18681865186c186c186f182f1877186f1872186c1864f6828a18681865186c186c186f182f1874186518731874f680"
        );
        assertEq(query.objects[0].key, "hello/world");
        assertEq(query.objects[0].value.hash, "");
        assertEq(query.objects[1].key, "hello/test");
        assertEq(query.objects[1].value.hash, "");
        assertEq(query.commonPrefixes.length, 0);
    }

    function testDecodeList() public view {
        // Empty list (no buckets)
        Machine[] memory machines = decodeList(hex"80");
        assertEq(machines.length, 0);

        // 1 bucket
        machines = decodeList(hex"81836b4f626a65637453746f72655502770d21925703390a236f68f84ef1d432ca5742c4a0");
        assertEq(machines.length, 1);
        assertEq(uint8(machines[0].kind), uint8(Kind.ObjectStore));
        assertEq(machines[0].addr, "t2o4gsdesxam4qui3pnd4e54ouglffoqwecfnrdzq");
        assertEq(machines[0].metadata.length, 0);

        // Multiple buckets
        machines = decodeList(
            hex"83836b4f626a65637453746f72655502770d21925703390a236f68f84ef1d432ca5742c4a0836b4f626a65637453746f726555024722ebdc6ff1cd1c5e01b1484f4ff4cc551f2f19a0836b4f626a65637453746f72655502c7e35ef76825a8f25fbb121fa5795c4cae6042d9a0"
        );
        assertEq(machines.length, 3);
        assertEq(uint8(machines[0].kind), uint8(Kind.ObjectStore));
        assertEq(machines[0].addr, "t2o4gsdesxam4qui3pnd4e54ouglffoqwecfnrdzq");
        assertEq(machines[0].metadata.length, 0);
        assertEq(uint8(machines[1].kind), uint8(Kind.ObjectStore));
        assertEq(machines[1].addr, "t2i4roxxdp6hgryxqbwfee6t7uzrkr6lyz257le7a");
        assertEq(machines[1].metadata.length, 0);
        assertEq(uint8(machines[2].kind), uint8(Kind.ObjectStore));
        assertEq(machines[2].addr, "t2y7rv553iewupex53cip2k6k4jsxgaqwznyz7dna");
        assertEq(machines[2].metadata.length, 0);
    }
}
