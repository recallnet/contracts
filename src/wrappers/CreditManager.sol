// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {Account, Balance, CreditApproval, CreditStats} from "../types/BlobTypes.sol";
import {LibBlob} from "./LibBlob.sol";

/// @title Credits Contract
/// @dev Implementation of the Recall Blobs actor EVM interface. See {ICredit} for details.
contract CreditManager is ICreditManager {
    /// @dev See {ICreditManager-getAccount}.
    function getAccount(address addr) external view returns (Account memory account) {
        return LibBlob.getAccount(addr);
    }

    /// @dev See {ICreditManager-getCreditStats}.
    function getCreditStats() external view returns (CreditStats memory stats) {
        return LibBlob.getCreditStats();
    }

    /// @dev See {ICreditManager-getCreditApproval}.
    function getCreditApproval(address from, address to) external view returns (CreditApproval memory approval) {
        return LibBlob.getCreditApproval(from, to);
    }

    /// @dev See {ICreditManager-getCreditBalance}.
    function getCreditBalance(address addr) external view returns (Balance memory balance) {
        return LibBlob.getCreditBalance(addr);
    }

    /// @dev See {ICreditManager-approveCredit}.
    function approveCredit(address to) external {
        LibBlob.approveCredit(msg.sender, to, new address[](0), 0, 0, 0);
    }

    /// @dev See {ICreditManager-approveCredit}.
    function approveCredit(address from, address to) external {
        LibBlob.approveCredit(from, to, new address[](0), 0, 0, 0);
    }

    /// @dev See {ICreditManager-approveCredit}.
    function approveCredit(address from, address to, address[] memory caller) external {
        LibBlob.approveCredit(from, to, caller, 0, 0, 0);
    }

    /// @dev See {ICreditManager-approveCredit}.
    function approveCredit(
        address from,
        address to,
        address[] memory caller,
        uint256 creditLimit,
        uint256 gasFeeLimit,
        uint64 ttl
    ) external {
        LibBlob.approveCredit(from, to, caller, creditLimit, gasFeeLimit, ttl);
    }

    /// @dev See {ICreditManager-buyCredit}.
    function buyCredit() external payable {
        LibBlob.buyCredit(msg.sender);
    }

    /// @dev See {ICreditManager-buyCredit}.
    function buyCredit(address recipient) external payable {
        LibBlob.buyCredit(recipient);
    }

    /// @dev See {ICreditManager-revokeCredit}.
    function revokeCredit(address to) external {
        LibBlob.revokeCredit(msg.sender, to, address(0));
    }

    /// @dev See {ICreditManager-revokeCredit}.
    function revokeCredit(address from, address to) external {
        LibBlob.revokeCredit(from, to, address(0));
    }

    /// @dev See {ICreditManager-revokeCredit}.
    function revokeCredit(address from, address to, address caller) external {
        LibBlob.revokeCredit(from, to, caller);
    }

    /// @dev See {ICreditManager-setAccountSponsor}.
    function setAccountSponsor(address from, address sponsor) external {
        LibBlob.setAccountSponsor(from, sponsor);
    }
}
