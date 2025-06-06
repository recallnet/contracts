// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {AddBlobParams, Blob, BlobStatus, BlobTuple, StorageStats, SubnetStats} from "../types/BlobTypes.sol";

/// @dev Recall Blobs actor EVM interface for managing and querying information about blogs/storage.
/// See Rust implementation for details:
/// https://github.com/recallnet/ipc/blob/develop/fendermint/actors/blobs/src/actor.rs
interface IBlobManager {
    /// @dev Get a list of added blobs.
    /// @param size Maximum number of added blobs to return.
    /// @return blobs List of added blobs.
    function getAddedBlobs(uint32 size) external view returns (BlobTuple[] memory blobs);

    /// @dev Get information about a specific blob.
    /// @param blobHash Blob blake3 hash.
    /// @return blob Information, including its hash, size, metadata hash, subscribers and status.
    function getBlob(string memory blobHash) external view returns (Blob memory blob);

    /// @dev Get status of a specific blob for a subscriber.
    /// @param subscriber The address of the subscriber.
    /// @param blobHash Blob blake3 hash.
    /// @param subscriptionId Identifier used to differentiate blob additions for the same subscriber.
    /// @return status The status of the blob: Pending, Resolved or Failed.
    function getBlobStatus(address subscriber, string memory blobHash, string memory subscriptionId)
        external
        view
        returns (BlobStatus status);

    /// @dev Get a list of pending blobs.
    /// @param size Maximum number of pending blobs to return.
    /// @return blobs List of pending blobs.
    function getPendingBlobs(uint32 size) external view returns (BlobTuple[] memory blobs);

    /// @dev Get the total count of pending blobs.
    /// @return Total number of pending blobs.
    function getPendingBlobsCount() external view returns (uint64);

    /// @dev Get the total size in bytes of pending blobs.
    /// @return Total size of pending blobs in bytes.
    function getPendingBytesCount() external view returns (uint64);

    /// @dev Get the storage usage for an account.
    /// @param addr The address of the account.
    /// @return usage The storage usage showing total size of all blobs managed by the account.
    function getStorageUsage(address addr) external view returns (uint256);

    /// @dev Get the storage stats for the subnet.
    /// @return stats The storage stats including capacity and blob counts.
    function getStorageStats() external view returns (StorageStats memory stats);

    /// @dev Get the subnet stats.
    /// @return stats The subnet stats including balance, capacity, credit metrics and counts.
    function getSubnetStats() external view returns (SubnetStats memory stats);

    /// @dev Add a new blob to storage.
    /// @param params Parameters for adding the blob including sponsor, source, hashes, size and TTL.
    function addBlob(AddBlobParams memory params) external;

    /// @dev Delete a blob from storage.
    /// @param subscriber The address of the subscriber.
    /// @param blobHash Blob blake3 hash to delete.
    /// @param subscriptionId Identifier used to differentiate blob additions for the same subscriber.
    /// @param from The address of the account that is deleting the blob.
    function deleteBlob(address subscriber, string memory blobHash, string memory subscriptionId, address from)
        external;

    /// @dev Overwrite a blob in storage.
    /// @param oldHash The blake3 hash of the blob to be deleted.
    /// @param params The parameters for adding a blob.
    function overwriteBlob(string memory oldHash, AddBlobParams memory params) external;
}
