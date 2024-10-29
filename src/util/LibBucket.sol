// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {
    AddParams,
    CreateBucketParams,
    KeyValue,
    Kind,
    Machine,
    Object,
    Query,
    Value,
    WriteAccess
} from "../types/BucketTypes.sol";
import {InvalidValue, LibWasm} from "./LibWasm.sol";

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

    /// @dev Decode a CBOR encoded array of metadata.
    /// @param data The CBOR encoded array of metadata.
    /// @return metadata The decoded metadata.
    function decodeMetadata(bytes memory data) internal view returns (KeyValue[] memory metadata) {
        bytes[2][] memory decoded = data.decodeCborMappingToBytes();
        if (decoded.length == 0) return metadata;
        metadata = new KeyValue[](decoded.length);
        for (uint256 i = 0; i < decoded.length; i++) {
            metadata[i] = KeyValue({key: string(decoded[i][0]), value: string(decoded[i][1])});
        }
        return metadata;
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
            blobHash: string(decoded[0].decodeBlobHash()),
            recoveryHash: string(decoded[1].decodeBlobHash()),
            size: decoded[2].decodeCborBytesToUint64(),
            expiry: decoded[3].decodeCborBytesToUint64(),
            metadata: decodeMetadata(decoded[4])
        });
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

    /// @dev Encode a CBOR encoded create bucket params.
    /// @param params The create bucket params.
    /// @return encoded The CBOR encoded create bucket params.
    function encodeCreateBucketParams(CreateBucketParams memory params) internal pure returns (bytes memory) {
        bytes[] memory encoded = new bytes[](4);
        encoded[0] = params.owner.encodeCborAddress();
        encoded[1] = kindToString(params.kind).encodeCborString();
        encoded[2] = writeAccessToString(params.writeAccess).encodeCborString();
        encoded[3] = params.metadata.encodeCborKeyValueMap();
        return encoded.encodeCborArray();
    }

    /// @dev Encode a CBOR encoded add params.
    /// @param params The add params.
    /// @return encoded The CBOR encoded add params.
    function encodeAddParams(AddParams memory params) internal pure returns (bytes memory) {
        bytes[] memory encoded = new bytes[](8);
        encoded[0] = params.source.encodeCborBlobHashOrNodeId();
        encoded[1] = params.key.encodeCborBytes();
        encoded[2] = params.blobHash.encodeCborBlobHashOrNodeId();
        // TODO: this currently is hardcoded to a 32 byte array of all zeros, but should use the method above
        // Once https://github.com/hokunet/ipc/issues/300 is merged, this'll need to change
        encoded[3] = hex"0000000000000000000000000000000000000000000000000000000000000000".encodeCborFixedArray();
        encoded[4] = params.size.encodeCborUint64();
        encoded[5] = params.ttl == 0 ? LibWasm.encodeCborNull() : params.ttl.encodeCborUint64();
        encoded[6] = params.metadata.encodeCborKeyValueMap();
        encoded[7] = params.overwrite.encodeCborBool();
        return encoded.encodeCborArray();
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
        return encoded.encodeCborArray();
    }

    /// @dev Convert a kind to a string.
    /// @param kind The kind.
    /// @return string The string representation of the kind.
    function kindToString(Kind kind) internal pure returns (string memory) {
        if (kind == Kind.Bucket) {
            return "Bucket";
        } else if (kind == Kind.Timehub) {
            return "Timehub";
        }
        revert InvalidValue("Invalid machine kind");
    }

    /// @dev Convert a string to a kind.
    /// @param kind The string representation of the kind.
    /// @return kind The kind.
    function stringToKind(string memory kind) internal pure returns (Kind) {
        if (keccak256(bytes(kind)) == keccak256(bytes("Bucket"))) {
            return Kind.Bucket;
        } else if (keccak256(bytes(kind)) == keccak256(bytes("Timehub"))) {
            return Kind.Timehub;
        }
        revert InvalidValue("Invalid machine kind");
    }

    /// @dev Convert a write access to a string.
    /// @param writeAccess The write access.
    /// @return string The string representation of the write access.
    // TODO: we'll eventually remove this since credit approvals handle access control
    function writeAccessToString(WriteAccess writeAccess) internal pure returns (string memory) {
        if (writeAccess == WriteAccess.OnlyOwner) {
            return "OnlyOwner";
        } else {
            return "Public";
        }
    }

    /// @dev Create a bucket.
    /// @param owner The owner.
    /// @param metadata The metadata.
    function create(address owner, KeyValue[] memory metadata) external {
        CreateBucketParams memory createParams = CreateBucketParams({
            owner: owner,
            kind: Kind.Bucket,
            writeAccess: WriteAccess.OnlyOwner, // Bucket access control always uses credit approvals
            metadata: metadata
        });
        bytes memory params = encodeCreateBucketParams(createParams);
        LibWasm.writeToWasmActor(ADM_ACTOR_ID, METHOD_CREATE_EXTERNAL, params);
    }

    /// @dev List all buckets owned by an address.
    /// @param owner The owner of the buckets.
    /// @return The list of buckets.
    function list(address owner) external view returns (Machine[] memory) {
        bytes memory addrEncoded = owner.encodeCborAddress();
        bytes[] memory encoded = new bytes[](1);
        encoded[0] = addrEncoded;
        bytes memory params = encoded.encodeCborArray();
        bytes memory data = LibWasm.readFromWasmActor(ADM_ACTOR_ID, METHOD_LIST_METADATA, params);
        return decodeList(data);
    }

    /// @dev Add an object to the bucket.
    /// @param bucket The bucket.
    /// @param addParams The add object params. See {AddParams} for more details.
    function add(string memory bucket, AddParams memory addParams) external {
        bytes memory bucketAddr = bucket.encodeCborActorAddress();
        bytes memory params = encodeAddParams(addParams);
        LibWasm.writeToWasmActorByAddress(bucketAddr, METHOD_ADD_OBJECT, params);
    }

    /// @dev Delete an object from the bucket.
    /// @param bucket The bucket.
    /// @param key The object key.
    function remove(string memory bucket, string memory key) external {
        bytes memory bucketAddr = bucket.encodeCborActorAddress();
        bytes memory params = key.encodeCborBytes();
        LibWasm.writeToWasmActorByAddress(bucketAddr, METHOD_DELETE_OBJECT, params);
    }

    /// @dev Get an object from the bucket.
    /// @param bucket The bucket.
    /// @param key The object key.
    /// @return Object's value. See {Value} for more details.
    function get(string memory bucket, string memory key) external returns (Value memory) {
        bytes memory bucketAddr = bucket.encodeCborActorAddress();
        bytes memory params = key.encodeCborBytes();
        bytes memory data = LibWasm.readFromWasmActorByAddress(bucketAddr, METHOD_GET_OBJECT, params);
        return decodeValue(data);
    }

    /// @dev Query the bucket.
    /// @param bucket The bucket.
    /// @param prefix The prefix.
    /// @param delimiter The delimiter.
    /// @param offset The offset.
    /// @param limit The limit.
    /// @return All objects matching the query.
    function query(string memory bucket, string memory prefix, string memory delimiter, uint64 offset, uint64 limit)
        external
        returns (Query memory)
    {
        bytes memory bucketAddr = bucket.encodeCborActorAddress();
        bytes memory params = encodeQueryParams(prefix, delimiter, offset, limit);
        bytes memory data = LibWasm.readFromWasmActorByAddress(bucketAddr, METHOD_LIST_OBJECTS, params);
        return decodeQuery(data);
    }
}
