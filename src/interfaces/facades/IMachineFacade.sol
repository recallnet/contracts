// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {KeyValue} from "../../types/CommonTypes.sol";

/// @dev The kind of machine.
/// @param Bucket: A bucket with S3-like key semantics.
/// @param Timehub: An MMR accumulator.
enum Kind {
    Bucket,
    Timehub
}

/// @dev A machine in the bucket.
/// @param kind (Kind): The kind of the machine.
/// @param addr (address): The robust address of the machine.
/// @param metadata (KeyValue[]): The user-defined metadata.
struct Machine {
    Kind kind;
    address addr;
    KeyValue[] metadata;
}

interface IMachineFacade {
    /// @dev Emitted when a machine is created.
    /// @param kind Machine kind, i.e., bucket (0) or timehub (1).
    /// @param owner Machine owner address.
    /// @param metadata IPLD-encoded machine metadata (HashMap<String, String>).
    event MachineCreated(uint8 indexed kind, address indexed owner, bytes metadata);

    /// @dev Emitted when a machine is initialized.
    /// @param kind Machine kind, i.e., bucket (0) or timehub (1).
    /// @param machineAddress Machine address.
    event MachineInitialized(uint8 indexed kind, address machineAddress);

    /// @dev Create a bucket. Uses the sender as the owner.
    function createBucket() external returns (address);

    /// @dev Create a bucket.
    /// @param owner The owner.
    function createBucket(address owner) external returns (address);

    /// @dev Create a bucket.
    /// @param owner The owner.
    /// @param metadata The metadata.
    function createBucket(address owner, KeyValue[] memory metadata) external returns (address);

    /// @dev List all buckets owned by an address.
    /// @return The list of buckets.
    function listBuckets() external view returns (Machine[] memory);

    /// @dev List all buckets owned by an address.
    /// @param owner The owner of the buckets.
    /// @return The list of buckets.
    function listBuckets(address owner) external view returns (Machine[] memory);
}
