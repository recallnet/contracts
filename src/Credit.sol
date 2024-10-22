// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ICredit} from "./interfaces/ICredit.sol";
import {
    Account, Balance, CreditApproval, CreditStats, StorageStats, SubnetStats, Usage
} from "./types/CreditTypes.sol";
import {LibCredit} from "./util/LibCredit.sol";

/// @title Credits Contract
/// @dev Implementation of the Hoku Blobs actor EVM interface. See {ICredit} for details.
contract Credit is ICredit {
    /// @dev See {ICredit-getSubnetStats}.
    function getSubnetStats() external view returns (SubnetStats memory stats) {
        return LibCredit.getSubnetStats();
    }

    /// @dev See {ICredit-getAccount}.
    function getAccount(address addr) external view returns (Account memory account) {
        return LibCredit.getAccount(addr);
    }

    /// @dev See {ICredit-getStorageUsage}.
    function getStorageUsage(address addr) external view returns (Usage memory usage) {
        return LibCredit.getStorageUsage(addr);
    }

    /// @dev See {ICredit-getStorageStats}.
    function getStorageStats() external view returns (StorageStats memory stats) {
        return LibCredit.getStorageStats();
    }

    /// @dev See {ICredit-getCreditStats}.
    function getCreditStats() external view returns (CreditStats memory stats) {
        return LibCredit.getCreditStats();
    }

    /// @dev See {ICredit-getCreditBalance}.
    function getCreditBalance(address addr) external view returns (Balance memory balance) {
        return LibCredit.getCreditBalance(addr);
    }

    /// @dev See {ICredit-buyCredit}.
    function buyCredit() external payable {
        LibCredit.buyCredit(msg.sender);
        emit BuyCredit(msg.sender, msg.value);
    }

    /// @dev See {ICredit-buyCredit}.
    function buyCredit(address recipient) external payable {
        LibCredit.buyCredit(recipient);
        emit BuyCredit(recipient, msg.value);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address receiver) external {
        LibCredit.approveCredit(msg.sender, receiver, address(0), 0, 0);
        emit ApproveCredit(msg.sender, receiver, address(0), 0, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver) external {
        LibCredit.approveCredit(from, receiver, address(0), 0, 0);
        emit ApproveCredit(from, receiver, address(0), 0, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver, address requiredCaller) external {
        LibCredit.approveCredit(from, receiver, requiredCaller, 0, 0);
        emit ApproveCredit(from, receiver, requiredCaller, 0, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver, address requiredCaller, uint256 limit) external {
        LibCredit.approveCredit(from, receiver, requiredCaller, limit, 0);
        emit ApproveCredit(from, receiver, requiredCaller, limit, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver, address requiredCaller, uint256 limit, uint64 ttl)
        external
    {
        LibCredit.approveCredit(from, receiver, requiredCaller, limit, ttl);
        emit ApproveCredit(from, receiver, requiredCaller, limit, ttl);
    }

    /// @dev See {ICredit-revokeCredit}.
    function revokeCredit(address receiver) external {
        LibCredit.revokeCredit(msg.sender, receiver, address(0));
        emit RevokeCredit(msg.sender, receiver, address(0));
    }

    /// @dev See {ICredit-revokeCredit}.
    function revokeCredit(address from, address receiver) external {
        LibCredit.revokeCredit(from, receiver, address(0));
        emit RevokeCredit(from, receiver, address(0));
    }

    /// @dev See {ICredit-revokeCredit}.
    function revokeCredit(address from, address receiver, address requiredCaller) external {
        LibCredit.revokeCredit(from, receiver, requiredCaller);
        emit RevokeCredit(from, receiver, requiredCaller);
    }
}
