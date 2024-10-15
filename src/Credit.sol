// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {ICredit} from "./interfaces/ICredit.sol";
import {
    Account, Balance, CreditApproval, CreditStats, StorageStats, SubnetStats, Usage
} from "./types/CreditTypes.sol";
import {LibCredit} from "./util/LibCredit.sol";

/// @title Credits Contract
/// @dev Implementation of the Hoku Blobs actor EVM interface. See {ICredit} for details.
contract Credit is ICredit {
    using LibCredit for bytes;

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
    function buyCredit() external payable returns (Balance memory balance) {
        emit BuyCredit(msg.sender, msg.value);
        return LibCredit.buyCredit(msg.sender);
    }

    /// @dev See {ICredit-buyCredit}.
    function buyCredit(address recipient) external payable returns (Balance memory balance) {
        emit BuyCredit(recipient, msg.value);
        return LibCredit.buyCredit(recipient);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address receiver) external returns (CreditApproval memory approval) {
        emit ApproveCredit(msg.sender, receiver, address(0), 0, 0);
        return LibCredit.approveCredit(msg.sender, receiver, address(0), 0, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver) external returns (CreditApproval memory approval) {
        emit ApproveCredit(from, receiver, address(0), 0, 0);
        return LibCredit.approveCredit(from, receiver, address(0), 0, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver, address requiredCaller)
        external
        returns (CreditApproval memory approval)
    {
        emit ApproveCredit(from, receiver, requiredCaller, 0, 0);
        return LibCredit.approveCredit(from, receiver, requiredCaller, 0, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver, address requiredCaller, uint256 limit)
        external
        returns (CreditApproval memory approval)
    {
        emit ApproveCredit(from, receiver, requiredCaller, limit, 0);
        return LibCredit.approveCredit(from, receiver, requiredCaller, limit, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver, address requiredCaller, uint256 limit, uint64 ttl)
        external
        returns (CreditApproval memory approval)
    {
        emit ApproveCredit(from, receiver, requiredCaller, limit, ttl);
        return LibCredit.approveCredit(from, receiver, requiredCaller, limit, ttl);
    }

    /// @dev See {ICredit-revokeCredit}.
    function revokeCredit(address receiver) external {
        emit RevokeCredit(msg.sender, receiver, address(0));
        return LibCredit.revokeCredit(msg.sender, receiver, address(0));
    }

    /// @dev See {ICredit-revokeCredit}.
    function revokeCredit(address from, address receiver) external {
        emit RevokeCredit(from, receiver, address(0));
        return LibCredit.revokeCredit(from, receiver, address(0));
    }

    /// @dev See {ICredit-revokeCredit}.
    function revokeCredit(address from, address receiver, address requiredCaller) external {
        emit RevokeCredit(from, receiver, requiredCaller);
        return LibCredit.revokeCredit(from, receiver, requiredCaller);
    }
}
