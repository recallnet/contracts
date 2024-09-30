// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Actor} from "@filecoin-solidity/v0.8/utils/Actor.sol";
import {FilecoinCBOR, Misc} from "@filecoin-solidity/v0.8/cbor/FilecoinCBOR.sol";
import {FilAddresses} from "@filecoin-solidity/v0.8/utils/FilAddresses.sol";
import {CommonTypes} from "@filecoin-solidity/v0.8/types/CommonTypes.sol";
import {ByteParser} from "./solidity-cbor/ByteParser.sol";
import {CBORDecoding} from "./solidity-cbor/CBORDecoding.sol";

/// @dev Utility functions for interacting with WASM actors and encoding/decoding CBOR.
library Wrapper {
    uint64 internal constant EMPTY_CODEC = Misc.NONE_CODEC;
    uint64 internal constant CBOR_CODEC = Misc.CBOR_CODEC;

    /// @dev Decode a CBOR encoded array to bytes.
    /// @param data The encoded CBOR array, including handling for null array (0xf6).
    /// @return decoded The decoded CBOR array. Returns empty bytes[] if the input is null.
    function decodeCborArrayToBytes(
        bytes memory data
    ) internal view returns (bytes[] memory decoded) {
        if (keccak256(data) == keccak256(hex"f6")) return new bytes[](0);
        decoded = CBORDecoding.decodeArray(data);
    }

    /// @dev Decode CBOR encoded bytes to uint64.
    /// @param data The encoded CBOR uint64.
    /// @return result The decoded uint64.
    function decodeCborBytesToUint64(
        bytes memory data
    ) internal pure returns (uint64) {
        return ByteParser.bytesToUint64(data);
    }

    /// @dev Decode CBOR encoded bytes to uint256.
    /// @param data The encoded CBOR uint256.
    /// @return result The decoded uint256.
    function decodeCborBytesToUint256(
        bytes memory data
    ) internal pure returns (uint256) {
        return ByteParser.bytesToBigNumber(data);
    }

    /// @dev Decode a CBOR encoded BigInt (unsigned) to a uint256. Assumptions:
    /// - Data is encoded as a CBOR array with two elements.
    /// - First element is a sign (0x00 if empty or zero, 0x01 if positive), and all values are non-negative.
    /// - Second element is an array of big endian values with up to 8 elements.
    /// - Array values can be either 8, 16, or 32 bit unsigned integers, represented in CBOR as 0x18, 0x19, or 0x1a respectively.
    /// See Rust implementation for more details: https://github.com/filecoin-project/ref-fvm/blob/b72a51084f3b65f8bd41f4a9a733d43bb4b1d6f7/shared/src/bigint/biguint_ser.rs#L29
    /// TODO: Try to use filecoin-solidity or solidity-cbor for this.
    ///
    /// @param data CBOR encoded BigInt with a sign and an array of values.
    /// @return result Decoded BigInt as a uint256.
    function decodeCborBigIntToUint256(
        bytes memory data
    ) internal pure returns (uint256) {
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
                value =
                    (uint32(uint8(data[index + 1])) << 8) |
                    uint32(uint8(data[index + 2]));
                index += 3;
            } else if (valueType == 0x1a) {
                value = uint32(
                    (uint32(uint8(data[index + 1])) << 24) |
                        (uint32(uint8(data[index + 2])) << 16) |
                        (uint32(uint8(data[index + 3])) << 8) |
                        uint32(uint8(data[index + 4]))
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

    /// @dev Prepare address parameter for a method call by serializing it.
    /// @param addr The address of the account.
    /// @return params The serialized address as CBOR bytes.
    function prepareParams(address addr) internal pure returns (bytes memory) {
        CommonTypes.FilAddress memory filAddr = FilAddresses.fromEthAddress(
            addr
        );
        return FilecoinCBOR.serializeAddress(filAddr);
    }

    /// @dev Read from a wasm actor with empty params.
    /// @param actorId The actor ID.
    /// @param methodNum The method number.
    /// @return data The data returned from the actor.
    function readFromWasmActor(
        CommonTypes.FilActorId actorId,
        uint64 methodNum
    ) internal view returns (bytes memory) {
        bytes memory params = new bytes(0);
        (int256 exit, bytes memory data) = Actor.callByIDReadOnly(
            actorId,
            methodNum,
            EMPTY_CODEC,
            params
        );

        require(exit == 0, "Actor returned an error");
        return data;
    }

    /// @dev Read from a wasm actor with encoded params.
    /// @param actorId The actor ID.
    /// @param methodNum The method number.
    /// @param params The parameters.
    /// @return data The data returned from the actor.
    function readFromWasmActor(
        CommonTypes.FilActorId actorId,
        uint64 methodNum,
        bytes memory params
    ) internal view returns (bytes memory) {
        require(params.length > 0, "Params must be non-empty");
        (int256 exit, bytes memory data) = Actor.callByIDReadOnly(
            actorId,
            methodNum,
            CBOR_CODEC,
            params
        );

        require(exit == 0, "Actor returned an error");
        return data;
    }

    /// @dev Write to a wasm actor.
    /// @param actorId The actor ID.
    /// @param methodNum The method number.
    /// @param params The parameters.
    /// @return data The data returned from the actor.
    function writeToWasmActor(
        CommonTypes.FilActorId actorId,
        uint64 methodNum,
        bytes memory params
    ) internal returns (bytes memory) {
        require(params.length > 0, "Params must be non-empty");
        uint64 codec = CBOR_CODEC;
        uint256 value = msg.value > 0 ? msg.value : 0;
        (int256 exit, bytes memory data) = Actor.callByID(
            actorId,
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
