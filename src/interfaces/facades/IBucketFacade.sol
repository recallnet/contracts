// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {KeyValue} from "../../types/CommonTypes.sol";

/// @dev Parameters for adding an object to a bucket.
/// @param source (string): The source Iroh node ID used for ingestion.
/// @param key (string): The object key.
/// @param blobHash (string): The object blake3 hash.
/// @param recoveryHash (string): Blake3 hash of the metadata to use for object recovery.
/// @param size (uint64): The object size.
/// @param ttl (uint64): The object time-to-live epochs.
/// @param metadata (KeyValue[]): The object metadata.
/// @param overwrite (bool): Whether to overwrite a key if it already exists.
struct AddObjectParams {
    bytes32 source;
    string key;
    bytes32 hash;
    bytes32 recoveryHash;
    uint64 size;
    uint64 ttl;
    KeyValue[] metadata;
    bool overwrite;
}

/// @dev The value of an object when getting an object.
/// @param blobHash (string): The object blake3 hash.
/// @param recoveryHash (string): Blake3 hash of the metadata to use for object recovery.
/// @param size (uint64): The object size.
/// @param expiry (uint64): The expiry block.
/// @param metadata (KeyValue[]): The user-defined object metadata (e.g., last modified timestamp, etc.).
struct ObjectValue {
    bytes32 blobHash;
    bytes32 recoveryHash;
    uint64 size;
    uint64 expiry;
    KeyValue[] metadata;
}

/// @dev The result of a bucket query.
/// @param objects (Object[]): The list of key-values matching the list query.
/// @param commonPrefixes (string[]): When a delimiter is used in the list query, this contains common key prefixes.
/// @param nextKey (string): Next key to use for paginating when there are more objects to list.
struct Query {
    Object[] objects;
    string[] commonPrefixes;
    string nextKey;
}

/// @dev An object in the bucket as part of a query.
/// @param key (string): The object key.
/// @param value (ObjectState): The object state.
struct Object {
    string key;
    ObjectState state;
}

/// @dev The state of an object.
/// @param blobHash (string): The object blake3 hash.
/// @param size (uint64): The object size.
/// @param expiry (uint64): The expiry block.
/// @param metadata (KeyValue[]): The user-defined object metadata (e.g., last modified timestamp, etc.).
struct ObjectState {
    bytes32 blobHash;
    uint64 size;
    uint64 expiry;
    KeyValue[] metadata;
}

interface IBucketFacade {
    /// @dev Emitted when an object is added to a bucket.
    /// @param key Object bucket key.
    /// @param blobHash Object blob blake3 hash.
    /// @param metadata IPLD-encoded object metadata (HashMap<String, String>).
    event ObjectAdded(bytes key, bytes32 blobHash, bytes metadata);

    /// @dev Emitted when an object's metadata is updated.
    /// @param key Object bucket key.
    /// @param metadata IPLD-encoded object metadata (HashMap<String, String>).
    event ObjectMetadataUpdated(bytes key, bytes metadata);

    /// @dev Emitted when an object is deleted from a bucket.
    /// @param key Object bucket key.
    /// @param blobHash Object blob blake3 hash.
    event ObjectDeleted(bytes key, bytes32 blobHash);

    // FIXME SU ADM CALLS
    //    /// @dev Create a bucket. Uses the sender as the owner.
    //    function createBucket() external;
    //
    //    /// @dev Create a bucket.
    //    /// @param owner The owner.
    //    function createBucket(address owner) external;
    // FIXME SU ADM CALL
    //    /// @dev Create a bucket.
    //    /// @param owner The owner.
    //    /// @param metadata The metadata.
    //    function createBucket(address owner, KeyValue[] memory metadata) external;

    // FIXME SU ADM CALL
    //    /// @dev List all buckets owned by an address.
    //    /// @return The list of buckets.
    //    function listBuckets() external view returns (Machine[] memory);
    //
    //    /// @dev List all buckets owned by an address.
    //    /// @param owner The owner of the buckets.
    //    /// @return The list of buckets.
    //    function listBuckets(address owner) external view returns (Machine[] memory);

    /// @dev Add an object to a bucket.
    /// @param source The source Iroh node ID used for ingestion.
    /// @param key The object key.
    /// @param hash The object blake3 hash.
    /// @param recoveryHash Blake3 hash of the metadata to use for object recovery.
    /// @param size The object size.
    function addObject(bytes32 source, string memory key, bytes32 hash, bytes32 recoveryHash, uint64 size) external;

    /// @dev Add an object to a bucket.
    /// @param params The add object params. See {AddObjectParams} for more details.
    function addObject(AddObjectParams memory params) external;

    /// @dev Delete an object from a bucket.
    /// @param key The key.
    function deleteObject(string memory key) external;

    /// @dev Update the metadata of an object.
    /// @param key The key.
    /// @param metadata The metadata.
    function updateObjectMetadata(string memory key, KeyValue[] memory metadata) external;

    /// @dev Get an object from a bucket.
    /// @param key The key.
    /// @return value Object's value. See {ObjectValue} for more details.
    function getObject(string memory key) external view returns (ObjectValue memory);

    /// @dev Query the bucket.
    /// @return All objects matching the query.
    function queryObjects() external view returns (Query memory);

    /// @dev Query the bucket.
    /// @param prefix The prefix.
    /// @return All objects matching the query.
    function queryObjects(string memory prefix) external view returns (Query memory);

    /// @dev Query the bucket.
    /// @param prefix The prefix.
    /// @param delimiter The delimiter.
    /// @return All objects matching the query.
    function queryObjects(string memory prefix, string memory delimiter) external view returns (Query memory);

    /// @dev Query the bucket.
    /// @param prefix The prefix.
    /// @param delimiter The delimiter.
    /// @param startKey The key to start listing objects from.
    /// @return All objects matching the query.
    function queryObjects(string memory prefix, string memory delimiter, string memory startKey)
        external
        view
        returns (Query memory);

    /// @dev Query the bucket.
    /// @param prefix The prefix.
    /// @param delimiter The delimiter.
    /// @param startKey The key to start listing objects from.
    /// @param limit The limit.
    /// @return All objects matching the query.
    function queryObjects(string memory prefix, string memory delimiter, string memory startKey, uint64 limit)
        external
        view
        returns (Query memory);
}
