// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {KeyValue} from "./CommonTypes.sol";

/// @dev The kind of machine.
/// @param Bucket: A bucket with S3-like key semantics.
/// @param Timehub: An MMR accumulator.
enum Kind {
    Bucket,
    Timehub
}

/// @dev Parameters for creating a bucket.
/// @param owner (address): The owner of the bucket.
/// @param kind (Kind): The kind of the bucket.
/// @param metadata (KeyValue[]): The metadata of the bucket.
struct CreateBucketParams {
    address owner;
    Kind kind;
    KeyValue[] metadata;
}

/// @dev The result of a bucket query.
/// @param objects (Object[]): The list of key-values matching the list query.
/// @param commonPrefixes (string[]): When a delimiter is used in the list query, this contains common key prefixes.
/// @param nextKey (string): Next key to use for paginating when there are more objects to list.
struct Query {
    Object[] objects;
    string[] commonPrefixes;
    string nextKey;
}

/// @dev An object in the bucket as part of a query.
/// @param key (string): The object key.
/// @param value (ObjectState): The object state.
struct Object {
    string key;
    ObjectState state;
}

/// @dev The state of an object.
/// @param blobHash (string): The object blake3 hash.
/// @param size (uint64): The object size.
/// @param expiry (uint64): The expiry block.
/// @param metadata (KeyValue[]): The user-defined object metadata (e.g., last modified timestamp, etc.).
struct ObjectState {
    string blobHash;
    uint64 size;
    uint64 expiry;
    KeyValue[] metadata;
}

/// @dev The value of an object when getting an object.
/// @param blobHash (string): The object blake3 hash.
/// @param recoveryHash (string): Blake3 hash of the metadata to use for object recovery.
/// @param size (uint64): The object size.
/// @param expiry (uint64): The expiry block.
/// @param metadata (KeyValue[]): The user-defined object metadata (e.g., last modified timestamp, etc.).
struct ObjectValue {
    string blobHash;
    string recoveryHash;
    uint64 size;
    uint64 expiry;
    KeyValue[] metadata;
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

/// @dev Parameters for adding an object to a bucket.
/// @param source (string): The source Iroh node ID used for ingestion.
/// @param key (string): The object key.
/// @param blobHash (string): The object blake3 hash.
/// @param recoveryHash (string): Blake3 hash of the metadata to use for object recovery.
/// @param size (uint64): The object size.
/// @param ttl (uint64): The object time-to-live epochs.
/// @param metadata (KeyValue[]): The object metadata.
/// @param overwrite (bool): Whether to overwrite a key if it already exists.
/// @param from (address): Account address that initiated the call
struct AddObjectParams {
    string source;
    string key;
    string blobHash;
    string recoveryHash;
    uint64 size;
    uint64 ttl;
    KeyValue[] metadata;
    bool overwrite;
    address from;
}
