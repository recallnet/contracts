// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {
    Account, Balance, CreditApproval, CreditStats, StorageStats, SubnetStats, Usage
} from "../types/CreditTypes.sol";

/// @dev Hoku Blobs actor EVM interface for managing credits, and querying credit or storage stats.
/// See Rust implementation for details:
/// https://github.com/hokunet/ipc/blob/develop/fendermint/actors/blobs/src/actor.rs
interface ICredit {
    /// @dev Emitted when an account buys credits.
    event BuyCredit(address indexed addr, uint256 amount);

    /// @dev Emitted when an account approves credits.
    event ApproveCredit(
        address indexed from, address indexed receiver, address indexed requiredCaller, uint256 limit, uint64 ttl
    );

    /// @dev Emitted when an account revokes credits.
    event RevokeCredit(address indexed from, address indexed receiver, address indexed requiredCaller);

    /// @dev Get the subnet stats.
    /// @return stats The subnet stats.
    function getSubnetStats() external view returns (SubnetStats memory stats);

    /// @dev Get the credit account for an address.
    /// @param addr The address of the account.
    /// @return account The credit account for the address.
    function getAccount(address addr) external view returns (Account memory account);

    /// @dev Get the storage usage for an account.
    /// @param addr The address of the account.
    /// @return usage The storage usage for the account.
    function getStorageUsage(address addr) external view returns (Usage memory usage);

    /// @dev Get the storage stats for the subnet.
    /// @return stats The storage stats for the subnet.
    function getStorageStats() external view returns (StorageStats memory stats);

    /// @dev Get the subnet-wide credit statistics.
    /// @return stats The subnet-wide credit statistics.
    function getCreditStats() external view returns (CreditStats memory stats);

    /// @dev Get the credit balance of an account.
    /// @param addr The address of the account.
    /// @return balance The credit balance of the account.
    function getCreditBalance(address addr) external view returns (Balance memory balance);

    /// @dev Buy credits for `msg.sender` with a `msg.value` for number of native currency to spend on credits.
    function buyCredit() external payable;

    /// @dev Buy credits for a specified account with a `msg.value` for number of native currency to spend on credits.
    /// @param recipient The address of the account.
    function buyCredit(address recipient) external payable;

    /// @dev Approve credits for an account. Assumes `msg.sender` is the owner of the credits, and no optional fields.
    /// @param receiver The address of the account to approve credits for.
    function approveCredit(address receiver) external;

    /// @dev Approve credits for an account. This is a simplified variant when no optional fields are needed.
    /// @param from The address of the account that owns the credits.
    /// @param receiver The address of the account to approve credits for.
    function approveCredit(address from, address receiver) external;

    /// @dev Approve credits for an account. This is a simplified variant when no optional fields are needed.
    /// @param from The address of the account that owns the credits.
    /// @param receiver The address of the account to approve credits for.
    /// @param requiredCaller Optional restriction on caller address, e.g., an object store. Use zero address if unused.
    function approveCredit(address from, address receiver, address requiredCaller) external;

    /// @dev Approve credits for an account. This is a simplified variant when no optional fields are needed.
    /// @param from The address of the account that owns the credits.
    /// @param receiver The address of the account to approve credits for.
    /// @param requiredCaller Optional restriction on caller address, e.g., an object store. Use zero address if unused.
    /// @param limit Optional credit approval limit. Use zero if unused, indicating a null value. Use zero if unused,
    function approveCredit(address from, address receiver, address requiredCaller, uint256 limit) external;

    /// @dev Approve credits for an account. This is a simplified variant when no optional fields are needed.
    /// @param from The address of the account that owns the credits.
    /// @param receiver The address of the account to approve credits for.
    /// @param requiredCaller Optional restriction on caller address, e.g., an object store. Use zero address if unused.
    /// @param limit Optional credit approval limit. Use zero if unused, indicating a null value.
    /// @param ttl Optional credit approval time-to-live epochs. Minimum value is 3600 (1 hour). Use zero if
    /// unused, indicating a null value.
    function approveCredit(address from, address receiver, address requiredCaller, uint256 limit, uint64 ttl)
        external;

    /// @dev Revoke credits for an account. Assumes `msg.sender` is the owner of the credits.
    /// @param receiver The address of the account to revoke credits for.
    function revokeCredit(address receiver) external;

    /// @dev Revoke credits for an account.
    /// @param from The address of the account that owns the credits.
    /// @param receiver The address of the account to revoke credits for.
    function revokeCredit(address from, address receiver) external;

    /// @dev Revoke credits for an account. Includes optional fields, which if set to zero, will be encoded as null.
    /// @param from The address of the account that owns the credits.
    /// @param receiver The address of the account to revoke credits for.
    /// @param requiredCaller Optional restriction on caller address, e.g., an object store.
    function revokeCredit(address from, address receiver, address requiredCaller) external;
}
