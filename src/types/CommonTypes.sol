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

/// Namespace for consensus-level activity summaries.
library Consensus {
    struct ValidatorData {
        /// @dev The validator whose activity we're reporting about, identified by the Ethereum address corresponding
        /// to its secp256k1 pubkey.
        address validator;
        /// @dev The number of blocks committed by this validator during the summarised period.
        uint64 blocksCommitted;
    }
}

/// @notice An IPC address type.
struct IPCAddress {
    SubnetID subnetId;
    FvmAddress rawAddress;
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
    /// @dev the gas limit is currently not used.
    // FIXME: currently not used.
    // uint256 gasLimit;
}
