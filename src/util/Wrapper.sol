// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BytesCBOR} from "@filecoin-solidity/v0.8/cbor/BytesCbor.sol";
import {FilecoinCBOR, Misc} from "@filecoin-solidity/v0.8/cbor/FilecoinCbor.sol";
import {CommonTypes} from "@filecoin-solidity/v0.8/types/CommonTypes.sol";
import {Actor} from "@filecoin-solidity/v0.8/utils/Actor.sol";
import {FilAddresses} from "@filecoin-solidity/v0.8/utils/FilAddresses.sol";

import {ByteParser} from "./solidity-cbor/ByteParser.sol";
import {CBORDecoding} from "./solidity-cbor/CBORDecoding.sol";
import {CBOR} from "./solidity-cbor/CBOREncoding.sol";

/// @title Wrapper Library
/// @dev Utility functions for interacting with WASM actors and encoding/decoding CBOR.
library Wrapper {
    uint64 internal constant EMPTY_CODEC = Misc.NONE_CODEC;
    uint64 internal constant CBOR_CODEC = Misc.CBOR_CODEC;

    /// @dev Decode a CBOR encoded array to bytes.
    /// @param data The encoded CBOR array, including handling for null array (0xf6).
    /// @return decoded The decoded CBOR array. Returns empty bytes[] if the input is null.
    function decodeCborArrayToBytes(bytes memory data) internal view returns (bytes[] memory decoded) {
        if (data.length == 1 && data[0] == 0xf6) return new bytes[](0);
        decoded = CBORDecoding.decodeArray(data);
    }

    /// @dev Decode a CBOR encoded array to bytes.
    /// @param data The encoded CBOR array, including handling for null array (0xf6).
    /// @return decoded The decoded CBOR array. Returns empty bytes[] if the input is null.
    function decodeCborMappingToBytes(bytes memory data) internal view returns (bytes[2][] memory decoded) {
        if (data.length == 1 && data[0] == 0xa0) return new bytes[2][](0);
        decoded = CBORDecoding.decodeMapping(data);
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
        require(data[0] == 0x82, "Must be array of 2 elements");
        require(uint8(data[1]) <= 1, "Invalid sign value");

        // Case: 0x820080 (zero; empty array)
        if (data[2] == 0x80) return 0;

        require(data[2] >= 0x81 && data[2] <= 0x88, "Invalid array length");

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
                revert("Unsupported integer type");
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
        require(data[0] >= 0x81 && data[0] <= 0x88, "Invalid array length");

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
                revert("Unsupported integer type");
            }

            result |= uint256(value) << shift;
            shift += 32;
        }

        return result;
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
    function encodeCborArray(bytes memory params) internal pure returns (bytes memory encoded) {
        // 1 for the array indicator/length (0x82) and the params length
        CBOR.CBORBuffer memory buf = CBOR.create(1 + params.length);
        CBOR.startFixedArray(buf, uint64(params.length));
        CBOR.writeRaw(buf, params);
        encoded = CBOR.data(buf);
    }

    /// @dev Encode a series of already encoded CBOR values as a CBOR array.
    /// @param params The already encoded params as a bytes array of CBOR encoded values.
    /// @return encoded The encoded params as a CBOR array.
    function encodeCborArray(bytes[] memory params) internal pure returns (bytes memory encoded) {
        bytes memory concat = concatBytes(params);
        // 1 for the array indicator/length (0x82) and the concat params length
        CBOR.CBORBuffer memory buf = CBOR.create(1 + concat.length);
        CBOR.startFixedArray(buf, uint64(params.length));
        CBOR.writeRaw(buf, concat);
        encoded = CBOR.data(buf);
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
    function encodeCborAddress(address addr) internal pure returns (bytes memory encoded) {
        CommonTypes.FilAddress memory filAddr = FilAddresses.fromEthAddress(addr);
        encoded = FilecoinCBOR.serializeAddress(filAddr);
    }

    /// @dev Prepare uint64 parameter for a method call by serializing it.
    /// @param value A uint64 value.
    /// @return encoded The serialized uint64 as CBOR bytes.
    function encodeCborUint64(uint64 value) internal pure returns (bytes memory encoded) {
        bytes memory valueBytes = abi.encodePacked(value);
        uint256 capacity = Misc.getBytesSize(valueBytes);
        CBOR.CBORBuffer memory buf = CBOR.create(capacity);
        CBOR.writeUInt64(buf, value);
        encoded = CBOR.data(buf);
    }

    /// @dev Encode a uint256 to a CBOR encoded BigInt (CBOR array with sign and big endian values of uint32).
    /// @param value The uint256 value to encode.
    /// @return encoded The CBOR encoded BigInt.
    function encodeCborBigInt(uint256 value) internal pure returns (bytes memory encoded) {
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

        encoded = CBOR.data(buf);
    }

    /// @dev Encode a uint256 to a CBOR encoded BigUInt (CBOR array with no sign and big endian values of uint32).
    /// @param value The uint256 value to encode.
    /// @return encoded The CBOR encoded BigUInt.
    function encodeCborBigUint(uint256 value) internal pure returns (bytes memory encoded) {
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

        encoded = CBOR.data(buf);
    }

    /// @dev Read from a wasm actor with empty params.
    /// @param actorId The actor ID.
    /// @param methodNum The method number.
    /// @return data The data returned from the actor.
    function readFromWasmActor(uint64 actorId, uint64 methodNum) internal view returns (bytes memory) {
        bytes memory params = new bytes(0);
        (int256 exit, bytes memory data) =
            Actor.callByIDReadOnly(CommonTypes.FilActorId.wrap(actorId), methodNum, EMPTY_CODEC, params);

        require(exit == 0, "Actor returned an error");
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
        require(params.length > 0, "Params must be non-empty");
        (int256 exit, bytes memory data) =
            Actor.callByIDReadOnly(CommonTypes.FilActorId.wrap(actorId), methodNum, CBOR_CODEC, params);

        require(exit == 0, "Actor returned an error");
        return data;
    }

    /// @dev Write to a wasm actor.
    /// @param actorId The actor ID.
    /// @param methodNum The method number.
    /// @param params The parameters.
    /// @return data The data returned from the actor.
    function writeToWasmActor(uint64 actorId, uint64 methodNum, bytes memory params) internal returns (bytes memory) {
        require(params.length > 0, "Params must be non-empty");
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

        require(exit == 0, "Actor returned an error");
        return data;
    }
}
