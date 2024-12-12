// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {IBlobManager} from "../interfaces/IBlobManager.sol";
import {AddBlobParams, Blob, BlobStatus, BlobTuple, StorageStats, SubnetStats} from "../types/BlobTypes.sol";
import {LibBlob} from "./LibBlob.sol";

contract BlobManager is IBlobManager {
    /// @dev See {IBlobManager-getAddedBlobs}.
    function getAddedBlobs(uint32 size) external view returns (BlobTuple[] memory blobs) {
        return LibBlob.getPendingBlobs(size);
    }

    /// @dev See {IBlobManager-getBlob}.
    function getBlob(string memory blobHash) external view returns (Blob memory blob) {
        return LibBlob.getBlob(blobHash);
    }

    /// @dev See {IBlobManager-getBlobStatus}.
    function getBlobStatus(address subscriber, string memory blobHash, string memory subscriptionId)
        external
        view
        returns (BlobStatus status)
    {
        return LibBlob.getBlobStatus(subscriber, blobHash, subscriptionId);
    }

    /// @dev See {IBlobManager-getPendingBlobs}.
    function getPendingBlobs(uint32 size) external view returns (BlobTuple[] memory blobs) {
        return LibBlob.getPendingBlobs(size);
    }

    /// @dev See {IBlobManager-getPendingBlobsCount}.
    function getPendingBlobsCount() external view returns (uint64) {
        return LibBlob.getPendingBlobsCount();
    }

    /// @dev See {IBlobManager-getPendingBytesCount}.
    function getPendingBytesCount() external view returns (uint64) {
        return LibBlob.getPendingBytesCount();
    }

    /// @dev See {IBlobManager-getStorageUsage}.
    function getStorageUsage(address addr) external view returns (uint256) {
        return LibBlob.getStorageUsage(addr);
    }

    /// @dev See {IBlobManager-getStorageStats}.
    function getStorageStats() external view returns (StorageStats memory stats) {
        return LibBlob.getStorageStats();
    }

    /// @dev See {IBlobManager-getSubnetStats}.
    function getSubnetStats() external view returns (SubnetStats memory stats) {
        return LibBlob.getSubnetStats();
    }

    /// @dev See {IBlobManager-addBlob}.
    function addBlob(AddBlobParams memory params) external {
        LibBlob.addBlob(params);
        emit AddBlob(msg.sender, params.sponsor, params.blobHash, params.subscriptionId);
    }

    /// @dev See {IBlobManager-deleteBlob}.
    function deleteBlob(address subscriber, string memory blobHash, string memory subscriptionId) external {
        LibBlob.deleteBlob(subscriber, blobHash, subscriptionId);
        emit DeleteBlob(msg.sender, subscriber, blobHash, subscriptionId);
    }
}
