// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import "../../types/BlobTypes.sol";

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

    /// @dev Get a list of added blobs.
    /// @param size Maximum number of added blobs to return.
    /// @return blobs List of added blobs.
    function getAddedBlobs(uint32 size) external view returns (BlobTuple[] memory blobs);

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

    /// @dev Get the total size in bytes of pending blobs.
    /// @return Total size of pending blobs in bytes.
    function getPendingBytesCount() external view returns (uint64);

    /// @dev Get the total count of pending blobs.
    /// @return Total number of pending blobs.
    function getPendingBlobsCount() external view returns (uint64);

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

    /// @dev Get information about a specific blob.
    /// @param blobHash Blob blake3 hash.
    /// @return blob Information, including its hash, size, metadata hash, subscribers and status.
    function getBlob(string memory blobHash) external view returns (Blob memory blob);

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
}
