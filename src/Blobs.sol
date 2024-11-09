// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {IBlobs} from "./interfaces/IBlobs.sol";
import {AddBlobParams} from "./types/CreditTypes.sol";
import {LibBlobs} from "./util/LibBlobs.sol";

contract Blobs is IBlobs {
    function addBlob(AddBlobParams memory params) external {
        LibBlobs.addBlob(params);
    }

    function deleteBlob(address subscriber, string memory blobHash, string memory subscriptionId) external {
        LibBlobs.deleteBlob(subscriber, blobHash, subscriptionId);
    }

    function getBlob(string memory blobHash) external view returns (bytes memory) {
        return LibBlobs.getBlob(blobHash);
    }

    function getBlobStatus(address subscriber, string memory blobHash, string memory subscriptionId)
        external
        view
        returns (bytes memory)
    {
        return LibBlobs.getBlobStatus(subscriber, blobHash, subscriptionId);
    }

    function getPendingBlobs(uint32 number) external view returns (bytes memory) {
        return LibBlobs.getPendingBlobs(number);
    }

    function getPendingBlobsCount() external view returns (uint64) {
        return LibBlobs.getPendingBlobsCount();
    }

    function getPendingBytesCount() external view returns (uint64) {
        return LibBlobs.getPendingBytesCount();
    }
}
