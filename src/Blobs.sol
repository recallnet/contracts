// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {IBlobs} from "./interfaces/IBlobs.sol";
import {AddBlobParams, StorageStats, SubnetStats} from "./types/BlobsTypes.sol";
import {LibBlobs} from "./util/LibBlobs.sol";

contract Blobs is IBlobs {
    /// @dev See {ICredit-getBlob}.
    function getBlob(string memory blobHash) external view returns (bytes memory) {
        return LibBlobs.getBlob(blobHash);
    }

    /// @dev See {ICredit-getBlobStatus}.
    function getBlobStatus(address subscriber, string memory blobHash, string memory subscriptionId)
        external
        view
        returns (bytes memory)
    {
        return LibBlobs.getBlobStatus(subscriber, blobHash, subscriptionId);
    }

    /// @dev See {ICredit-getPendingBlobs}.
    function getPendingBlobs(uint32 size) external view returns (bytes memory) {
        return LibBlobs.getPendingBlobs(size);
    }

    /// @dev See {ICredit-getPendingBlobsCount}.
    function getPendingBlobsCount() external view returns (uint64) {
        return LibBlobs.getPendingBlobsCount();
    }

    /// @dev See {ICredit-getPendingBytesCount}.
    function getPendingBytesCount() external view returns (uint64) {
        return LibBlobs.getPendingBytesCount();
    }

    /// @dev See {ICredit-getStorageUsage}.
    function getStorageUsage(address addr) external view returns (uint256) {
        return LibBlobs.getStorageUsage(addr);
    }

    /// @dev See {ICredit-getSubnetStats}.
    function getSubnetStats() external view returns (SubnetStats memory stats) {
        return LibBlobs.getSubnetStats();
    }

    /// @dev See {ICredit-getStorageStats}.
    function getStorageStats() external view returns (StorageStats memory stats) {
        return LibBlobs.getStorageStats();
    }

    /// @dev See {ICredit-addBlob}.
    function addBlob(AddBlobParams memory params) external {
        LibBlobs.addBlob(params);
        emit AddBlob(msg.sender, params.sponsor, params.blobHash, params.subscriptionId);
    }

    /// @dev See {ICredit-deleteBlob}.
    function deleteBlob(address subscriber, string memory blobHash, string memory subscriptionId) external {
        LibBlobs.deleteBlob(subscriber, blobHash, subscriptionId);
        emit DeleteBlob(msg.sender, subscriber, blobHash, subscriptionId);
    }
}
