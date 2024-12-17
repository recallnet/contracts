// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Account, Balance, CreditApproval, CreditStats} from "../types/BlobTypes.sol";

/// @dev Hoku Blobs actor EVM interface for managing and querying information about credit.
/// See Rust implementation for details:
/// https://github.com/hokunet/ipc/blob/develop/fendermint/actors/blobs/src/actor.rs
interface ICreditManager {
    /// @dev Emitted when an account approves credits.
    event ApproveCredit(address indexed from, address indexed to, address[] indexed caller, uint256 limit, uint64 ttl);

    /// @dev Emitted when an account buys credits.
    event BuyCredit(address indexed addr, uint256 amount);

    /// @dev Emitted when an account sets the credit sponsor.
    event SetCreditSponsor(address indexed from, address indexed sponsor);

    /// @dev Emitted when an account revokes credits.
    event RevokeCredit(address indexed from, address indexed to, address indexed caller);

    /// @dev Get the credit account for an address.
    /// @param addr The address of the account.
    /// @return account The credit account for the address.
    function getAccount(address addr) external view returns (Account memory account);

    /// @dev Get the subnet-wide credit statistics.
    /// @return stats The subnet-wide credit statistics.
    function getCreditStats() external view returns (CreditStats memory stats);

    /// @dev Get the credit balance of an account.
    /// @param addr The address of the account.
    /// @return balance The credit balance of the account.
    function getCreditBalance(address addr) external view returns (Balance memory balance);

    /// @dev Approve credits for an account. Assumes `msg.sender` is the owner of the credits, and no optional fields.
    /// @param to The address of the account to approve credits for.
    function approveCredit(address to) external;

    /// @dev Approve credits for an account. This is a simplified variant when no optional fields are needed.
    /// @param from The address of the account that owns the credits.
    /// @param to The address of the account to approve credits for.
    function approveCredit(address from, address to) external;

    /// @dev Approve credits for an account. This is a simplified variant when no optional fields are needed.
    /// @param from The address of the account that owns the credits.
    /// @param to The address of the account to approve credits for.
    /// @param caller Optional restriction on caller address, e.g., an object store. Use zero address if unused.
    function approveCredit(address from, address to, address[] memory caller) external;

    /// @dev Approve credits for an account. This is a simplified variant when no optional fields are needed.
    /// @param from The address of the account that owns the credits.
    /// @param to The address of the account to approve credits for.
    /// @param caller Optional restriction on caller address, e.g., an object store. Use zero address if unused.
    /// @param limit Optional credit approval limit. Use zero if unused, indicating a null value. Use zero if unused,
    function approveCredit(address from, address to, address[] memory caller, uint256 limit) external;

    /// @dev Approve credits for an account. This is a simplified variant when no optional fields are needed.
    /// @param from The address of the account that owns the credits.
    /// @param to The address of the account to approve credits for.
    /// @param caller Optional restriction on caller address, e.g., an object store. Use zero address if unused.
    /// @param limit Optional credit approval limit. Use zero if unused, indicating a null value.
    /// @param ttl Optional credit approval time-to-live epochs. Minimum value is 3600 (1 hour). Use zero if
    /// unused, indicating a null value.
    function approveCredit(address from, address to, address[] memory caller, uint256 limit, uint64 ttl) external;

    /// @dev Buy credits for `msg.sender` with a `msg.value` for number of native currency to spend on credits.
    function buyCredit() external payable;

    /// @dev Buy credits for a specified account with a `msg.value` for number of native currency to spend on credits.
    /// @param recipient The address of the account.
    function buyCredit(address recipient) external payable;

    /// @dev Set the credit sponsor for an account.
    /// @param from The address of the account.
    /// @param sponsor The address of the sponsor. Use zero address if unused.
    function setCreditSponsor(address from, address sponsor) external;

    /// @dev Revoke credits for an account. Assumes `msg.sender` is the owner of the credits.
    /// @param to The address of the account to revoke credits for.
    function revokeCredit(address to) external;

    /// @dev Revoke credits for an account.
    /// @param from The address of the account that owns the credits.
    /// @param to The address of the account to revoke credits for.
    function revokeCredit(address from, address to) external;

    /// @dev Revoke credits for an account. Includes optional fields, which if set to zero, will be encoded as null.
    /// @param from The address of the account that owns the credits.
    /// @param to The address of the account to revoke credits for.
    /// @param caller Optional restriction on caller address, e.g., an object store.
    function revokeCredit(address from, address to, address caller) external;
}
