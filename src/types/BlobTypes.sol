// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

/// @dev The stored representation of a credit account.
/// @param capacityUsed (uint256): Total size of all blobs managed by the account.
/// @param creditFree (uint256): Current free credit in byte-blocks that can be used for new commitments.
/// @param creditCommitted (uint256): Current committed credit in byte-blocks that will be used for debits.
/// @param lastDebitEpoch (uint64): The chain epoch of the last debit.
/// @param approvals (Approvals[]): Credit approvals to other accounts, keyed by receiver, keyed by caller.
struct Account {
    uint256 capacityUsed;
    uint256 creditFree;
    uint256 creditCommitted;
    uint64 lastDebitEpoch;
    // Note: this is a nested array that emulates a Rust `Hashmap<Address, Hashmap<Address, CreditApproval>>`
    Approvals[] approvals;
}

/// @dev Credit approvals to other accounts, keyed by receiver, keyed by caller.
/// @param receiver (address): The receiver address.
/// @param approval (Approval[]): The list of approvals. See {Approval} for more details.
struct Approvals {
    address receiver;
    Approval[] approval;
}

/// @dev Credit approval from one account to another.
/// @param requiredCaller (address): Optional restriction on caller address, e.g., an object store. Use zero address if
/// unused, indicating a null value.
/// @param approval (CreditApproval): The credit approval. See {CreditApproval} for more details.
struct Approval {
    address requiredCaller;
    CreditApproval approval;
}

/// @dev Credit balance for an account.
/// @param creditFree (uint256): Current free credit in byte-blocks that can be used for new commitments.
/// @param creditCommitted (uint256): Current committed credit in byte-blocks that will be used for debits.
/// @param lastDebitEpoch (uint64): The chain epoch of the last debit.
struct Balance {
    uint256 creditFree;
    uint256 creditCommitted;
    uint64 lastDebitEpoch;
}

/// @dev A credit approval from one account to another.
/// @param limit (uint256): Optional credit approval limit.
/// @param expiry (uint64): Optional credit approval time-to-live epochs.
/// @param used (uint256): Counter for how much credit has been committed via this approval.
struct CreditApproval {
    uint256 limit;
    uint64 expiry;
    uint256 used;
}

/// @dev The stats of the blob actor.
/// This is the return type for the blobs actor `get_stats` method:
/// - The `balance` is a uint256, encoded as a CBOR byte string (e.g., 0x00010f0cf064dd59200000).
/// - The `capacityTotal`, `capacityUsed`, `creditSold`, `creditCommitted`, and `creditDebited` are
/// WASM BigInt types: a CBOR array with a sign (assume non-negative) and array of numbers (e.g., 0x8201820001).
/// - The `creditDebitRate`, `numAccounts`, `numBlobs`, and `numResolving` are uint64, encoded as a
/// CBOR byte string (e.g., 0x317).
/// @param balance (uint256): The current token balance earned by the subnet.
/// @param capacityTotal (uint256): The total free storage capacity of the subnet.
/// @param capacityUsed (uint256): The total used storage capacity of the subnet.
/// @param creditSold (uint256): The total number of credits sold in the subnet.
/// @param creditCommitted (uint256): The total number of credits committed to active storage in the subnet.
/// @param creditDebited (uint256): The total number of credits debited in the subnet.
/// @param creditDebitRate (uint64): The byte-blocks per atto token rate set at genesis.
/// @param numAccounts (uint64): Total number of debit accounts.
/// @param numBlobs (uint64): Total number of actively stored blobs.
struct SubnetStats {
    uint256 balance;
    uint256 capacityTotal;
    uint256 capacityUsed;
    uint256 creditSold;
    uint256 creditCommitted;
    uint256 creditDebited;
    uint64 creditDebitRate;
    uint64 numAccounts;
    uint64 numBlobs;
    uint64 numResolving;
}

/// @dev Subnet-wide credit statistics.
/// @param balance (uint256): The current token balance earned by the subnet.
/// @param creditSold (uint256): The total number of credits sold in the subnet.
/// @param creditCommitted (uint256): The total number of credits committed to active storage in the subnet.
/// @param creditDebited (uint256): The total number of credits debited in the subnet.
/// @param creditDebitRate (uint64): The byte-blocks per atto token rate set at genesis.
/// @param numAccounts (uint64): Total number of debit accounts.
struct CreditStats {
    uint256 balance;
    uint256 creditSold;
    uint256 creditCommitted;
    uint256 creditDebited;
    uint64 creditDebitRate;
    uint64 numAccounts;
}

/// @dev Subnet-wide storage statistics.
/// @param capacityTotal (uint256): The total free storage capacity of the subnet.
/// @param capacityUsed (uint256): The total used storage capacity of the subnet.
/// @param numBlobs (uint64): Total number of actively stored blobs.
/// @param numResolving (uint64): Total number of currently resolving blobs.
struct StorageStats {
    uint256 capacityTotal;
    uint256 capacityUsed;
    uint64 numBlobs;
    uint64 numResolving;
}

/// @dev Parameters for adding a raw blob.
/// @param sponsor  Optional sponsor address.
/// @param source Source Iroh node ID used for ingestion.
/// @param blobHash Blob blake3 hash.
/// @param metadataHash  Blake3 hash of the metadata to use for blob recovery.
/// @param subscriptionId Identifier used to differentiate blob additions for the same subscriber.
/// @param size Blob size.
/// @param ttl Blob time-to-live epochs. If not specified, the auto-debitor maintains about one hour of credits as an
/// ongoing commitment.
struct AddBlobParams {
    address sponsor;
    string source;
    string blobHash;
    string metadataHash;
    string subscriptionId;
    uint64 size;
    uint64 ttl;
}

/// @dev Blob information and status.
/// @param size (uint64): The size of the blob content in bytes.
/// @param metadataHash (string): Blob metadata hash that contains information for block recovery.
/// @param subscribers (bytes): Active subscribers (accounts) that are paying for the blob, encoded as HashMap<Address,
/// SubscriptionGroup>.
/// @param status (bytes): Current status of the blob.
struct Blob {
    uint64 size;
    string metadataHash;
    // TODO: decode the following from Rust type: HashMap<Address, SubscriptionGroup>
    bytes subscribers;
    BlobStatus status;
}

/// @dev Status of a blob in the system.
/// @param Pending Blob is pending resolve.
/// @param Resolved Blob was successfully resolved.
/// @param Failed Blob resolution failed.
enum BlobStatus {
    Pending,
    Resolved,
    Failed
}

/// @dev Pending subscription information.
/// @param subscriber (address): The subscriber address.
/// @param subscriptionId (string): The subscription ID.
/// @param publicKey (bytes): The public key.
struct Subscription {
    address subscriber;
    string subscriptionId;
    bytes publicKey;
}

/// @dev Pending blob information. Represents a Rust `(Hash, HashSet<(Address, SubscriptionId, PublicKey)>)`
/// @param hash (bytes): The blob hash.
/// @param subscriptions (Subscription[]): The pending subscriptions.
struct PendingBlob {
    bytes hash;
    Subscription[] subscriptions;
}
