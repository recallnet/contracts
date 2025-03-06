// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {BlobStatus, BlobTuple, StorageStats, SubnetStats} from "../../types/BlobTypes.sol";

/// @dev Parameters for adding a raw blob.
/// @param sponsor  Optional sponsor address.
/// @param source Source Iroh node ID used for ingestion.
/// @param blobHash Blob blake3 hash.
/// @param metadataHash  Blake3 hash of the metadata to use for blob recovery.
/// @param subscriptionId Identifier used to differentiate blob additions for the same subscriber.
/// @param size Blob size.
/// @param ttl Blob time-to-live epochs. If not specified, the auto-debitor maintains about one hour of credits as an
/// ongoing commitment.
/// @param from Address of the entity adding the blob.
struct AddBlobParams {
    address sponsor;
    bytes32 source;
    bytes32 blobHash;
    bytes32 metadataHash;
    string subscriptionId;
    uint64 size;
    uint64 ttl;
}

/// @dev Blob information and status.
/// @param size (uint64): The size of the blob content in bytes.
/// @param metadataHash (string): Blob metadata hash that contains information for block recovery.
/// @param subscribers (bytes): Active subscribers (accounts) that are paying for the blob, encoded as HashMap<Address,
/// SubscriptionGroup>.
/// @param status (bytes): Current status of the blob.
struct Blob {
    uint64 size;
    bytes32 metadataHash;
    Subscriber[] subscribers;
    BlobStatus status;
}

/// @dev A subscriber and their subscription groups.
/// @param subscriber (address): The subscriber address.
/// @param subscriptionGroup (SubscriptionGroup[]): The subscription groups. See {SubscriptionGroup} for more details.
struct Subscriber {
    address subscriber;
    SubscriptionGroup[] subscriptionGroup;
}

/// @dev Pending subscription information.
/// @param subscriptionId (string): The subscription ID.
/// @param publicKey (bytes): The public key.
struct SubscriptionGroup {
    // TODO: the blobs solidity logic assumes a string key. But, a blob added when pushing to a bucket will serialize
    // the key as the blake3(Vec<bucket_address + object_key>). We should probably make this value a bytes type, but all
    // of the encoding/decoding logic works...except you might see odd decoding with a bucket-backed blob, like a
    // subscription ID of `��0������䣱p�V�%���?��:\u{8}4T�~��V`.
    string subscriptionId;
    Subscription subscription;
}

/// @dev A subscription to a blob.
/// @param added (uint64): The block number when the subscription was added.
/// @param expiry (uint64): The block number when the subscription will expire.
/// @param source (string): The source Iroh node ID used for ingestion.
/// @param delegate (address): The delegate origin that may have created the subscription via a credit approval.
/// approval (else, zero address if null)
/// @param failed (bool): Whether the subscription failed due to an issue resolving the target blob.
struct Subscription {
    uint64 added;
    uint64 expiry;
    bytes32 source;
    address delegate;
    bool failed;
}

/// @dev Params for trimming blob expiries.
/// @param subscriber (address): Address to trim blob expiries for.
/// @param startingHash (bytes32): Starting hash to trim expiries from. 0x00 means "None".
/// @param limit (uint64): Maximum number of blobs that will be examined for trimming. 0 means "no limit" or rather max of uint64.
struct TrimBlobExpiriesParams {
    address subscriber;
    bytes32 startingHash;
    uint32 limit;
}

struct TrimBlobExpiries {
    uint32 processed;
    bytes32 nextKey;
}

interface IBlobsFacade {
    /// @dev Emitted when a blob is added.
    /// @param subscriber Blob subscriber address.
    /// @param hash Blob blake3 hash.
    /// @param size Blob size.
    /// @param expiry Blob expiry epoch.
    /// @param bytesUsed Network capacity bytes used.
    event BlobAdded(address indexed subscriber, bytes32 hash, uint256 size, uint256 expiry, uint256 bytesUsed);

    /// @dev Emitted when the system actor marks a blob as pending, triggering validators to start
    /// the blob commitment process.
    /// @param subscriber Blob subscriber address.
    /// @param hash Blob blake3 hash.
    /// @param sourceId Iroh node ID (public key) providing the blob.
    event BlobPending(address indexed subscriber, bytes32 hash, bytes32 sourceId);

    /// @dev Emitted when the system actor marks a blob as resolved or failed.
    /// @param subscriber Blob subscriber address.
    /// @param hash Blob blake3 hash.
    /// @param resolved Whether the blob was successfully resolved by the network.
    event BlobFinalized(address indexed subscriber, bytes32 hash, bool resolved);

    /// @dev Emitted when a blob is deleted.
    /// @param subscriber Blob subscriber address.
    /// @param hash Blob blake3 hash.
    /// @param size Blob size.
    /// @param bytesReleased Network capacity bytes released.
    event BlobDeleted(address indexed subscriber, bytes32 hash, uint256 size, uint256 bytesReleased);

    /// @dev Add a new blob to storage.
    /// @param params Parameters for adding the blob including sponsor, source, hashes, size and TTL.
    function addBlob(AddBlobParams memory params) external;

    /// @dev Get information about a specific blob.
    /// @param blobHash Blob blake3 hash.
    /// @return blob Information, including its hash, size, metadata hash, subscribers and status.
    function getBlob(bytes32 blobHash) external view returns (Blob memory blob);

    /// @dev Delete a blob from storage.
    /// @param subscriber The address of the subscriber.
    /// @param blobHash Blob blake3 hash to delete.
    /// @param subscriptionId Identifier used to differentiate blob additions for the same subscriber.
    function deleteBlob(address subscriber, bytes32 blobHash, string memory subscriptionId)
    external;

    /// @dev Overwrite a blob in storage.
    /// @param oldHash The blake3 hash of the blob to be deleted.
    /// @param params The parameters for adding a blob.
    function overwriteBlob(bytes32 oldHash, AddBlobParams memory params) external;

    /// @dev Get the subnet stats.
    /// @return stats The stats including balance, capacity, credit metrics and counts.
    function getStats() external view returns (SubnetStats memory stats);

    /// @dev Trims the subscription expiries for an account based on its current maximum allowed blob TTL.
    /// @param params Options for trimming.
    function trimBlobExpiries(TrimBlobExpiriesParams memory params) external returns (TrimBlobExpiries memory);
}
