// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {IBucketManager} from "./interfaces/IBucketManager.sol";
import {AddParams, CreateBucketParams, KeyValue, Kind, Machine, Object, Query, Value} from "./types/BucketTypes.sol";
import {LibBucket} from "./util/LibBucket.sol";
import {LibWasm} from "./util/LibWasm.sol";

/// @title Bucket Manager Contract
/// @dev Implementation of the Hoku Bucket actor EVM interface. See {IBucketManager} for details.
contract BucketManager is IBucketManager {
    /// @dev See {IBucketManager-create}.
    function create() external {
        KeyValue[] memory metadata = new KeyValue[](0);
        LibBucket.create(msg.sender, metadata);
        emit BucketCreated(msg.sender);
    }

    /// @dev See {IBucketManager-create}.
    function create(address owner) external {
        KeyValue[] memory metadata = new KeyValue[](0);
        LibBucket.create(owner, metadata);
        emit BucketCreated(owner);
    }

    /// @dev See {IBucketManager-create}.
    function create(address owner, KeyValue[] memory metadata) external {
        LibBucket.create(owner, metadata);
        emit BucketCreated(owner);
    }

    /// @dev See {IBucketManager-list}.
    function list() external view returns (Machine[] memory) {
        return LibBucket.list(msg.sender);
    }

    /// @dev See {IBucketManager-list}.
    function list(address owner) external view returns (Machine[] memory) {
        return LibBucket.list(owner);
    }

    /// @dev See {IBucketManager-add}.
    function add(string memory bucket, AddParams memory addParams) external {
        LibBucket.add(bucket, addParams);
        emit ObjectAdded(msg.sender, bucket, addParams.key);
    }

    /// @dev See {IBucketManager-remove}.
    function remove(string memory bucket, string memory key) external {
        LibBucket.remove(bucket, key);
        emit ObjectRemoved(msg.sender, bucket, key);
    }

    /// @dev See {IBucketManager-get}.
    function get(string memory bucket, string memory key) external returns (Value memory) {
        return LibBucket.get(bucket, key);
    }

    /// @dev See {IBucketManager-query}.
    function query(string memory bucket) external returns (Query memory) {
        return LibBucket.query(bucket, "", "/", 0, 0);
    }

    /// @dev See {IBucketManager-query}.
    function query(string memory bucket, string memory prefix) external returns (Query memory) {
        return LibBucket.query(bucket, prefix, "/", 0, 0);
    }

    /// @dev See {IBucketManager-query}.
    function query(string memory bucket, string memory prefix, string memory delimiter)
        external
        returns (Query memory)
    {
        return LibBucket.query(bucket, prefix, delimiter, 0, 0);
    }

    /// @dev See {IBucketManager-query}.
    function query(string memory bucket, string memory prefix, string memory delimiter, uint64 offset)
        external
        returns (Query memory)
    {
        return LibBucket.query(bucket, prefix, delimiter, offset, 0);
    }

    /// @dev See {IBucketManager-query}.
    function query(string memory bucket, string memory prefix, string memory delimiter, uint64 offset, uint64 limit)
        external
        returns (Query memory)
    {
        return LibBucket.query(bucket, prefix, delimiter, offset, limit);
    }
}
