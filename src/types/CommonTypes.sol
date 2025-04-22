// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

/// @dev A key-value pair.
/// @param key (string): The key.
/// @param value (string): The value.
struct KeyValue {
    string key;
    string value;
}

/// @dev The corresponding implementation of Fil Address from FVM.
/// @param addrType (uint8): The address type.
/// @param payload (bytes): The address payload.
/// Currently it supports only f1 addresses.
/// See:
/// https://github.com/filecoin-project/ref-fvm/blob/db8c0b12c801f364e87bda6f52d00c6bd0e1b878/shared/src/address/payload.rs#L87
struct FvmAddress {
    uint8 addrType;
    bytes payload;
}

/// @dev The delegated f4 address in Fil Address from FVM.
/// @param namespace (uint64): The namespace.
/// @param length (uint128): The length.
/// @param buffer (bytes): The buffer.
struct DelegatedAddress {
    uint64 namespace;
    uint128 length;
    bytes buffer;
}

/// @dev A subnet identity type.
/// @param root (uint64): The root chainID.
/// @param route (address[]): The path of subnet contracts.
struct SubnetID {
    uint64 root;
    address[] route;
}

/// @notice The parent finality for IPC parent at certain height.
struct ParentFinality {
    uint256 height;
    bytes32 blockHash;
}

/// @notice A bottom-up checkpoint type.
struct BottomUpCheckpoint {
    /// @dev Child subnet ID, for replay protection from other subnets where the exact same validators operate.
    /// Alternatively it can be appended to the hash before signing, similar to how we use the chain ID.
    SubnetID subnetID;
    /// @dev The height of the child subnet at which this checkpoint was cut.
    /// Has to follow the previous checkpoint by checkpoint period.
    uint256 blockHeight;
    /// @dev The hash of the block.
    bytes32 blockHash;
    /// @dev The number of the membership (validator set) which is going to sign the next checkpoint.
    /// This one expected to be signed by the validators from the membership reported in the previous checkpoint.
    /// 0 could mean "no change".
    uint64 nextConfigurationNumber;
    /// @dev Batch of messages to execute.
    IpcEnvelope[] msgs;
    /// @dev The activity rollup from child subnet to parent subnet.
    CompressedActivityRollup activity;
}

/// @notice A batch of bottom-up messages for execution.
struct BottomUpMsgBatch {
    SubnetID subnetID;
    uint256 blockHeight;
    IpcEnvelope[] msgs;
}

/// @notice Tracks information about the last batch executed.
struct BottomUpMsgBatchInfo {
    uint256 blockHeight;
    bytes32 hash;
}

/// @notice Type of cross-net messages currently supported
enum IpcMsgKind {
    /// @dev for cross-net messages that move native token, i.e. fund/release.
    /// and in the future multi-level token transactions.
    Transfer,
    /// @dev general-purpose cross-net transaction that call smart contracts.
    Call,
    /// @dev receipt from the execution of cross-net messages
    Result
}

/// @notice An IPC address type.
struct IPCAddress {
    SubnetID subnetId;
    FvmAddress rawAddress;
}

/// @notice Envelope used to propagate IPC cross-net messages
struct IpcEnvelope {
    /// @dev type of message being propagated.
    IpcMsgKind kind;
    /// @dev outgoing nonce for the envelope.
    /// This nonce is set by the gateway when committing the message for propagation.
    /// This nonce is changed on each network when the message is propagated,
    /// so it is unique for each network and prevents replay attacks.
    uint64 localNonce;
    /// @dev original nonce of the message from the source network.
    /// It is set once at the source network and remains unchanged during propagation.
    /// It is used to generate a unique tracing ID across networks, which is useful for debugging and auditing purposes.
    uint64 originalNonce;
    /// @dev Value being sent in the message.
    uint256 value;
    /// @dev destination of the message
    /// It makes sense to extract from the encoded message
    /// all shared fields required by all message, so they
    /// can be inspected without having to decode the message.
    IPCAddress to;
    /// @dev address sending the message
    IPCAddress from;
    /// @dev abi.encoded message
    bytes message;
}

/// @notice Message format used for `Transfer` and `Call` messages.
struct CallMsg {
    bytes method;
    bytes params;
}

/// @notice Outcome type for cross message execution
enum OutcomeType {
    Ok,
    SystemErr,
    ActorErr
}

struct ResultMsg {
    bytes32 id;
    OutcomeType outcome;
    bytes ret;
}

/// @notice Validator struct stored in the gateway.
struct Validator {
    uint256 weight;
    address addr;
    bytes metadata;
}

/// @notice Membership information stored in the gateway.
struct Membership {
    Validator[] validators;
    uint64 configurationNumber;
}

/// @notice Defines token representation in subnet
struct Asset {
    AssetKind kind;
    address tokenAddress;
}

/// @notice Token type used in the subnet
enum AssetKind {
    Native,
    ERC20
}

// Activity related structs
struct FullActivityRollup {
    Consensus.FullSummary consensus;
}

struct CompressedActivityRollup {
    Consensus.CompressedSummary consensus;
}

/// Namespace for consensus-level activity summaries.
library Consensus {
    type MerkleHash is bytes32;

    struct AggregatedStats {
        uint64 totalActiveValidators;
        uint64 totalNumBlocksCommitted;
    }

    struct FullSummary {
        AggregatedStats stats;
        ValidatorData[] data;
    }

    struct CompressedSummary {
        AggregatedStats stats;
        MerkleHash dataRootCommitment;
    }

    struct ValidatorData {
        address validator;
        uint64 blocksCommitted;
    }

    struct ValidatorClaim {
        ValidatorData data;
        MerkleHash[] proof;
    }
}
