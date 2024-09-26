// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Actor} from "@filecoin-solidity/v0.8/utils/Actor.sol";
import {FilAddresses} from "@filecoin-solidity/v0.8/utils/FilAddresses.sol";
import {CommonTypes} from "@filecoin-solidity/v0.8/types/CommonTypes.sol";
import {FilecoinCBOR} from "@filecoin-solidity/v0.8/cbor/FilecoinCBOR.sol";
import {CBORDecoding} from "./util/CBORDecoding.sol";
import {ByteParser} from "./util/ByteParser.sol";

import {console} from "forge-std/console.sol";

type BigInt is int256;

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
    BigInt capacityFree;
    BigInt capacityUsed;
    BigInt creditSold;
    BigInt creditCommitted;
    BigInt creditDebited;
    uint64 creditDebitRate;
    uint64 numAccounts;
    uint64 numBlobs;
    uint64 numResolving;
}

struct AccountReturn {
    BigInt capacityUsed;
    BigInt capacityFree;
    BigInt creditCommitted;
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

    function parseBigInt(bytes memory data) internal returns (BigInt) {
        bytes[] memory decoded = decodeArray(data);
        uint64 sign = bytesToUint64(decoded[0]);
        bytes[] memory value = decodeArray(decoded[1]);
        if (value.length == 0) {
            return BigInt.wrap(0);
        }
        uint256 result = 0;
        for (uint256 i = 0; i < value.length; i++) {
            bytes memory val = this.decodePrimitive(value[i]);
            result = result << 8;
            result += bytesToUint256(val);
        }
        int256 signedResult = int256(result);
        if (sign == 0) {
            signedResult *= -1;
        }
        return BigInt.wrap(signedResult);
    }

    function decodeStats(bytes memory data) external returns (GetStatsReturn memory) {
        bytes[] memory decoded = decodeArray(data);
        TokenAmount memory balance;
        // This isn't properly encoded in the actor
        // bytes[] memory decodedBalance = decodeArray(decoded[0]);
        balance.atto = BigInt.wrap(int256(bytesToUint256(decoded[0])));
        GetStatsReturn memory stats;
        stats.balance = balance;
        stats.capacityFree = parseBigInt(decoded[1]);
        stats.capacityUsed = parseBigInt(decoded[2]);
        stats.creditSold = parseBigInt(decoded[3]);
        stats.creditCommitted = parseBigInt(decoded[4]);
        stats.creditDebited = parseBigInt(decoded[5]);
        stats.creditDebitRate = bytesToUint64(decoded[6]);
        stats.numAccounts = bytesToUint64(decoded[7]);
        stats.numBlobs = bytesToUint64(decoded[8]);
        stats.numResolving = bytesToUint64(decoded[9]);
        return stats;
    }

    function getStats() external returns (GetStatsReturn memory) {
        bytes memory raw_request = new bytes(0);
        (int256 exit, bytes memory data) = Actor.callByIDReadOnly(_actorId, uint64(188400153), EMPTY_CODEC, raw_request);

        require(exit == 0, "Actor returned an error");

        return this.decodeStats(data);
    }

    function buyCredit(address addr) external payable returns (AccountReturn memory) {
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

        return this.decodeAccount(data);
    }

    function decodeAccount(bytes memory data) external returns (AccountReturn memory) {
        bytes[] memory decoded = decodeArray(data);
        AccountReturn memory acc;
        acc.capacityUsed = parseBigInt(decoded[1]);
        acc.capacityFree = parseBigInt(decoded[2]);
        acc.creditCommitted = parseBigInt(decoded[3]);
        acc.lastDebitEpoch = ChainEpoch.wrap(int64(bytesToUint64(decoded[4])));
        return acc;
    }

    function account(address addr) external returns (AccountReturn memory) {
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

        return this.decodeAccount(data);
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
