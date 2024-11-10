// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {ICreditManager} from "./interfaces/ICreditManager.sol";
import {Account, Balance, CreditApproval, CreditStats} from "./types/BlobTypes.sol";
import {LibBlob} from "./util/LibBlob.sol";

/// @title Credits Contract
/// @dev Implementation of the Hoku Blobs actor EVM interface. See {ICredit} for details.
contract CreditManager is ICreditManager {
    /// @dev See {ICredit-getAccount}.
    function getAccount(address addr) external view returns (Account memory account) {
        return LibBlob.getAccount(addr);
    }

    /// @dev See {ICredit-getCreditStats}.
    function getCreditStats() external view returns (CreditStats memory stats) {
        return LibBlob.getCreditStats();
    }

    /// @dev See {ICredit-getCreditBalance}.
    function getCreditBalance(address addr) external view returns (Balance memory balance) {
        return LibBlob.getCreditBalance(addr);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address receiver) external {
        LibBlob.approveCredit(msg.sender, receiver, address(0), 0, 0);
        emit ApproveCredit(msg.sender, receiver, address(0), 0, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver) external {
        LibBlob.approveCredit(from, receiver, address(0), 0, 0);
        emit ApproveCredit(from, receiver, address(0), 0, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver, address requiredCaller) external {
        LibBlob.approveCredit(from, receiver, requiredCaller, 0, 0);
        emit ApproveCredit(from, receiver, requiredCaller, 0, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver, address requiredCaller, uint256 limit) external {
        LibBlob.approveCredit(from, receiver, requiredCaller, limit, 0);
        emit ApproveCredit(from, receiver, requiredCaller, limit, 0);
    }

    /// @dev See {ICredit-approveCredit}.
    function approveCredit(address from, address receiver, address requiredCaller, uint256 limit, uint64 ttl)
        external
    {
        LibBlob.approveCredit(from, receiver, requiredCaller, limit, ttl);
        emit ApproveCredit(from, receiver, requiredCaller, limit, ttl);
    }

    /// @dev See {ICredit-buyCredit}.
    function buyCredit() external payable {
        LibBlob.buyCredit(msg.sender);
        emit BuyCredit(msg.sender, msg.value);
    }

    /// @dev See {ICredit-buyCredit}.
    function buyCredit(address recipient) external payable {
        LibBlob.buyCredit(recipient);
        emit BuyCredit(recipient, msg.value);
    }

    /// @dev See {ICredit-revokeCredit}.
    function revokeCredit(address receiver) external {
        LibBlob.revokeCredit(msg.sender, receiver, address(0));
        emit RevokeCredit(msg.sender, receiver, address(0));
    }

    /// @dev See {ICredit-revokeCredit}.
    function revokeCredit(address from, address receiver) external {
        LibBlob.revokeCredit(from, receiver, address(0));
        emit RevokeCredit(from, receiver, address(0));
    }

    /// @dev See {ICredit-revokeCredit}.
    function revokeCredit(address from, address receiver, address requiredCaller) external {
        LibBlob.revokeCredit(from, receiver, requiredCaller);
        emit RevokeCredit(from, receiver, requiredCaller);
    }
}
