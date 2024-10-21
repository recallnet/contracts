// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

// import {} from "../util/Types.sol";

/// @dev Hoku Bucket actor EVM interface for managing objects, and querying object or storage stats.
/// See Rust implementation for details:
/// https://github.com/hokunet/ipc/blob/develop/fendermint/actors/blobs/src/actor.rs
interface IBucket {
    function list(bytes memory prefix, bytes memory delimiter, uint64 offset, uint64 limit)
        external
        returns (bytes memory);
}
