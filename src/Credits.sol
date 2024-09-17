// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Actor} from "@filecoin-solidity/v0.8/utils/Actor.sol";
import {FilAddresses} from "@filecoin-solidity/v0.8/utils/FilAddresses.sol";
import {CommonTypes} from "@filecoin-solidity/v0.8/types/CommonTypes.sol";
import {FilecoinCBOR} from "@filecoin-solidity/v0.8/cbor/FilecoinCBOR.sol";

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

contract Credits {
    CommonTypes.FilActorId internal _actorId = CommonTypes.FilActorId.wrap(49);
    uint64 internal constant EMPTY_CODEC = 0x00;
    uint64 internal constant CBOR_CODEC = 0x51;

    constructor() {}

    function getStats() external returns (bytes memory) {
        bytes memory raw_request = new bytes(0);
        (int256 exit, bytes memory data) = Actor.callByIDReadOnly(_actorId, uint64(188400153), EMPTY_CODEC, raw_request);

        require(exit == 0, "Actor returned an error");

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

    function getAccount(address addr) external {
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
