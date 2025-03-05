// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

interface ICreditFacade {
    /// @dev Emitted when credit is purchased.
    /// @param from Credit purchaser.
    /// @param amount Credit purchased amount.
    event CreditPurchased(address from, uint256 amount);

    /// @dev Emitted when credit is approved from one account to another.
    /// @param from Approval from address.
    /// @param to Approval to address.
    /// @param creditLimit Approval credit limit (0 means no limit).
    /// @param gasFeeLimit Approval gas fee limit (0 means no limit).
    /// @param expiry Approval expiry epoch.
    event CreditApproved(address from, address to, uint256 creditLimit, uint256 gasFeeLimit, uint256 expiry);

    /// @dev Emitted when credit is revoked from one account to another.
    /// @param from Approval from address.
    /// @param to Approval to address.
    event CreditRevoked(address from, address to);

    /// @dev Emitted when the system actor debits credit from accounts.
    /// @param amount Total amount of credit debited from accounts.
    /// @param numAccounts Number of accounts debited.
    /// @param moreAccounts Whether there are more accounts to debit for the current billing cycle.
    event CreditDebited(uint256 amount, uint256 numAccounts, bool moreAccounts);

    /// @dev Set the credit sponsor for an account.
    /// @param from The address of the account.
    /// @param sponsor The address of the sponsor. Use zero address if unused.
    function setAccountSponsor(address from, address sponsor) external;
}
