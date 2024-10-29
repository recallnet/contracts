// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {
    AddParams, CreateBucketParams, KeyValue, Kind, Machine, Query, Value, WriteAccess
} from "../types/BucketTypes.sol";

/// @dev Hoku Bucket actor EVM interface for managing objects, and querying object or storage stats.
/// See Rust implementation for details:
/// https://github.com/hokunet/ipc/blob/develop/fendermint/actors/objectstore/src/actor.rs
interface IBucketManager {
    /// @dev Emitted when a bucket is created.
    // TODO: It'd be nice to emit the bucket t2 address, but decoding the CBOR is too expensive.
    event BucketCreated(address indexed owner);

    /// @dev Emitted when an object is added to a bucket.
    event ObjectAdded(address indexed owner, string indexed bucket, string indexed key);

    /// @dev Emitted when an object is removed from a bucket.
    event ObjectRemoved(address indexed owner, string indexed bucket, string indexed key);

    /// @dev Create a bucket. Uses the sender as the owner.
    function create() external;

    /// @dev Create a bucket.
    /// @param owner The owner.
    function create(address owner) external;

    /// @dev Create a bucket.
    /// @param owner The owner.
    /// @param metadata The metadata.
    function create(address owner, KeyValue[] memory metadata) external;

    /// @dev List all buckets owned by an address.
    /// @return The list of buckets.
    function list() external view returns (Machine[] memory);

    /// @dev List all buckets owned by an address.
    /// @param owner The owner of the buckets.
    /// @return The list of buckets.
    function list(address owner) external view returns (Machine[] memory);

    /// @dev Add an object to a bucket.
    /// @param bucket The bucket.
    /// @param source The source Iroh node ID used for ingestion.
    /// @param key The object key.
    /// @param blobHash The object blake3 hash.
    /// @param recoveryHash Blake3 hash of the metadata to use for object recovery.
    /// @param size The object size.
    function add(
        string memory bucket,
        string memory source,
        string memory key,
        string memory blobHash,
        string memory recoveryHash,
        uint64 size
    ) external;

    /// @dev Add an object to a bucket.
    /// @param bucket The bucket.
    /// @param addParams The add object params. See {AddParams} for more details.
    function add(string memory bucket, AddParams memory addParams) external;

    /// @dev Delete an object from a bucket.
    /// @param bucket The bucket.
    /// @param key The key.
    function remove(string memory bucket, string memory key) external;

    /// @dev Get an object from a bucket.
    /// @param bucket The bucket.
    /// @param key The key.
    /// @return value Object's value. See {Value} for more details.
    function get(string memory bucket, string memory key) external returns (Value memory);

    /// @dev Query the bucket.
    /// @param bucket The bucket.
    /// @return The CBOR encoded query data.
    function query(string memory bucket) external returns (Query memory);

    /// @dev Query the bucket.
    /// @param bucket The bucket.
    /// @param prefix The prefix.
    /// @return The CBOR encoded query data.
    function query(string memory bucket, string memory prefix) external returns (Query memory);

    /// @dev Query the bucket.
    /// @param bucket The bucket.
    /// @param prefix The prefix.
    /// @param delimiter The delimiter.
    /// @return The CBOR encoded query data.
    function query(string memory bucket, string memory prefix, string memory delimiter)
        external
        returns (Query memory);

    /// @dev Query the bucket.
    /// @param bucket The bucket.
    /// @param prefix The prefix.
    /// @param delimiter The delimiter.
    /// @param offset The offset.
    /// @return All objects matching the query.
    function query(string memory bucket, string memory prefix, string memory delimiter, uint64 offset)
        external
        returns (Query memory);

    /// @dev Query the bucket.
    /// @param bucket The bucket.
    /// @param prefix The prefix.
    /// @param delimiter The delimiter.
    /// @param offset The offset.
    /// @param limit The limit.
    /// @return All objects matching the query.
    function query(string memory bucket, string memory prefix, string memory delimiter, uint64 offset, uint64 limit)
        external
        returns (Query memory);
}
