// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Actor} from "@filecoin-solidity/v0.8/utils/Actor.sol";
import {FilAddresses} from "@filecoin-solidity/v0.8/utils/FilAddresses.sol";
import {CommonTypes} from "@filecoin-solidity/v0.8/types/CommonTypes.sol";
import {FilecoinCBOR} from "@filecoin-solidity/v0.8/cbor/FilecoinCBOR.sol";
import {CBORDecoding} from "./util/CBORDecoding.sol";
import {ByteParser} from "./util/ByteParser.sol";

import "forge-std/console.sol";

type BigInt is uint256;

enum BlobStatus {
    Pending,
    Resolved,
    Failed
}

type ChainEpoch is int64;

type Hash is bytes32;

struct TokenAmount {
    BigInt atto;
}

struct RevokeCreditParams {
    address receiver;
    address requiredCaller;
}

struct AddBlobParams {
    address sponsor;
    string source;
    Hash hash;
    uint64 size;
    ChainEpoch ttl;
}

struct DeleteBlobParams {
    address sponsor;
    Hash hash;
}

struct ApproveCreditParams {
    address receiver;
    address requiredCaller;
    BigInt limit;
    ChainEpoch ttl;
}

struct FinalizeBlobParams {
    address subscriber;
    Hash hash;
    BlobStatus status;
}

struct GetBlobStatusParams {
    address subscriber;
    Hash hash;
}

struct GetStatsReturn {
    TokenAmount balance;
    uint64 capacityFree;
    uint64 capacityUsed;
    uint256 creditSold;
    uint256 creditCommitted;
    uint256 creditDebited;
    uint64 creditDebitRate;
    uint64 numAccounts;
    uint64 numBlobs;
    uint64 numResolving;
}

struct AccountReturn {
    uint64 capacityUsed;
    uint64 capacityFree;
    uint256 creditCommitted;
    ChainEpoch lastDebitEpoch;
}

contract Credits is CBORDecoding, ByteParser {
    CommonTypes.FilActorId internal _actorId = CommonTypes.FilActorId.wrap(49);
    uint64 internal constant EMPTY_CODEC = 0x00;
    uint64 internal constant CBOR_CODEC = 0x51;

    constructor() {}

    function trimPrefix(bytes memory data) public pure returns (bytes32) {
        bytes memory result = new bytes(32);
        uint256 pos = result.length - 1;
        for (uint256 i = 0; i < (result.length - data.length - 2); i++) {
            result[i] = 0;
        }
        for (uint256 i = 2; i < data.length; i++) {
            result[pos] = data[i];
            pos--;
        }
        return bytes32(result);
    }

    function parseU256(bytes memory data) public pure returns (uint256) {
        return uint256(trimPrefix(data));
    }

    function decodeStats(bytes memory data) external returns (GetStatsReturn memory) {
        bytes[] memory decoded = decodeArray(data);
        // 0: string, 1: balance, 2: capacityFree, 3: capacityUsed, 4: creditSold, 5: creditCommitted, 6: creditDebited, 7: creditDebitRate, 8: numAccounts, 9: numBlobs, 10: numResolving
        TokenAmount memory balance;
        //   bytes[] memory decodedBalance = decodeArray(decoded[0]);
        // 0: atto
        //   balance.atto = BigInt.wrap(bytesToBigNumber(decodedBalance[0]));
        GetStatsReturn memory stats;
        stats.balance = balance;
        stats.capacityFree = bytesToUint64(decoded[1]);
        stats.capacityUsed = bytesToUint64(decoded[2]);
        stats.creditSold = parseU256(decoded[3]);
        stats.creditCommitted = parseU256(decoded[4]);
        stats.creditDebited = parseU256(decoded[5]);
        stats.creditDebitRate = bytesToUint64(decoded[6]);
        stats.numAccounts = bytesToUint64(decoded[7]);
        stats.numBlobs = bytesToUint64(decoded[8]);
        stats.numResolving = bytesToUint64(decoded[9]);
        return stats;
    }

    function getStats() external returns (bytes memory) {
        bytes memory raw_request = new bytes(0);
        (int256 exit, bytes memory data) = Actor.callByIDReadOnly(_actorId, uint64(188400153), EMPTY_CODEC, raw_request);

        require(exit == 0, "Actor returned an error");

        // GetStatsReturn memory stats = decodeStats(data);
        return data;
    }

    function buyCredit(address addr) external payable {
        CommonTypes.FilAddress memory filAddr = FilAddresses.fromEthAddress(addr);
        bytes memory raw_request = FilecoinCBOR.serializeAddress(filAddr);
        (int256 exit, bytes memory data) = Actor.callByID(
            _actorId,
            uint64(1035900737),
            CBOR_CODEC,
            raw_request,
            msg.value,
            false //static call
        );

        require(exit == 0, "Actor returned an error");
    }

    function decodeAccount(bytes memory data) public view returns (AccountReturn memory) {
        //   bytes[] memory decoded = CBORDecoding.decodeArray(data);
        AccountReturn memory acc;
        //   acc.capacityUsed = BigInt.wrap(ByteParser.bytesToBigNumber(decoded[0]));
        //   acc.capacityFree = BigInt.wrap(ByteParser.bytesToBigNumber(decoded[1]));
        //   acc.creditCommitted = BigInt.wrap(ByteParser.bytesToBigNumber(decoded[2]));
        //   acc.lastDebitEpoch = ChainEpoch.wrap(int64(ByteParser.bytesToUint64(decoded[3])));
        return acc;
    }

    function account(address addr) external returns (bytes memory) {
        CommonTypes.FilAddress memory filAddr = FilAddresses.fromEthAddress(addr);
        bytes memory raw_request = FilecoinCBOR.serializeAddress(filAddr);
        (int256 exit, bytes memory data) = Actor.callByID(
            _actorId,
            uint64(3435393067),
            CBOR_CODEC,
            raw_request,
            0,
            false //static call
        );

        require(exit == 0, "Actor returned an error");

        // AccountReturn memory acc = decodeAccount(data);
        return data;
    }

    function approveCredit(ApproveCreditParams memory params) external {
        bytes memory raw_request = new bytes(0);
        (int256 exit, bytes memory data) = Actor.callByID(
            _actorId,
            uint64(2276438360),
            CBOR_CODEC,
            raw_request,
            0,
            false //static call
        );

        require(exit == 0, "Actor returned an error");
    }

    function revokeCredit(RevokeCreditParams memory params) external {
        bytes memory raw_request = new bytes(0);
        (int256 exit, bytes memory data) = Actor.callByID(
            _actorId,
            uint64(37550845),
            CBOR_CODEC,
            raw_request,
            0,
            false //static call
        );

        require(exit == 0, "Actor returned an error");
    }

    function debitAccounts() external {
        bytes memory raw_request = new bytes(0);
        (int256 exit, bytes memory data) = Actor.callByID(
            _actorId,
            uint64(1572888619),
            EMPTY_CODEC,
            raw_request,
            0,
            false //static call
        );

        require(exit == 0, "Actor returned an error");
    }
}
