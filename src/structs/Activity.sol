// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.23;

import {SubnetID} from "../structs/Subnet.sol";

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