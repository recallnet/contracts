// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {CreateBucketParams, Kind, Machine, Metadata, Query, WriteAccess} from "../types/BucketTypes.sol";

/// @dev Hoku Bucket actor EVM interface for managing objects, and querying object or storage stats.
/// See Rust implementation for details:
/// https://github.com/hokunet/ipc/blob/develop/fendermint/actors/objectstore/src/actor.rs
interface IBucketManager {
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
    /// @return The CBOR encoded query data.
    function query(string memory bucket, string memory prefix, string memory delimiter, uint64 offset)
        external
        returns (Query memory);

    /// @dev Query the bucket.
    /// @param bucket The bucket.
    /// @param prefix The prefix.
    /// @param delimiter The delimiter.
    /// @param offset The offset.
    /// @param limit The limit.
    /// @return The CBOR encoded query data.
    function query(string memory bucket, string memory prefix, string memory delimiter, uint64 offset, uint64 limit)
        external
        returns (Query memory);

    /// @dev List the metadata of the bucket.
    /// @return The CBOR encoded metadata data.
    function list() external view returns (Machine[] memory);

    /// @dev List the metadata of the bucket.
    /// @param owner The owner of the buckets.
    /// @return The CBOR encoded metadata data.
    function list(address owner) external view returns (Machine[] memory);

    /// @dev Create a bucket. Uses the sender as the owner.
    function create() external;

    /// @dev Create a bucket.
    /// @param owner The owner.
    function create(address owner) external;
}
