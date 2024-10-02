// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

/// @dev Environment helper for setting the chain environment in scripts or contracts.
/// - Local: Local (localnet or devnet)
/// - Testnet: Testnet environment
/// - Mainnet: Mainnet environment
enum Environment {
    Local,
    Testnet,
    Mainnet
}

/// @dev The stored representation of a credit account.
struct Account {
    /// Total size of all blobs managed by the account.
    uint256 capacityUsed;
    /// Current free credit in byte-blocks that can be used for new commitments.
    uint256 creditFree;
    /// Current committed credit in byte-blocks that will be used for debits.
    uint256 creditCommitted;
    /// The chain epoch of the last debit.
    uint64 lastDebitEpoch;
    /// Credit approvals to other accounts, keyed by receiver, keyed by caller
    // TODO: implement from hashmap: HashMap<Address, HashMap<Address, CreditApproval>>
    // mapping(address => mapping(address => uint256)) public approvals;
    uint64 approvals;
}

/// @dev Credit ba`lance for an account.
struct Balance {
    /// Current free credit in byte-blocks that can be used for new commitments.
    uint256 creditFree;
    /// Current committed credit in byte-blocks that will be used for debits.
    uint256 creditCommitted;
    /// The chain epoch of the last debit.
    uint64 lastDebitEpoch;
}

/// @dev Params for revoking credit.
struct RevokeCreditParams {
    /// Account address that is receiving the approval.
    address receiver;
    /// Optional restriction on caller address, e.g., an object store.
    /// This allows the origin of a transaction to use an approval limited to the caller.
    address requiredCaller;
}

/// @dev Params for approving credit.
struct ApproveCreditParams {
    /// Account address that is receiving the approval.
    address receiver;
    /// Optional restriction on caller address, e.g., an object store.
    /// The receiver will only be able to use the approval via a caller contract.
    address requiredCaller;
    /// Optional credit approval limit.
    /// If specified, the approval becomes invalid once the committed credits reach the
    /// specified limit.
    uint256 limit;
    /// Optional credit approval time-to-live epochs.
    /// If specified, the approval becomes invalid after this duration.
    uint64 ttl;
}

/// @dev A credit approval from one account to another.
struct CreditApproval {
    /// Optional credit approval limit.
    uint256 limit;
    /// Optional credit approval expiry epoch.
    uint64 expiry;
    /// Counter for how much credit has been committed via this approval.
    uint256 committed;
}

/// @dev The stats of the blob actor.
/// This is the return type for the blobs actor `get_stats` method:
/// - The `balance` is a uint256, encoded as a CBOR byte string (e.g., 0x00010f0cf064dd59200000).
/// - The `capacityFree`, `capacityUsed`, `creditSold`, `creditCommitted`, and `creditDebited` are
/// WASM BigInt types: a CBOR array with a sign (assume non-negative) and array of numbers (e.g., 0x8201820001).
/// - The `creditDebitRate`, `numAccounts`, `numBlobs`, and `numResolving` are uint64, encoded as a
/// CBOR byte string (e.g., 0x317).
struct SubnetStats {
    /// The current token balance earned by the subnet.
    uint256 balance;
    /// The total free storage capacity of the subnet.
    uint256 capacityFree;
    /// The total used storage capacity of the subnet.
    uint256 capacityUsed;
    /// The total number of credits sold in the subnet.
    uint256 creditSold;
    /// The total number of credits committed to active storage in the subnet.
    uint256 creditCommitted;
    /// The total number of credits debited in the subnet.
    uint256 creditDebited;
    /// The byte-blocks per atto token rate set at genesis.
    uint64 creditDebitRate;
    /// Total number of debit accounts.
    uint64 numAccounts;
    /// Total number of actively stored blobs.
    uint64 numBlobs;
    /// Total number of currently resolving blobs.
    uint64 numResolving;
}

/// @dev Subnet-wide credit statistics.
struct CreditStats {
    /// The current token balance earned by the subnet.
    uint256 balance;
    /// The total number of credits sold in the subnet.
    uint256 creditSold;
    /// The total number of credits committed to active storage in the subnet.
    uint256 creditCommitted;
    /// The total number of credits debited in the subnet.
    uint256 creditDebited;
    /// The byte-blocks per atto token rate set at genesis.
    uint64 creditDebitRate;
    /// Total number of debit accounts.
    uint64 numAccounts;
}

/// @dev Subnet-wide storage statistics.
struct StorageStats {
    /// The total free storage capacity of the subnet.
    uint256 capacityFree;
    /// The total used storage capacity of the subnet.
    uint256 capacityUsed;
    /// Total number of actively stored blobs.
    uint64 numBlobs;
    /// Total number of currently resolving blobs.
    uint64 numResolving;
}

/// @dev Storage usage stats for an account.
struct Usage {
    /// Total size of all blobs managed by the account.
    uint256 capacityUsed;
}
