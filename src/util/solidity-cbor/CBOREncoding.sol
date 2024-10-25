// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {InvalidValue} from "./components/CBORErrors.sol";
import {Buffer} from "@ensdomains/buffer/contracts/Buffer.sol";

/// @title CBOR Encoding Library
/// @dev A library for populating CBOR encoded payload in Solidity.
/// @notice https://datatracker.ietf.org/doc/html/rfc7049
///
/// The library offers various write* and start* methods to encode values of different types.
/// The resulted buffer can be obtained with data() method.
/// Encoding of primitive types is straightforward, whereas encoding of sequences can result
/// in an invalid CBOR if start/write/end flow is violated.
/// For the purpose of gas saving, the library does not verify start/write/end flow internally,
/// except for nested start/end pairs.
///
/// Forked from source: https://github.com/smartcontractkit/solidity-cborutils
library CBOR {
    using Buffer for Buffer.buffer;

    struct CBORBuffer {
        Buffer.buffer buf;
        uint256 depth;
    }

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_TAG = 6;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    uint8 private constant TAG_TYPE_BIGNUM = 2;
    uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

    uint8 private constant CBOR_FALSE = 20;
    uint8 private constant CBOR_TRUE = 21;
    uint8 private constant CBOR_NULL = 22;
    uint8 private constant CBOR_UNDEFINED = 23;

    /// @dev Creates a new CBOR buffer with the specified capacity
    /// @param capacity The initial capacity of the buffer
    /// @return cbor The newly created CBORBuffer
    function create(uint256 capacity) internal pure returns (CBORBuffer memory cbor) {
        Buffer.init(cbor.buf, capacity);
        cbor.depth = 0;
        return cbor;
    }

    /// @dev Returns the encoded CBOR data
    /// @param buf The CBORBuffer to extract data from
    /// @return The encoded CBOR data as bytes
    function data(CBORBuffer memory buf) internal pure returns (bytes memory) {
        if (buf.depth != 0) {
            revert InvalidValue("Invalid CBOR");
        }
        return buf.buf.buf;
    }

    /// @dev Writes a uint256 value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param value The uint256 value to write
    function writeUInt256(CBORBuffer memory buf, uint256 value) internal pure {
        buf.buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
        writeBytes(buf, abi.encode(value));
    }

    /// @dev Writes an int256 value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param value The int256 value to write
    function writeInt256(CBORBuffer memory buf, int256 value) internal pure {
        if (value < 0) {
            buf.buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
            writeBytes(buf, abi.encode(uint256(-1 - value)));
        } else {
            writeUInt256(buf, uint256(value));
        }
    }

    /// @dev Writes a uint64 value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param value The uint64 value to write
    function writeUInt64(CBORBuffer memory buf, uint64 value) internal pure {
        writeFixedNumeric(buf, MAJOR_TYPE_INT, value);
    }

    /// @dev Writes an int64 value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param value The int64 value to write
    function writeInt64(CBORBuffer memory buf, int64 value) internal pure {
        if (value >= 0) {
            writeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
        } else {
            writeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(-1 - value));
        }
    }

    /// @dev Writes a byte array to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param value The byte array to write
    function writeBytes(CBORBuffer memory buf, bytes memory value) internal pure {
        writeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
        buf.buf.append(value);
    }

    /// @dev Writes a string to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param value The string to write
    function writeString(CBORBuffer memory buf, string memory value) internal pure {
        writeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
        buf.buf.append(bytes(value));
    }

    /// @dev Writes a boolean value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param value The boolean value to write
    function writeBool(CBORBuffer memory buf, bool value) internal pure {
        writeContentFree(buf, value ? CBOR_TRUE : CBOR_FALSE);
    }

    /// @dev Writes a null value to the buffer
    /// @param buf The CBORBuffer to write to
    function writeNull(CBORBuffer memory buf) internal pure {
        writeContentFree(buf, CBOR_NULL);
    }

    /// @dev Writes an undefined value to the buffer
    /// @param buf The CBORBuffer to write to
    function writeUndefined(CBORBuffer memory buf) internal pure {
        writeContentFree(buf, CBOR_UNDEFINED);
    }

    /// @dev Starts an indefinite length array in the buffer
    /// @param buf The CBORBuffer to write to
    function startArray(CBORBuffer memory buf) internal pure {
        writeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
        buf.depth += 1;
    }

    /// @dev Starts a fixed length array in the buffer
    /// @param buf The CBORBuffer to write to
    /// @param length The length of the array
    function startFixedArray(CBORBuffer memory buf, uint64 length) internal pure {
        writeDefiniteLengthType(buf, MAJOR_TYPE_ARRAY, length);
    }

    /// @dev Starts an indefinite length map in the buffer
    /// @param buf The CBORBuffer to write to
    function startMap(CBORBuffer memory buf) internal pure {
        writeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
        buf.depth += 1;
    }

    /// @dev Starts a fixed length map in the buffer
    /// @param buf The CBORBuffer to write to
    /// @param length The length of the map
    function startFixedMap(CBORBuffer memory buf, uint64 length) internal pure {
        writeDefiniteLengthType(buf, MAJOR_TYPE_MAP, length);
    }

    /// @dev Ends a sequence (array or map) in the buffer
    /// @param buf The CBORBuffer to write to
    function endSequence(CBORBuffer memory buf) internal pure {
        writeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
        buf.depth -= 1;
    }

    /// @dev Writes a key-value pair with string values to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param key The key of the pair
    /// @param value The value of the pair
    function writeKVString(CBORBuffer memory buf, string memory key, string memory value) internal pure {
        writeString(buf, key);
        writeString(buf, value);
    }

    /// @dev Writes a key-value pair with a string key and bytes value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param key The key of the pair
    /// @param value The value of the pair
    function writeKVBytes(CBORBuffer memory buf, string memory key, bytes memory value) internal pure {
        writeString(buf, key);
        writeBytes(buf, value);
    }

    /// @dev Writes a key-value pair with a string key and uint256 value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param key The key of the pair
    /// @param value The value of the pair
    function writeKVUInt256(CBORBuffer memory buf, string memory key, uint256 value) internal pure {
        writeString(buf, key);
        writeUInt256(buf, value);
    }

    /// @dev Writes a key-value pair with a string key and int256 value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param key The key of the pair
    /// @param value The value of the pair
    function writeKVInt256(CBORBuffer memory buf, string memory key, int256 value) internal pure {
        writeString(buf, key);
        writeInt256(buf, value);
    }

    /// @dev Writes a key-value pair with a string key and uint64 value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param key The key of the pair
    /// @param value The value of the pair
    function writeKVUInt64(CBORBuffer memory buf, string memory key, uint64 value) internal pure {
        writeString(buf, key);
        writeUInt64(buf, value);
    }

    /// @dev Writes a key-value pair with a string key and int64 value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param key The key of the pair
    /// @param value The value of the pair
    function writeKVInt64(CBORBuffer memory buf, string memory key, int64 value) internal pure {
        writeString(buf, key);
        writeInt64(buf, value);
    }

    /// @dev Writes a key-value pair with a string key and boolean value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param key The key of the pair
    /// @param value The value of the pair
    function writeKVBool(CBORBuffer memory buf, string memory key, bool value) internal pure {
        writeString(buf, key);
        writeBool(buf, value);
    }

    /// @dev Writes a key-value pair with a string key and null value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param key The key of the pair
    function writeKVNull(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        writeNull(buf);
    }

    /// @dev Writes a key-value pair with a string key and undefined value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param key The key of the pair
    function writeKVUndefined(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        writeUndefined(buf);
    }

    /// @dev Writes a key and starts a map as its value in the buffer
    /// @param buf The CBORBuffer to write to
    /// @param key The key of the pair
    function writeKVMap(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        startMap(buf);
    }

    /// @dev Writes a key and starts an array as its value in the buffer
    /// @param buf The CBORBuffer to write to
    /// @param key The key of the pair
    function writeKVArray(CBORBuffer memory buf, string memory key) internal pure {
        writeString(buf, key);
        startArray(buf);
    }

    /// @dev Writes a fixed numeric value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param major The major type of the value
    /// @param value The numeric value to write
    function writeFixedNumeric(CBORBuffer memory buf, uint8 major, uint64 value) private pure {
        if (value <= 23) {
            buf.buf.appendUint8(uint8((major << 5) | value));
        } else if (value <= 0xFF) {
            buf.buf.appendUint8(uint8((major << 5) | 24));
            buf.buf.appendInt(value, 1);
        } else if (value <= 0xFFFF) {
            buf.buf.appendUint8(uint8((major << 5) | 25));
            buf.buf.appendInt(value, 2);
        } else if (value <= 0xFFFFFFFF) {
            buf.buf.appendUint8(uint8((major << 5) | 26));
            buf.buf.appendInt(value, 4);
        } else {
            buf.buf.appendUint8(uint8((major << 5) | 27));
            buf.buf.appendInt(value, 8);
        }
    }

    /// @dev Writes an indefinite length type to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param major The major type of the value
    function writeIndefiniteLengthType(CBORBuffer memory buf, uint8 major) private pure {
        buf.buf.appendUint8(uint8((major << 5) | 31));
    }

    /// @dev Writes a definite length type to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param major The major type of the value
    /// @param length The length of the value
    function writeDefiniteLengthType(CBORBuffer memory buf, uint8 major, uint64 length) private pure {
        writeFixedNumeric(buf, major, length);
    }

    /// @dev Writes a content-free value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param value The value to write
    function writeContentFree(CBORBuffer memory buf, uint8 value) private pure {
        buf.buf.appendUint8(uint8((MAJOR_TYPE_CONTENT_FREE << 5) | value));
    }

    /// @dev Writes raw CBOR data to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param rawCBOR The raw CBOR data to write
    function writeRaw(CBORBuffer memory buf, bytes memory rawCBOR) internal pure {
        buf.buf.append(rawCBOR);
    }

    /// @dev Writes a uint32 value to the buffer
    /// @param buf The CBORBuffer to write to
    /// @param value The uint64 value to write
    function writeUInt32(CBORBuffer memory buf, uint32 value) internal pure {
        if (value <= 23) {
            buf.buf.appendUint8(uint8((MAJOR_TYPE_INT << 5) | value));
        } else if (value <= 0xFF) {
            buf.buf.appendUint8(uint8((MAJOR_TYPE_INT << 5) | 24));
            buf.buf.appendInt(value, 1);
        } else if (value <= 0xFFFF) {
            buf.buf.appendUint8(uint8((MAJOR_TYPE_INT << 5) | 25));
            buf.buf.appendInt(value, 2);
        } else {
            buf.buf.appendUint8(uint8((MAJOR_TYPE_INT << 5) | 26));
            buf.buf.appendInt(value, 4);
        }
    }
}
