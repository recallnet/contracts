// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

/// @dev Errors for CBOR encoding and decoding
error InvalidValue(string);

/// @dev Errors for CBOR RFC shortcodes
error InvalidRFCShortcode();

/// @dev Errors for CBOR tag types
error InvalidTagType();

/// @dev Errors for CBOR major types
error InvalidMajorType();
