// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {IBucketManager} from "../interfaces/IBucketManager.sol";
import {AddObjectParams, KeyValue, Machine, ObjectValue, Query} from "../types/BucketTypes.sol";
import {LibBucket} from "./LibBucket.sol";
import {LibWasm} from "./LibWasm.sol";

/// @title Bucket Manager Contract
/// @dev Implementation of the Recall Bucket actor EVM interface. See {IBucketManager} for details.
contract BucketManager is IBucketManager {
    /// @dev See {IBucketManager-createBucket}.
    function createBucket() external {
        KeyValue[] memory metadata = new KeyValue[](0);
        LibBucket.createBucket(msg.sender, metadata);
    }

    /// @dev See {IBucketManager-createBucket}.
    function createBucket(address owner) external {
        KeyValue[] memory metadata = new KeyValue[](0);
        LibBucket.createBucket(owner, metadata);
    }

    /// @dev See {IBucketManager-createBucket}.
    function createBucket(address owner, KeyValue[] memory metadata) external {
        LibBucket.createBucket(owner, metadata);
    }

    /// @dev See {IBucketManager-listBuckets}.
    function listBuckets() external view returns (Machine[] memory) {
        return LibBucket.listBuckets(msg.sender);
    }

    /// @dev See {IBucketManager-listBuckets}.
    function listBuckets(address owner) external view returns (Machine[] memory) {
        return LibBucket.listBuckets(owner);
    }

    /// @dev See {IBucketManager-addObject}.
    function addObject(
        address bucket,
        string memory source,
        string memory key,
        string memory blobHash,
        string memory recoveryHash,
        uint64 size,
        address from
    ) external {
        AddObjectParams memory params = AddObjectParams({
            source: source,
            key: key,
            blobHash: blobHash,
            recoveryHash: recoveryHash,
            size: size,
            ttl: 0, // No expiration
            metadata: new KeyValue[](0), // No metadata
            overwrite: false, // Do not overwrite
            from: from
        });
        LibBucket.addObject(bucket, params);
    }

    /// @dev See {IBucketManager-addObject}.
    function addObject(address bucket, AddObjectParams memory params) external {
        LibBucket.addObject(bucket, params);
    }

    /// @dev See {IBucketManager-deleteObject}.
    function deleteObject(address bucket, string memory key, address from) external {
        LibBucket.deleteObject(bucket, key, from);
    }

    /// @dev See {IBucketManager-updateObjectMetadata}.
    function updateObjectMetadata(address bucket, string memory key, KeyValue[] memory metadata, address from)
        external
    {
        LibBucket.updateObjectMetadata(bucket, key, metadata, from);
    }

    /// @dev See {IBucketManager-getObject}.
    function getObject(address bucket, string memory key) external view returns (ObjectValue memory) {
        return LibBucket.getObject(bucket, key);
    }

    /// @dev See {IBucketManager-queryObjects}.
    function queryObjects(address bucket) external view returns (Query memory) {
        return LibBucket.queryObjects(bucket, "", "/", "", 0);
    }

    /// @dev See {IBucketManager-queryObjects}.
    function queryObjects(address bucket, string memory prefix) external view returns (Query memory) {
        return LibBucket.queryObjects(bucket, prefix, "/", "", 0);
    }

    /// @dev See {IBucketManager-queryObjects}.
    function queryObjects(address bucket, string memory prefix, string memory delimiter)
        external
        view
        returns (Query memory)
    {
        return LibBucket.queryObjects(bucket, prefix, delimiter, "", 0);
    }

    /// @dev See {IBucketManager-queryObjects}.
    function queryObjects(address bucket, string memory prefix, string memory delimiter, string memory startKey)
        external
        view
        returns (Query memory)
    {
        return LibBucket.queryObjects(bucket, prefix, delimiter, startKey, 0);
    }

    /// @dev See {IBucketManager-queryObjects}.
    function queryObjects(
        address bucket,
        string memory prefix,
        string memory delimiter,
        string memory startKey,
        uint64 limit
    ) external view returns (Query memory) {
        return LibBucket.queryObjects(bucket, prefix, delimiter, startKey, limit);
    }
}
