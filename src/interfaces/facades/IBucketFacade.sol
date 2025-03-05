// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import "../../types/BucketTypes.sol";

// TODO SU: Got rid of "bucket" address param.
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
//
//    /// @dev Create a bucket.
//    /// @param owner The owner.
//    /// @param metadata The metadata.
//    function createBucket(address owner, KeyValue[] memory metadata) external;

    // FIXME SU ADM CALLS
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
    /// @param blobHash The object blake3 hash.
    /// @param recoveryHash Blake3 hash of the metadata to use for object recovery.
    /// @param size The object size.
    /// @param from The address of the account that is adding the object.
    function addObject(
        string memory source,
        string memory key,
        string memory blobHash,
        string memory recoveryHash,
        uint64 size,
        address from
    ) external;

    /// @dev Add an object to a bucket.
    /// @param addObjectParams The add object params. See {AddObjectParams} for more details.
    function addObject(AddObjectParams memory addObjectParams) external;

    /// @dev Delete an object from a bucket.
    /// @param key The key.
    /// @param from The address of the account that is deleting the object.
    function deleteObject(string memory key, address from) external;

    /// @dev Update the metadata of an object.
    /// @param key The key.
    /// @param metadata The metadata.
    /// @param from The address of the account that is updating the metadata.
    function updateObjectMetadata(string memory key, KeyValue[] memory metadata, address from)
    external;

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
    function queryObjects(string memory prefix, string memory delimiter)
    external
    view
    returns (Query memory);

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
    function queryObjects(
        string memory prefix,
        string memory delimiter,
        string memory startKey,
        uint64 limit
    ) external view returns (Query memory);
}
