// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {
    CreateBucketParams, Kind, Machine, Metadata, Object, Query, Value, WriteAccess
} from "../types/BucketTypes.sol";
import {LibWasm} from "./LibWasm.sol";

/// @title Bucket Library
/// @dev Utility functions for interacting with the Hoku Bucket actor.
library LibBucket {
    using LibWasm for *;

    // Constants for the actor and method IDs of the Hoku ADM actor
    uint64 internal constant ADM_ACTOR_ID = 17;
    uint64 internal constant METHOD_CREATE_EXTERNAL = 1214262202;
    uint64 internal constant METHOD_UPDATE_DEPLOYERS = 1768606754;
    uint64 internal constant METHOD_LIST_METADATA = 2283215593;

    // Methods for instances Bucket contracts
    uint64 internal constant METHOD_GET_METADATA = 4024736952;
    uint64 internal constant METHOD_ADD_OBJECT = 3518119203;
    uint64 internal constant METHOD_DELETE_OBJECT = 4237275016;
    uint64 internal constant METHOD_GET_OBJECT = 1894890866;
    uint64 internal constant METHOD_LIST_OBJECTS = 572676265;

    /// @dev Decode a CBOR encoded array of objects.
    /// @param data The CBOR encoded array of objects.
    /// @return objects The decoded objects.
    function decodeObjects(bytes memory data) internal view returns (Object[] memory objects) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return objects;
        objects = new Object[](decoded.length);
        for (uint256 i = 0; i < decoded.length; i++) {
            bytes[] memory object = decoded[i].decodeCborArrayToBytes();
            string memory key = string(object[0].decodeCborBytesArrayToBytes());
            Value memory value = decodeValue(object[1]);
            objects[i] = Object({key: key, value: value});
        }
        return objects;
    }

    /// @dev Decode a CBOR encoded value.
    /// @param data The CBOR encoded value.
    /// @return value The decoded value.
    function decodeValue(bytes memory data) internal view returns (Value memory value) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return value;
        value = Value({
            hash: string(decoded[0].decodeBlobHash()),
            size: decoded[1].decodeCborBytesToUint64(),
            expiry: decoded[2].decodeCborBytesToUint64(),
            metadata: decodeMetadata(decoded[3])
        });
    }

    /// @dev Decode a CBOR encoded array of metadata.
    /// @param data The CBOR encoded array of metadata.
    /// @return metadata The decoded metadata.
    function decodeMetadata(bytes memory data) internal view returns (Metadata[] memory metadata) {
        bytes[2][] memory decoded = data.decodeCborMappingToBytes();
        if (decoded.length == 0) return metadata;
        metadata = new Metadata[](decoded.length);
        for (uint256 i = 0; i < decoded.length; i++) {
            metadata[i] = Metadata({key: string(decoded[i][0]), value: string(decoded[i][1])});
        }
        return metadata;
    }

    /// @dev Decode a CBOR encoded array of common prefixes.
    /// @param data The CBOR encoded array of common prefixes.
    /// @return commonPrefixes The decoded common prefixes.
    function decodeCommonPrefixes(bytes memory data) internal view returns (string[] memory commonPrefixes) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return commonPrefixes;
        commonPrefixes = new string[](decoded.length);
        for (uint256 i = 0; i < decoded.length; i++) {
            commonPrefixes[i] = string(decoded[i].decodeCborBytesArrayToBytes());
        }
    }

    /// @dev Decode a CBOR encoded query.
    /// @param data The CBOR encoded query.
    /// @return decodedQuery The decoded query.
    function decodeQuery(bytes memory data) internal view returns (Query memory decodedQuery) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return decodedQuery;
        decodedQuery.objects = decodeObjects(decoded[0]);
        decodedQuery.commonPrefixes = decodeCommonPrefixes(decoded[1]);
    }

    /// @dev Decode a CBOR encoded machine metadata.
    /// @param data The CBOR encoded machine metadata.
    /// @return machine The decoded machine metadata.
    function decodeMachine(bytes memory data) internal view returns (Machine memory machine) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return machine;
        machine = Machine({
            kind: stringToKind(string(decoded[0])), // Decoded array automatically removes leading byte (string length)
            addr: decoded[1].decodeCborActorAddress(),
            metadata: decodeMetadata(decoded[2])
        });
    }

    /// @dev Decode a CBOR encoded list.
    /// @param data The CBOR encoded list.
    /// @return decodedList The decoded list.
    function decodeList(bytes memory data) internal view returns (Machine[] memory decodedList) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return decodedList;
        decodedList = new Machine[](decoded.length);
        for (uint256 i = 0; i < decoded.length; i++) {
            decodedList[i] = decodeMachine(decoded[i]);
        }
    }

    /// @dev Encode a CBOR encoded create bucket params.
    /// @param params The create bucket params.
    /// @return encoded The CBOR encoded create bucket params.
    function encodeCreateBucketParams(CreateBucketParams memory params) internal pure returns (bytes memory) {
        bytes[] memory encoded = new bytes[](4);
        encoded[0] = params.owner.encodeCborAddress();
        encoded[1] = kindToString(params.kind).encodeCborString();
        encoded[2] = writeAccessToString(params.writeAccess).encodeCborString();
        encoded[3] = hex"a0";
        return LibWasm.encodeCborArray(encoded);
    }

    /// @dev Encode a CBOR encoded query params.
    /// @param prefix The prefix.
    /// @param delimiter The delimiter.
    /// @param offset The offset.
    /// @param limit The limit.
    /// @return encoded The CBOR encoded query params.
    function encodeQueryParams(string memory prefix, string memory delimiter, uint64 offset, uint64 limit)
        internal
        pure
        returns (bytes memory)
    {
        bytes[] memory encoded = new bytes[](4);
        encoded[0] = prefix.encodeCborBytes();
        encoded[1] = delimiter.encodeCborBytes();
        encoded[2] = offset.encodeCborUint64();
        encoded[3] = limit.encodeCborUint64();
        return LibWasm.encodeCborArray(encoded);
    }

    /// @dev Convert a kind to a string.
    /// @param kind The kind.
    /// @return string The string representation of the kind.
    function kindToString(Kind kind) internal pure returns (string memory) {
        if (kind == Kind.ObjectStore) {
            return "ObjectStore";
        } else if (kind == Kind.Accumulator) {
            return "Accumulator";
        }
        revert("Invalid Kind");
    }

    /// @dev Convert a string to a kind.
    /// @param kind The string representation of the kind.
    /// @return kind The kind.
    function stringToKind(string memory kind) internal pure returns (Kind) {
        if (keccak256(abi.encode(kind)) == keccak256(abi.encode("ObjectStore"))) {
            return Kind.ObjectStore;
        } else {
            return Kind.Accumulator;
        }
    }

    /// @dev Convert a write access to a string.
    /// @param writeAccess The write access.
    /// @return string The string representation of the write access.
    function writeAccessToString(WriteAccess writeAccess) internal pure returns (string memory) {
        if (writeAccess == WriteAccess.OnlyOwner) {
            return "OnlyOwner";
        } else if (writeAccess == WriteAccess.Public) {
            return "Public";
        }
        revert("Invalid WriteAccess");
    }

    /// @dev Query the bucket.
    /// @param bucket The bucket.
    /// @param prefix The prefix.
    /// @param delimiter The delimiter.
    /// @param offset The offset.
    /// @param limit The limit.
    /// @return The CBOR encoded query data.
    function query(string memory bucket, string memory prefix, string memory delimiter, uint64 offset, uint64 limit)
        external
        returns (Query memory)
    {
        bytes memory bucketAddr = bucket.encodeCborActorAddress();
        bytes memory params = encodeQueryParams(prefix, delimiter, offset, limit);
        bytes memory data = LibWasm.readFromWasmActorByAddress(bucketAddr, METHOD_LIST_OBJECTS, params);
        return decodeQuery(data);
    }

    /// @dev List the metadata of the bucket.
    /// @return The CBOR encoded metadata data.
    function list() external view returns (Machine[] memory) {
        bytes memory addrEncoded = msg.sender.encodeCborAddress();
        bytes[] memory encoded = new bytes[](1);
        encoded[0] = addrEncoded;
        bytes memory params = encoded.encodeCborArray();
        bytes memory data = LibWasm.readFromWasmActor(ADM_ACTOR_ID, METHOD_LIST_METADATA, params);

        return decodeList(data);
    }

    /// @dev List the metadata of the bucket.
    /// @param owner The owner of the buckets.
    /// @return The CBOR encoded metadata data.
    function list(address owner) external view returns (Machine[] memory) {
        bytes memory addrEncoded = owner.encodeCborAddress();
        bytes[] memory encoded = new bytes[](1);
        encoded[0] = addrEncoded;
        bytes memory params = encoded.encodeCborArray();
        bytes memory data = LibWasm.readFromWasmActor(ADM_ACTOR_ID, METHOD_LIST_METADATA, params);

        return decodeList(data);
    }

    /// @dev Create a bucket.
    /// @param owner The owner.
    function create(address owner) external {
        CreateBucketParams memory createParams = CreateBucketParams({
            owner: owner,
            kind: Kind.ObjectStore,
            writeAccess: WriteAccess.OnlyOwner,
            metadata: new Metadata[](0)
        });
        bytes memory params = encodeCreateBucketParams(createParams);
        LibWasm.writeToWasmActor(ADM_ACTOR_ID, METHOD_CREATE_EXTERNAL, params);
    }
}
