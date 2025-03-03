// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

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

    /// @dev Get the total size in bytes of pending blobs.
    /// @return Total size of pending blobs in bytes.
    function getPendingBytesCount() external view returns (uint64);

    /// @dev Get the total count of pending blobs.
    /// @return Total number of pending blobs.
    function getPendingBlobsCount() external view returns (uint64);
}
