// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Account, Balance, CreditApproval, CreditStats, StorageStats, SubnetStats, Usage} from "../util/Types.sol";

/// @dev Hoku Blobs actor EVM interface for managing credits, and querying credit or storage stats.
/// See Rust implementation for details: https://github.com/hokunet/ipc/blob/develop/fendermint/actors/blobs/src/actor.rs
interface ICredits {
    /// @dev Emitted when an account buys credits.
    event BuyCredit(address indexed addr, uint256 amount);

    /// @dev Emitted when an account approves credits.
    event ApproveCredit(address indexed owner, address indexed receiver);

    /// @dev Emitted when an account revokes credits.
    event RevokeCredit(address indexed owner, address indexed receiver);

    /// @dev Get the subnet stats.
    /// @return stats The subnet stats.
    function getSubnetStats() external view returns (SubnetStats memory stats);

    /// @dev Get the credit account for an address.
    /// @param addr The address of the account.
    /// @return account The credit account for the address.
    function getAccount(
        address addr
    ) external view returns (Account memory account);

    /// @dev Get the storage usage for an account.
    /// @param addr The address of the account.
    /// @return usage The storage usage for the account.
    function getStorageUsage(
        address addr
    ) external view returns (Usage memory usage);

    /// @dev Get the storage stats for the subnet.
    /// @return stats The storage stats for the subnet.
    function getStorageStats()
        external
        view
        returns (StorageStats memory stats);

    /// @dev Get the subnet-wide credit statistics.
    /// @return stats The subnet-wide credit statistics.
    function getCreditStats() external view returns (CreditStats memory stats);

    /// @dev Get the credit balance of an account.
    /// @param addr The address of the account.
    /// @return balance The credit balance of the account.
    function getCreditBalance(
        address addr
    ) external view returns (Balance memory balance);

    /// @dev Buy credits for an account with a `msg.value` for number of native currency to spend on credits.
    /// @param addr The address of the account.
    /// @return balance The balance of the account after buying credits.
    function buyCredit(
        address addr
    ) external payable returns (Balance memory balance);

    /// @dev Approve credits for an account.
    /// @param receiver The address of the account to approve credits for.
    /// @return approval The credit approval response.
    function approveCredit(
        address receiver
    ) external returns (CreditApproval memory approval);

    /// @dev Revoke credits for an account.
    /// @param receiver The address of the account to revoke credits for.
    function revokeCredit(address receiver) external;
}
