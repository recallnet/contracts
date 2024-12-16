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
