// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {Account, Balance, CreditApproval, CreditStats} from "../types/BlobTypes.sol";
import {LibBlob} from "./LibBlob.sol";

/// @title Credits Contract
/// @dev Implementation of the Hoku Blobs actor EVM interface. See {ICredit} for details.
contract CreditManager is ICreditManager {
    /// @dev See {ICreditManager-getAccount}.
    function getAccount(address addr) external view returns (Account memory account) {
        return LibBlob.getAccount(addr);
    }

    /// @dev See {ICreditManager-getCreditStats}.
    function getCreditStats() external view returns (CreditStats memory stats) {
        return LibBlob.getCreditStats();
    }

    /// @dev See {ICreditManager-getCreditBalance}.
    function getCreditBalance(address addr) external view returns (Balance memory balance) {
        return LibBlob.getCreditBalance(addr);
    }

    /// @dev See {ICreditManager-approveCredit}.
    function approveCredit(address to) external {
        LibBlob.approveCredit(msg.sender, to, new address[](0), 0, 0);
        emit ApproveCredit(msg.sender, to, new address[](0), 0, 0);
    }

    /// @dev See {ICreditManager-approveCredit}.
    function approveCredit(address from, address to) external {
        LibBlob.approveCredit(from, to, new address[](0), 0, 0);
        emit ApproveCredit(from, to, new address[](0), 0, 0);
    }

    /// @dev See {ICreditManager-approveCredit}.
    function approveCredit(address from, address to, address[] memory caller) external {
        LibBlob.approveCredit(from, to, caller, 0, 0);
        emit ApproveCredit(from, to, caller, 0, 0);
    }

    /// @dev See {ICreditManager-approveCredit}.
    function approveCredit(address from, address to, address[] memory caller, uint256 limit) external {
        LibBlob.approveCredit(from, to, caller, limit, 0);
        emit ApproveCredit(from, to, caller, limit, 0);
    }

    /// @dev See {ICreditManager-approveCredit}.
    function approveCredit(address from, address to, address[] memory caller, uint256 limit, uint64 ttl) external {
        LibBlob.approveCredit(from, to, caller, limit, ttl);
        emit ApproveCredit(from, to, caller, limit, ttl);
    }

    /// @dev See {ICreditManager-buyCredit}.
    function buyCredit() external payable {
        LibBlob.buyCredit(msg.sender);
        emit BuyCredit(msg.sender, msg.value);
    }

    /// @dev See {ICreditManager-buyCredit}.
    function buyCredit(address recipient) external payable {
        LibBlob.buyCredit(recipient);
        emit BuyCredit(recipient, msg.value);
    }

    /// @dev See {ICreditManager-setCreditSponsor}.
    function setCreditSponsor(address from, address sponsor) external {
        LibBlob.setCreditSponsor(from, sponsor);
        emit SetCreditSponsor(from, sponsor);
    }

    /// @dev See {ICreditManager-revokeCredit}.
    function revokeCredit(address to) external {
        LibBlob.revokeCredit(msg.sender, to, address(0));
        emit RevokeCredit(msg.sender, to, address(0));
    }

    /// @dev See {ICreditManager-revokeCredit}.
    function revokeCredit(address from, address to) external {
        LibBlob.revokeCredit(from, to, address(0));
        emit RevokeCredit(from, to, address(0));
    }

    /// @dev See {ICreditManager-revokeCredit}.
    function revokeCredit(address from, address to, address caller) external {
        LibBlob.revokeCredit(from, to, caller);
        emit RevokeCredit(from, to, caller);
    }
}
