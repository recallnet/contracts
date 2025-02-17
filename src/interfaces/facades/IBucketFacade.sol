// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

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
}
