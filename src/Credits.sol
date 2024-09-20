// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Actor} from "@filecoin-solidity/v0.8/utils/Actor.sol";
import {FilAddresses} from "@filecoin-solidity/v0.8/utils/FilAddresses.sol";
import {CommonTypes} from "@filecoin-solidity/v0.8/types/CommonTypes.sol";
import {FilecoinCBOR} from "@filecoin-solidity/v0.8/cbor/FilecoinCBOR.sol";
import {CBORDecoding} from "@solidity-cbor/CBORDecoding.sol";
import {ByteParser} from "@solidity-cbor/ByteParser.sol";

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

contract Credits {
    CommonTypes.FilActorId internal _actorId = CommonTypes.FilActorId.wrap(49);
    uint64 internal constant EMPTY_CODEC = 0x00;
    uint64 internal constant CBOR_CODEC = 0x51;

    constructor() {}

    function decodeStats(bytes memory data) internal view returns (GetStatsReturn memory) {
      bytes[2][] memory decoded = CBORDecoding.decodeMapping(data);
      TokenAmount memory balance;
      bytes[2][] memory balanceDecoded = CBORDecoding.decodeMapping(decoded[0][1]);
      balance.atto = BigInt.wrap(ByteParser.bytesToBigNumber(balanceDecoded[0][0]));
      GetStatsReturn memory stats;
      stats.balance = balance;
      stats.capacityFree = BigInt.wrap(ByteParser.bytesToBigNumber(decoded[1][0]));
      stats.capacityUsed = BigInt.wrap(ByteParser.bytesToBigNumber(decoded[2][0]));
      stats.creditSold = BigInt.wrap(ByteParser.bytesToBigNumber(decoded[3][0]));
      stats.creditCommitted = BigInt.wrap(ByteParser.bytesToBigNumber(decoded[4][0]));
      stats.creditDebited = BigInt.wrap(ByteParser.bytesToBigNumber(decoded[5][0]));
      stats.creditDebitRate = ByteParser.bytesToUint64(decoded[6][0]);
      stats.numAccounts = ByteParser.bytesToUint64(decoded[7][0]);
      stats.numBlobs = ByteParser.bytesToUint64(decoded[8][0]);
      stats.numResolving = ByteParser.bytesToUint64(decoded[9][0]);
      stats.capacityFree = BigInt.wrap(ByteParser.bytesToBigNumber(decoded[10][0]));
      return stats;
    }

    function getStats() external view returns (GetStatsReturn memory) {
        bytes memory raw_request = new bytes(0);
        (int256 exit, bytes memory data) = Actor.callByIDReadOnly(_actorId, uint64(188400153), EMPTY_CODEC, raw_request);

        require(exit == 0, "Actor returned an error");

        return decodeStats(data);
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

    function decodeAccount(bytes memory data) internal view returns (AccountReturn memory) {
      bytes[2][] memory decoded = CBORDecoding.decodeMapping(data);
      AccountReturn memory acc;
      acc.capacityUsed = BigInt.wrap(ByteParser.bytesToBigNumber(decoded[0][0]));
      acc.capacityFree = BigInt.wrap(ByteParser.bytesToBigNumber(decoded[1][0]));
      acc.creditCommitted = BigInt.wrap(ByteParser.bytesToBigNumber(decoded[2][0]));
      acc.lastDebitEpoch = ChainEpoch.wrap(int64(ByteParser.bytesToUint64(decoded[3][0])));
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

        return decodeAccount(data);
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
