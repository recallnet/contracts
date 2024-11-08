// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {ICredit} from "./interfaces/ICredit.sol";
import {
    Account, Balance, CreditApproval, CreditStats, StorageStats, SubnetStats, Usage
} from "./types/CreditTypes.sol";
import {LibBlobs} from "./util/LibBlobs.sol";

/// @title Credits Contract
/// @dev Implementation of the Hoku Blobs actor EVM interface. See {ICredit} for details.
contract Credit is ICredit {
    /// @dev See {ICredit-getSubnetStats}.
    function getSubnetStats() external view returns (SubnetStats memory stats) {
        return LibBlobs.getSubnetStats();
    }

    /// @dev See {ICredit-getAccount}.
    function getAccount(address addr) external view returns (Account memory account) {
        return LibBlobs.getAccount(addr);
    }

    /// @dev See {ICredit-getStorageUsage}.
    function getStorageUsage(address addr) external view returns (Usage memory usage) {
        return LibBlobs.getStorageUsage(addr);
    }

    /// @dev See {ICredit-getStorageStats}.
    function getStorageStats() external view returns (StorageStats memory stats) {
        return LibBlobs.getStorageStats();
    }

    /// @dev See {ICredit-getCreditStats}.
    function getCreditStats() external view returns (CreditStats memory stats) {
        return LibBlobs.getCreditStats();
    }

    /// @dev See {ICredit-getCreditBalance}.
    function getCreditBalance(address addr) external view returns (Balance memory balance) {
        return LibBlobs.getCreditBalance(addr);
    }

    /// @dev See {ICredit-buyCredit}.
    function buyCredit() external payable {
        LibBlobs.buyCredit(msg.sender);
        emit BuyCredit(msg.sender, msg.value);
    }

    /// @dev See {ICredit-buyCredit}.
    function buyCredit(address recipient) external payable {
        LibBlobs.buyCredit(recipient);
        emit BuyCredit(recipient, msg.value);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address receiver) external {
        LibBlobs.approveCredit(msg.sender, receiver, address(0), 0, 0);
        emit ApproveCredit(msg.sender, receiver, address(0), 0, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver) external {
        LibBlobs.approveCredit(from, receiver, address(0), 0, 0);
        emit ApproveCredit(from, receiver, address(0), 0, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver, address requiredCaller) external {
        LibBlobs.approveCredit(from, receiver, requiredCaller, 0, 0);
        emit ApproveCredit(from, receiver, requiredCaller, 0, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver, address requiredCaller, uint256 limit) external {
        LibBlobs.approveCredit(from, receiver, requiredCaller, limit, 0);
        emit ApproveCredit(from, receiver, requiredCaller, limit, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver, address requiredCaller, uint256 limit, uint64 ttl)
        external
    {
        LibBlobs.approveCredit(from, receiver, requiredCaller, limit, ttl);
        emit ApproveCredit(from, receiver, requiredCaller, limit, ttl);
    }

    /// @dev See {ICredit-revokeCredit}.
    function revokeCredit(address receiver) external {
        LibBlobs.revokeCredit(msg.sender, receiver, address(0));
        emit RevokeCredit(msg.sender, receiver, address(0));
    }

    /// @dev See {ICredit-revokeCredit}.
    function revokeCredit(address from, address receiver) external {
        LibBlobs.revokeCredit(from, receiver, address(0));
        emit RevokeCredit(from, receiver, address(0));
    }

    /// @dev See {ICredit-revokeCredit}.
    function revokeCredit(address from, address receiver, address requiredCaller) external {
        LibBlobs.revokeCredit(from, receiver, requiredCaller);
        emit RevokeCredit(from, receiver, requiredCaller);
    }
}
