// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {AddObjectParams, KeyValue, Machine, ObjectValue, Query} from "../types/BucketTypes.sol";
import {LibBucket} from "./LibBucket.sol";
import {LibWasm} from "./LibWasm.sol";

/// @dev Hoku Bucket actor EVM interface for managing objects, and querying object or storage stats.
/// See Rust implementation for details:
/// https://github.com/hokunet/ipc/blob/develop/fendermint/actors/objectstore/src/actor.rs
library BucketManager {
    /// @dev Emitted when a bucket is created.
    /// @param owner The owner.
    /// @param data The CBOR encoded response—array with two values including the bucket's ID and robust (t2) addresses.
    event CreateBucket(address indexed owner, bytes data);

    /// @dev Emitted when an object is added to a bucket.
    /// @param owner The owner.
    /// @param bucket The bucket's robust t2 address.
    /// @param key The object key.
    event AddObject(address indexed owner, string bucket, string key);

    /// @dev Emitted when an object is removed from a bucket.
    /// @param owner The owner.
    /// @param bucket The bucket's robust t2 address.
    /// @param key The object key.
    event DeleteObject(address indexed owner, string bucket, string key);

    /// @dev Create a bucket. Uses the sender as the owner.
    function createBucket() external {
        KeyValue[] memory metadata = new KeyValue[](0);
        bytes memory data = LibBucket.createBucket(msg.sender, metadata);
        emit CreateBucket(msg.sender, data);
    }

    /// @dev Create a bucket.
    /// @param owner The owner.
    function createBucket(address owner) external {
        KeyValue[] memory metadata = new KeyValue[](0);
        bytes memory data = LibBucket.createBucket(owner, metadata);
        emit CreateBucket(owner, data);
    }

    /// @dev Create a bucket.
    /// @param owner The owner.
    /// @param metadata The metadata.
    function createBucket(address owner, KeyValue[] memory metadata) external {
        bytes memory data = LibBucket.createBucket(owner, metadata);
        emit CreateBucket(owner, data);
    }

    /// @dev List all buckets owned by the sender.
    /// @return The list of buckets.
    function listBuckets() external view returns (Machine[] memory) {
        return LibBucket.listBuckets(msg.sender);
    }

    /// @dev List all buckets owned by an address.
    /// @param owner The owner of the buckets.
    /// @return The list of buckets.
    function listBuckets(address owner) external view returns (Machine[] memory) {
        return LibBucket.listBuckets(owner);
    }

    /// @dev Add an object to a bucket.
    /// @param bucket The bucket.
    /// @param source The source Iroh node ID used for ingestion.
    /// @param key The object key.
    /// @param blobHash The object blake3 hash.
    /// @param recoveryHash Blake3 hash of the metadata to use for object recovery.
    /// @param size The object size.
    function addObject(
        string memory bucket,
        string memory source,
        string memory key,
        string memory blobHash,
        string memory recoveryHash,
        uint64 size
    ) external {
        AddObjectParams memory params = AddObjectParams({
            source: source,
            key: key,
            blobHash: blobHash,
            recoveryHash: recoveryHash,
            size: size,
            ttl: 0, // No expiration
            metadata: new KeyValue[](0), // No metadata
            overwrite: false // Do not overwrite
        });
        LibBucket.addObject(bucket, params);
        emit AddObject(msg.sender, bucket, key);
    }

    /// @dev Add an object to a bucket.
    /// @param bucket The bucket.
    /// @param params The add object params. See {AddObjectParams} for more details.
    function addObject(string memory bucket, AddObjectParams memory params) external {
        LibBucket.addObject(bucket, params);
        emit AddObject(msg.sender, bucket, params.key);
    }

    /// @dev Delete an object from a bucket.
    /// @param bucket The bucket.
    /// @param key The key.
    function deleteObject(string memory bucket, string memory key) external {
        LibBucket.deleteObject(bucket, key);
        emit DeleteObject(msg.sender, bucket, key);
    }

    /// @dev Get an object from a bucket.
    /// @param bucket The bucket.
    /// @param key The key.
    /// @return value Object's value. See {ObjectValue} for more details.
    function getObject(string memory bucket, string memory key) external view returns (ObjectValue memory) {
        return LibBucket.getObject(bucket, key);
    }

    /// @dev Query the bucket.
    /// @param bucket The bucket.
    /// @return All objects matching the query.
    function queryObjects(string memory bucket) external view returns (Query memory) {
        return LibBucket.queryObjects(bucket, "", "/", "", 0);
    }

    /// @dev Query the bucket.
    /// @param bucket The bucket.
    /// @param prefix The prefix.
    /// @return All objects matching the query.
    function queryObjects(string memory bucket, string memory prefix) external view returns (Query memory) {
        return LibBucket.queryObjects(bucket, prefix, "/", "", 0);
    }

    /// @dev Query the bucket.
    /// @param bucket The bucket.
    /// @param prefix The prefix.
    /// @param delimiter The delimiter.
    /// @return All objects matching the query.
    function queryObjects(string memory bucket, string memory prefix, string memory delimiter)
        external
        view
        returns (Query memory)
    {
        return LibBucket.queryObjects(bucket, prefix, delimiter, "", 0);
    }

    /// @dev Query the bucket.
    /// @param bucket The bucket.
    /// @param prefix The prefix.
    /// @param delimiter The delimiter.
    /// @param startKey The key to start listing objects from.
    /// @return All objects matching the query.
    function queryObjects(string memory bucket, string memory prefix, string memory delimiter, string memory startKey)
        external
        view
        returns (Query memory)
    {
        return LibBucket.queryObjects(bucket, prefix, delimiter, startKey, 0);
    }

    /// @dev Query the bucket.
    /// @param bucket The bucket.
    /// @param prefix The prefix.
    /// @param delimiter The delimiter.
    /// @param startKey The key to start listing objects from.
    /// @param limit The limit.
    /// @return All objects matching the query.
    function queryObjects(
        string memory bucket,
        string memory prefix,
        string memory delimiter,
        string memory startKey,
        uint64 limit
    ) external view returns (Query memory) {
        return LibBucket.queryObjects(bucket, prefix, delimiter, startKey, limit);
    }
}
