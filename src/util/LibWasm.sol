// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {BytesCBOR} from "@filecoin-solidity/v0.8/cbor/BytesCbor.sol";
import {FilecoinCBOR, Misc} from "@filecoin-solidity/v0.8/cbor/FilecoinCbor.sol";
import {CommonTypes} from "@filecoin-solidity/v0.8/types/CommonTypes.sol";
import {Actor} from "@filecoin-solidity/v0.8/utils/Actor.sol";
import {FilAddresses} from "@filecoin-solidity/v0.8/utils/FilAddresses.sol";

import {ActorError, InvalidValue} from "../errors/WasmErrors.sol";
import {KeyValue} from "../types/CommonTypes.sol";
import {Base32} from "./Base32.sol";
import {Blake2b} from "./Blake2b.sol";
import {ByteParser} from "./solidity-cbor/ByteParser.sol";
import {CBORDecoding} from "./solidity-cbor/CBORDecoding.sol";
import {CBOR} from "./solidity-cbor/CBOREncoding.sol";

/// @title WASM Adapter Library
/// @dev Utility functions for interacting with WASM actors and encoding/decoding CBOR.
/// All Wasm parameters and return types are encoded/decoded using CBOR. The following resources are useful if working
/// on new contracts and encoding/decoding data from onchain calls:
/// - CBOR spec: https://datatracker.ietf.org/doc/html/rfc8949
/// - CBOR inspector: https://cbor.me/
library LibWasm {
    uint64 internal constant EMPTY_CODEC = Misc.NONE_CODEC;
    uint64 internal constant CBOR_CODEC = Misc.CBOR_CODEC;

    /// @dev Decode a CBOR encoded array to bytes, extracting each value into an array of bytes.
    /// @param data The encoded CBOR array, including handling for null array (0xf6).
    /// @return decoded The decoded CBOR array. Returns empty bytes[] if the input is null.
    function decodeCborArrayToBytes(bytes memory data) internal view returns (bytes[] memory) {
        if (data.length == 1) return new bytes[](0); // Null value (0x80, 0xf6, 0x00) only case where 1 byte is possible
        return CBORDecoding.decodeArray(data);
    }

    /// @dev Decode CBOR encoded bytes array to underlying bytes string (e.g., a serialized Rust `Vec<u8>`).
    /// @param data The encoded CBOR bytes (e.g., 0x8618681865...).
    /// @return result The decoded bytes.
    function decodeCborBytesArrayToBytes(bytes memory data) internal pure returns (bytes memory) {
        if (uint8(data[0]) < 0x80 || uint8(data[0]) > 0x97) revert InvalidValue("Invalid fixed array indicator");
        // Initial data is a CBOR array (0x8<length>) of single byte values (0x18<byte>18<byte>)
        uint8 length = uint8(data[0]) - 0x80;
        bytes memory result = new bytes(length);
        // Skip first byte (indicator + length) and the second byte (first instance of 0x18 indicator)
        // Then, get every other byte since this is the raw value (skipping the 0x18 indicator)
        for (uint8 i = 0; i < length; i++) {
            result[i] = data[2 * i + 2];
        }
        return result;
    }

    /// @dev Decode a CBOR encoded fixed array/slice to bytes (e.g., a serialized Rust slice `[u8; N]`).
    /// @param data The encoded CBOR fixed array (e.g., `0x9820188e184c...` is a 32 byte array).
    /// @return decoded The decoded CBOR fixed array. Returns empty bytes[] if the input is null.
    function decodeCborFixedArrayToBytes(bytes memory data) internal pure returns (bytes memory) {
        if (data[0] != 0x98) revert InvalidValue("Invalid fixed array indicator");
        uint8 length = uint8(data[1]);
        bytes memory result = new bytes(length);
        uint256 index = 2; // Start at the third byte (i.e., the first instance of 0x18 or 0x00 to 0x17)
        for (uint8 i = 0; i < length; i++) {
            if (data[index] == 0x18) {
                result[i] = data[index + 1];
                index += 2;
            } else {
                // Assume that if the value is not a single byte (i.e., 0x18), it's the direct value (0x00..0x17)
                result[i] = data[index];
                index += 1;
            }
        }
        return result;
    }

    /// @dev Decode a CBOR encoded array to bytes.
    /// @param data The encoded CBOR array, including handling for null array (0xf6).
    /// @return decoded The decoded CBOR array. Returns empty bytes[] if the input is null.
    function decodeCborMappingToBytes(bytes memory data) internal view returns (bytes[2][] memory) {
        if (data.length == 1 && data[0] == 0xa0) return new bytes[2][](0);
        return CBORDecoding.decodeMapping(data);
    }

    /// @dev Decode a CBOR encoded string to bytes.
    /// @param data The encoded CBOR string.
    /// @return decoded The decoded CBOR string.
    function decodeStringToBytes(bytes memory data) internal view returns (bytes memory) {
        return CBORDecoding.decodePrimitive(data);
    }

    /// @dev Decode CBOR encoded bytes to uint64.
    /// @param data The encoded CBOR uint64.
    /// @return result The decoded uint64.
    function decodeCborBytesToUint64(bytes memory data) internal pure returns (uint64) {
        return ByteParser.bytesToUint64(data);
    }

    /// @dev Decode CBOR encoded bytes to uint256.
    /// @param data The encoded CBOR uint256.
    /// @return result The decoded uint256.
    function decodeCborBytesToUint256(bytes memory data) internal pure returns (uint256) {
        return ByteParser.bytesToBigNumber(data);
    }

    /// @dev Decode CBOR encoded Filecoin address bytes to an Ethereum address.
    /// @param addr The encoded CBOR Filecoin address. Example: 0x040a15d34aaf54267db7d7c367839aaf71a00a2c6a65
    /// @return result The decoded Ethereum address.
    // TODO: we need to figure out handling `t2` addresses. For example `t2yxnetcwoaljcrctdk5bm3v3bcmg6o7kzxol4zwi` will
    // get interpreted as `0xda498aCe02D2288A635742cdd761130De77D5900`, which is not valid since a `t2` address does not
    // have an EVM address counterpart(?).
    function decodeCborAddress(bytes memory addr) internal pure returns (address) {
        address result;
        assembly {
            // Skip 32 byte prefix, the first two FVM-specific bytes (0x04, 0x0a), and shift to the last 20 bytes
            result := shr(96, mload(add(addr, 34)))
        }
        return result;
    }

    /// @dev Decode a CBOR encoded Wasm actor address to a string.
    /// @param encoded The encoded Wasm actor address as CBOR bytes.
    /// @return result The decoded Wasm actor address as a string.
    function decodeCborActorAddress(bytes memory encoded) internal pure returns (string memory) {
        if (encoded.length != 21 || encoded[0] != 0x02) revert InvalidValue("Invalid address length or protocol");

        bytes memory checksum = Blake2b.hash(encoded, 4);
        // Combine payload and checksum
        bytes memory combined = new bytes(24);
        for (uint8 i = 0; i < 20; i++) {
            combined[i] = encoded[i + 1];
        }
        for (uint8 i = 0; i < 4; i++) {
            combined[20 + i] = checksum[i];
        }

        bytes memory base32Encoded = Base32.encode(combined);
        bytes memory addrBytes = new bytes(41);
        addrBytes[0] = "t";
        addrBytes[1] = "2";
        for (uint256 i = 0; i < 39; i++) {
            addrBytes[i + 2] = base32Encoded[i];
        }

        return string(addrBytes);
    }

    /// @dev Decode a CBOR encoded BigInt (unsigned) to a uint256. Assumptions:
    /// - Data is (almost always) encoded as a CBOR array with two elements.
    /// - A null BigInt is typically encoded as `0x820080`, but WASM sometimes serializes it as a string `0xf6`—and
    /// also, using the external CBOR helper `decodeArray` will convert to `0x00`.
    /// - First element is a sign (0x00 if empty or zero, 0x01 if positive), and all values are non-negative.
    /// - Second element is an array of big endian values with up to 8 elements (each 32 bit max).
    /// - Array values can be either 8, 16, or 32 bit unsigned integers, represented in CBOR as 0x18, 0x19, or 0x1a
    /// respectively.
    /// See Rust implementation for more details:
    /// https://github.com/filecoin-project/ref-fvm/blob/b72a51084f3b65f8bd41f4a9a733d43bb4b1d6f7/shared/src/bigint/biguint_ser.rs#L29
    /// TODO: Try to use filecoin-solidity or solidity-cbor for this.
    ///
    /// @param data CBOR encoded BigInt with a sign and an array of values.
    /// @return result Decoded BigInt as a uint256.
    function decodeCborBigIntToUint256(bytes memory data) internal pure returns (uint256) {
        if (data.length == 1 && (data[0] == 0x00 || data[0] == 0xf6)) return 0;
        if (data[0] != 0x82 || uint8(data[1]) > 1) revert InvalidValue("Invalid array length or sign value");

        // Case: 0x820080 (zero; empty array)
        if (data[2] == 0x80) return 0;

        // Can only be 0x81 to 0x88 (1 to 8 elements)
        if (data[2] < 0x81 || data[2] > 0x88) revert InvalidValue("Invalid bigint value");

        uint256 result;
        uint256 shift;
        uint256 index = 3;
        uint8 arrayLength = uint8(data[2]) - 0x80;

        for (uint8 i; i < arrayLength; i++) {
            uint32 value;
            uint8 valueType = uint8(data[index]);

            if (valueType <= 0x17) {
                value = valueType;
                index++;
            } else if (valueType == 0x18) {
                value = uint8(data[index + 1]);
                index += 2;
            } else if (valueType == 0x19) {
                value = (uint32(uint8(data[index + 1])) << 8) | uint32(uint8(data[index + 2]));
                index += 3;
            } else if (valueType == 0x1a) {
                value = uint32(
                    (uint32(uint8(data[index + 1])) << 24) | (uint32(uint8(data[index + 2])) << 16)
                        | (uint32(uint8(data[index + 3])) << 8) | uint32(uint8(data[index + 4]))
                );
                index += 5;
            } else {
                revert InvalidValue("Unsupported integer type");
            }

            result |= uint256(value) << shift;
            shift += 32;
        }

        return result;
    }

    /// @dev Decode CBOR encoded BigUint (unsigned) to a uint256.
    /// Assumptions:
    /// - Data is encoded as a CBOR array with values, and there is no sign.
    /// - A null BigUint is encoded as `0xf6`.
    /// - Array values are big endian values with up to 8 elements (each 32 bit max).
    /// - Array values can be either 8, 16, or 32 bit unsigned integers, represented in CBOR as 0x18, 0x19, or 0x1a
    /// respectively.
    /// @param data CBOR encoded BigUint.
    /// @return result Decoded BigUint as a uint256.
    function decodeCborBigUintToUint256(bytes memory data) internal pure returns (uint256) {
        if (data.length == 1 && (data[0] == 0x80 || data[0] == 0xf6)) return 0;
        if (data[0] < 0x81 || data[0] > 0x88) revert InvalidValue("Invalid bigint value");

        uint256 result;
        uint256 shift;
        uint256 index = 1;
        uint8 arrayLength = uint8(data[0]) - 0x80;

        for (uint8 i; i < arrayLength; i++) {
            uint32 value;
            uint8 valueType = uint8(data[index]);

            if (valueType <= 0x17) {
                value = valueType;
                index++;
            } else if (valueType == 0x18) {
                value = uint8(data[index + 1]);
                index += 2;
            } else if (valueType == 0x19) {
                value = (uint32(uint8(data[index + 1])) << 8) | uint32(uint8(data[index + 2]));
                index += 3;
            } else if (valueType == 0x1a) {
                value = uint32(
                    (uint32(uint8(data[index + 1])) << 24) | (uint32(uint8(data[index + 2])) << 16)
                        | (uint32(uint8(data[index + 3])) << 8) | uint32(uint8(data[index + 4]))
                );
                index += 5;
            } else {
                revert InvalidValue("Unsupported integer type");
            }

            result |= uint256(value) << shift;
            shift += 32;
        }

        return result;
    }

    /// @dev Decode a CBOR encoded blob hash to a string (a Rust Iroh hash value `Hash(pub [u8; 32])`).
    /// @param value The encoded CBOR blob hash (e.g,. `0x9820188e184c...`)
    /// @return result The decoded blob hash as base32 encoded bytes.
    function decodeBlobHash(bytes memory value) internal pure returns (bytes memory) {
        bytes memory decoded = decodeCborFixedArrayToBytes(value);
        return Base32.encode(decoded);
    }

    /// @dev Write raw bytes values to a CBOR buffer.
    /// @param data The bytes array to concatenate.
    function concatBytes(bytes[] memory data) internal pure returns (bytes memory) {
        bytes memory concat = bytes.concat();
        for (uint256 i = 0; i < data.length; i++) {
            concat = bytes.concat(concat, data[i]);
        }
        return concat;
    }

    /// @dev Encode a series of already encoded CBOR values as a CBOR array.
    /// @param params The already encoded params as a bytes array of CBOR encoded values.
    /// @return encoded The encoded params as a CBOR array.
    function encodeCborArray(bytes[] memory params) internal pure returns (bytes memory) {
        bytes memory concat = concatBytes(params);
        // 1 for the array indicator/length (0x82) and the concat params length
        CBOR.CBORBuffer memory buf = CBOR.create(1 + concat.length);
        CBOR.startFixedArray(buf, uint64(params.length));
        CBOR.writeRaw(buf, concat);
        return CBOR.data(buf);
    }

    /// @dev Encode a series of already encoded CBOR values as a CBOR map.
    /// @param params The already encoded params as a bytes array of CBOR encoded values.
    /// @return encoded The encoded params as a CBOR map.
    function encodeCborKeyValueMap(KeyValue[] memory params) internal pure returns (bytes memory) {
        if (params.length == 0) return hex"a0";
        CBOR.CBORBuffer memory buf = CBOR.create(1);
        CBOR.startFixedMap(buf, uint64(params.length));
        for (uint256 i = 0; i < params.length; i++) {
            CBOR.writeKVString(buf, params[i].key, params[i].value);
        }
        return CBOR.data(buf);
    }

    /// @dev Prepare bytes parameter for a method call by serializing it.
    /// @return params The serialized bytes as CBOR bytes.
    function encodeCborBytes(bytes memory value) internal pure returns (bytes memory) {
        uint256 capacity = value.length;
        CBOR.CBORBuffer memory buf = CBOR.create(1 + capacity);
        CBOR.writeBytes(buf, value);
        return CBOR.data(buf);
    }

    /// @dev Prepare string parameter for a method call by serializing it.
    /// @return params The serialized string as CBOR bytes.
    function encodeCborBytes(string memory value) internal pure returns (bytes memory) {
        uint256 capacity = bytes(value).length;
        CBOR.CBORBuffer memory buf = CBOR.create(1 + capacity);
        CBOR.writeBytes(buf, bytes(value));
        return CBOR.data(buf);
    }

    /// @dev Prepare string parameter for a method call by serializing it.
    /// @return params The serialized string as CBOR bytes.
    function encodeCborString(string memory str) internal pure returns (bytes memory) {
        uint256 capacity = bytes(str).length;
        CBOR.CBORBuffer memory buf = CBOR.create(1 + capacity);
        CBOR.writeString(buf, str);
        return CBOR.data(buf);
    }

    /// @dev Prepare boolean parameter for a method call by serializing it.
    /// @param value The boolean value to serialize.
    /// @return encoded The serialized boolean as CBOR bytes.
    function encodeCborBool(bool value) internal pure returns (bytes memory) {
        return value ? bytes(hex"f5") : bytes(hex"f4"); // `0xf5` is true, `0xf4` is false
    }

    /// @dev Prepare address parameter for a method call by serializing it.
    /// @return params The serialized address as CBOR bytes.
    function encodeCborNull() internal pure returns (bytes memory) {
        return hex"f6";
    }

    /// @dev Prepare address parameter for a method call by serializing it.
    /// @param addr The address of the account.
    /// @return encoded The serialized address as CBOR bytes.
    // TODO: figure out if a `t2` address can work here
    function encodeCborAddress(address addr) internal pure returns (bytes memory) {
        CommonTypes.FilAddress memory filAddr = FilAddresses.fromEthAddress(addr);
        return FilecoinCBOR.serializeAddress(filAddr);
    }

    /// @dev Prepare actor address parameter for a method call by serializing it. Assumes the address is a valid `t2`
    /// address.
    /// @param addr The address of the Wasm actor (e.g, `t2...`).
    /// @return encoded The serialized Wasm actor address as CBOR bytes.
    function encodeCborActorAddress(string memory addr) internal pure returns (bytes memory) {
        bytes memory addrBytes = bytes(addr);
        bytes1 protocol = addrBytes[1]; // Second value of `t2` is the protocol
        // A t2 address is 41 bytes long, and protocol `2` is an actor (`2` from a string is 0x32)
        if (addrBytes.length != 41 || protocol != 0x32) revert InvalidValue("Invalid address length or protocol");
        bytes memory subAddr = new bytes(39); // Ignore the first 2 bytes (network + protocol)
        for (uint256 i = 0; i < 39; i++) {
            subAddr[i] = addrBytes[i + 2];
        }
        bytes memory decoded = Base32.decode(subAddr); // 24 bytes
        // Payload's first byte is the protocol actor (0x02) + the first 20 bytes (ignore last 4 bytes; checksum)
        bytes memory encoded = new bytes(21);
        encoded[0] = 0x02;
        assembly {
            let decodedPtr := add(decoded, 32)
            let encodedPtr := add(encoded, 33)
            mstore(encodedPtr, xor(mload(encodedPtr), mload(decodedPtr)))
        }
        return encoded;
    }

    /// @dev Prepare uint64 parameter for a method call by serializing it.
    /// @param value A uint64 value.
    /// @return encoded The serialized uint64 as CBOR bytes.
    function encodeCborUint64(uint64 value) internal pure returns (bytes memory) {
        CBOR.CBORBuffer memory buf = CBOR.create(1); // Minimum of 1 byte; will expand if exceeded
        CBOR.writeUInt64(buf, value);
        return CBOR.data(buf);
    }

    /// @dev Encode a uint256 to a CBOR encoded BigInt (CBOR array with sign and big endian values of uint32).
    /// @param value The uint256 value to encode.
    /// @return encoded The CBOR encoded BigInt.
    function encodeCborBigInt(uint256 value) internal pure returns (bytes memory) {
        if (value == 0) return hex"820080"; // Case: 0x820080 (zero; empty array)

        // Minimum possible size: 1 (0x82) + 1 (sign; 0x01) + 2 (smallest possible inner array; e.g. 0x8101)
        CBOR.CBORBuffer memory buf = CBOR.create(4);
        CBOR.startFixedArray(buf, 2);
        CBOR.writeRaw(buf, bytes(hex"01")); // Sign: always 1 for positive

        // Deconstruct the uint256 into 8 uint32 values where the length provides most significant bits chunk
        uint8 arrayLength = 0;
        uint32[] memory values = new uint32[](8);
        for (uint256 i = 0; i < 8; i++) {
            uint32 chunk = uint32(value >> ((7 - i) * 32));
            if (chunk > 0 || arrayLength > 0) {
                values[arrayLength] = chunk;
                arrayLength++;
            }
        }

        CBOR.startFixedArray(buf, arrayLength);
        // Write values in reverse order to match Rust's BigInt serialization (big endian)
        // Writing also resizes the buffer if it exceeds the initial capacity
        for (uint8 i = arrayLength; i > 0; i--) {
            CBOR.writeUInt32(buf, values[i - 1]);
        }

        return CBOR.data(buf);
    }

    /// @dev Encode a uint256 to a CBOR encoded BigUInt (CBOR array with no sign and big endian values of uint32).
    /// @param value The uint256 value to encode.
    /// @return encoded The CBOR encoded BigUInt.
    function encodeCborBigUint(uint256 value) internal pure returns (bytes memory) {
        // TODO: in Rust, if a value is null, it's `0xf6`, but if a value is zero, it's `0x80`
        if (value == 0) return hex"80"; // Case: 0x80 (zero; empty array)

        // Deconstruct the uint256 into 8 uint32 values where the length provides most significant bits chunk
        uint8 arrayLength = 0;
        uint32[] memory values = new uint32[](8);
        for (uint256 i = 0; i < 8; i++) {
            uint32 chunk = uint32(value >> ((7 - i) * 32));
            if (chunk > 0 || arrayLength > 0) {
                values[arrayLength] = chunk;
                arrayLength++;
            }
        }

        // Minimum possible size: 1 (0x81) + 1 (smallest possible inner array; e.g. 0x01)
        CBOR.CBORBuffer memory buf = CBOR.create(2);
        CBOR.startFixedArray(buf, arrayLength);

        // Write values in reverse order to match Rust's BigInt serialization (big endian)
        // Writing also resizes the buffer if it exceeds the initial capacity
        for (uint8 i = arrayLength; i > 0; i--) {
            CBOR.writeUInt32(buf, values[i - 1]);
        }

        return CBOR.data(buf);
    }

    /// @dev Encode a bytes array to a CBOR encoded fixed array/slice (e.g., a serialized Rust slice `[u8; N]`).
    /// @param value The bytes array to encode.
    /// @return encoded The CBOR encoded fixed array.
    function encodeCborFixedArray(bytes memory value) internal pure returns (bytes memory) {
        uint8 length = uint8(value.length);
        bytes memory result = new bytes(2 + length * 2); // Max possible length
        result[0] = 0x98; // Fixed array indicator
        result[1] = bytes1(length); // Length indicator

        uint256 resultIndex = 2;
        for (uint8 i = 0; i < length; i++) {
            uint8 val = uint8(value[i]);
            if (val <= 0x17) {
                result[resultIndex] = bytes1(val);
                resultIndex++;
            } else {
                result[resultIndex] = 0x18;
                result[resultIndex + 1] = bytes1(val);
                resultIndex += 2;
            }
        }
        // Trim any unused bytes
        assembly {
            mstore(result, resultIndex)
        }

        return result;
    }

    /// @dev Encode a blob hash or Iroh node ID to a CBOR encoded value (a Rust base32 encoded value `pub [u8; 32]`).
    /// @param value The blob hash or Iroh node ID to encode.
    /// @return encoded The CBOR encoded blob hash or node ID.
    function encodeCborBlobHashOrNodeId(string memory value) internal pure returns (bytes memory) {
        bytes memory decoded = Base32.decode(bytes(value));
        return encodeCborFixedArray(decoded);
    }

    /// @dev Read from a wasm actor with empty params.
    /// @param actorId The actor ID.
    /// @param methodNum The method number.
    /// @return data The data returned from the actor.
    function readFromWasmActor(uint64 actorId, uint64 methodNum) internal view returns (bytes memory) {
        bytes memory params = new bytes(0);
        (int256 exit, bytes memory data) =
            Actor.callByIDReadOnly(CommonTypes.FilActorId.wrap(actorId), methodNum, EMPTY_CODEC, params);

        if (exit != 0) revert ActorError(exit);
        return data;
    }

    /// @dev Read from a wasm actor with encoded params.
    /// @param actorId The actor ID.
    /// @param methodNum The method number.
    /// @param params The parameters.
    /// @return data The data returned from the actor.
    function readFromWasmActor(uint64 actorId, uint64 methodNum, bytes memory params)
        internal
        view
        returns (bytes memory)
    {
        if (params.length == 0) revert InvalidValue("Params must be non-empty");
        (int256 exit, bytes memory data) =
            Actor.callByIDReadOnly(CommonTypes.FilActorId.wrap(actorId), methodNum, CBOR_CODEC, params);

        if (exit != 0) revert ActorError(exit);
        return data;
    }

    /// @dev Read from a Wasm actor (by its `t2` address) with encoded params.
    /// @param addr The actor address (e.g, `t2...`).
    /// @param methodNum The method number.
    /// @param params The parameters.
    /// @return data The data returned from the actor.
    function readFromWasmActorByAddress(bytes memory addr, uint64 methodNum, bytes memory params)
        internal
        returns (bytes memory)
    {
        if (params.length == 0) revert InvalidValue("Params must be non-empty");
        (int256 exit, bytes memory data) = Actor.callByAddress(addr, methodNum, CBOR_CODEC, params, 0, true);

        if (exit != 0) revert ActorError(exit);
        return data;
    }

    /// @dev Write to a wasm actor.
    /// @param actorId The actor ID.
    /// @param methodNum The method number.
    /// @param params The parameters.
    /// @return data The data returned from the actor.
    function writeToWasmActor(uint64 actorId, uint64 methodNum, bytes memory params) internal returns (bytes memory) {
        if (params.length == 0) revert InvalidValue("Params must be non-empty");
        uint64 codec = CBOR_CODEC;
        uint256 value = msg.value > 0 ? msg.value : 0;
        (int256 exit, bytes memory data) = Actor.callByID(
            CommonTypes.FilActorId.wrap(actorId),
            methodNum,
            codec,
            params,
            value,
            false // static call
        );

        if (exit != 0) revert ActorError(exit);
        return data;
    }

    /// @dev Write to a Wasm actor (by its `t2` address) with encoded params.
    /// @param addr The actor address (e.g, `t2...`).
    /// @param methodNum The method number.
    /// @param params The parameters.
    /// @return data The data returned from the actor.
    function writeToWasmActorByAddress(bytes memory addr, uint64 methodNum, bytes memory params)
        internal
        returns (bytes memory)
    {
        if (params.length == 0) revert InvalidValue("Params must be non-empty");
        (int256 exit, bytes memory data) = Actor.callByAddress(addr, methodNum, CBOR_CODEC, params, 0, false);

        if (exit != 0) revert ActorError(exit);
        return data;
    }
}
