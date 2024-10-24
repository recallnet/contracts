// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {KeyValue} from "./CommonTypes.sol";

/// @dev The kind of machine.
enum Kind {
    /// A bucket with S3-like key semantics.
    Bucket,
    /// An MMR accumulator.
    Timehub
}

/// @dev The write access of the machine.
enum WriteAccess {
    /// Only the owner can write to the machine.
    OnlyOwner,
    /// Any valid account can write to the machine.
    Public
}

/// @dev Parameters for creating a bucket.
struct CreateBucketParams {
    address owner;
    Kind kind;
    WriteAccess writeAccess;
    KeyValue[] metadata;
}

/// @dev The result of a bucket query.
struct Query {
    /// List of key-values matching the list query.
    Object[] objects;
    /// When a delimiter is used in the list query, this contains common key prefixes.
    string[] commonPrefixes;
}

/// @dev An object in the bucket.
struct Object {
    /// Object key.
    string key;
    /// Object value.
    Value value;
}

/// @dev The value of an object.
struct Value {
    /// Object blake3 hash.
    string hash;
    /// Object size.
    uint64 size;
    /// Object expiry.
    uint64 expiry;
    /// Object metadata.
    KeyValue[] metadata;
}

/// @dev A machine in the bucket.
struct Machine {
    /// Machine kind.
    Kind kind;
    /// Machine robust address.
    string addr;
    /// User-defined metadata.
    KeyValue[] metadata;
}

/// @dev Parameters for adding an object to a bucket.
struct AddParams {
    string source;
    string key;
    string blobHash;
    uint64 size;
    uint64 ttl;
    KeyValue[] metadata;
    bool overwrite;
}
