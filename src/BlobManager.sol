// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {IBlobManager} from "./interfaces/IBlobManager.sol";
import {
    AddBlobParams,
    Blob,
    BlobStatus,
    BlobTuple,
    StorageStats,
    SubnetStats,
    SubscriptionGroup
} from "./types/BlobTypes.sol";
import {LibBlob} from "./util/LibBlob.sol";

contract BlobManager is IBlobManager {
    /// @dev See {ICredit-getBlob}.
    function getBlob(string memory blobHash) external view returns (Blob memory blob) {
        return LibBlob.getBlob(blobHash);
    }

    /// @dev See {ICredit-getBlobStatus}.
    function getBlobStatus(address subscriber, string memory blobHash, string memory subscriptionId)
        external
        view
        returns (BlobStatus status)
    {
        return LibBlob.getBlobStatus(subscriber, blobHash, subscriptionId);
    }

    /// @dev See {ICredit-getPendingBlobs}.
    function getPendingBlobs(uint32 size) external view returns (BlobTuple[] memory blobs) {
        return LibBlob.getPendingBlobs(size);
    }

    /// @dev See {ICredit-getPendingBlobsCount}.
    function getPendingBlobsCount() external view returns (uint64) {
        return LibBlob.getPendingBlobsCount();
    }

    /// @dev See {ICredit-getPendingBytesCount}.
    function getPendingBytesCount() external view returns (uint64) {
        return LibBlob.getPendingBytesCount();
    }

    /// @dev See {ICredit-getStorageUsage}.
    function getStorageUsage(address addr) external view returns (uint256) {
        return LibBlob.getStorageUsage(addr);
    }

    /// @dev See {ICredit-getSubnetStats}.
    function getSubnetStats() external view returns (SubnetStats memory stats) {
        return LibBlob.getSubnetStats();
    }

    /// @dev See {ICredit-getStorageStats}.
    function getStorageStats() external view returns (StorageStats memory stats) {
        return LibBlob.getStorageStats();
    }

    /// @dev See {ICredit-addBlob}.
    function addBlob(AddBlobParams memory params) external {
        LibBlob.addBlob(params);
        emit AddBlob(msg.sender, params.sponsor, params.blobHash, params.subscriptionId);
    }

    /// @dev See {ICredit-deleteBlob}.
    function deleteBlob(address subscriber, string memory blobHash, string memory subscriptionId) external {
        LibBlob.deleteBlob(subscriber, blobHash, subscriptionId);
        emit DeleteBlob(msg.sender, subscriber, blobHash, subscriptionId);
    }
}
