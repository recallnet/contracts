// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

interface IBlobReaderFacade {
    /// @dev Emitted when a blob read request is opened.
    /// @param id Read request ID.
    /// @param blobHash Blob blake3 hash.
    /// @param readOffset Blob byte offset to read from.
    /// @param readLength Blob byte length to read.
    /// @param callbackAddress Contract address to receive read bytes.
    /// @param callbackMethod Contract method number to receive read bytes.
    event ReadRequestOpened(
        bytes32 id,
        bytes32 blobHash,
        uint256 readOffset,
        uint256 readLength,
        address callbackAddress,
        uint256 callbackMethod
    );

    /// @dev Emitted when the system actor marks a read request as pending, triggering validators to forward
    /// data to the request callback.
    /// @param id Read request ID.
    event ReadRequestPending(bytes32 id);

    /// @dev Emitted when the system actor marks a read request as closed.
    /// @param id Read request ID.
    event ReadRequestClosed(bytes32 id);
}
