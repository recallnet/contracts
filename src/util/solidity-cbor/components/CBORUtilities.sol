//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORSpec as Spec} from "./CBORSpec.sol";
import {CBORByteUtils as ByteUtils} from "./CBORByteUtils.sol";

/**
 * @dev Solidity library built for decoding CBOR data.
 *
 */
abstract contract CBORUtilities is ByteUtils, Spec {
    /**
     * @dev Extracts the data from CBOR-encoded type.
     * @param encoding the dynamic bytes array to slice from
     * @param majorType the correspondnig data type being used
     * @param start position where type starts (in bytes)
     * @param end position where the type ends (in bytes)
     * @return value a cloned dynamic bytes array with the data value
     */
    function extractValue(
        bytes memory encoding,
        /*Spec.*/
        MajorType majorType,
        uint8 shortCount,
        uint256 start,
        uint256 end
    ) internal pure returns (bytes memory value) {
        if (start != end) {
            // If we have a payload/count, slice it and short-circuit
            value = /*ByteUtils.*/ sliceBytesMemory(encoding, start, end);
        } else if (majorType /*Spec.*/ == MajorType.Special) {
            // Special means data is encoded INSIDE field
            if (shortCount == 21) {
                // True
                value = abi.encodePacked(/*Spec.*/ UINT_TRUE);
            } else if (
                // Falsy
                shortCount == 20 || // false
                shortCount == 22 || // null
                shortCount == 23 // undefined
            ) {
                value = abi.encodePacked(/*Spec.*/ UINT_FALSE);
            }
        }
        // Data IS the shortCount (<24)
        else {
            value = abi.encodePacked(shortCount);
        }

        return value;
    }

    /**
     * @dev Parses a CBOR byte into major type and short count.
     * See https://en.wikipedia.org/wiki/CBOR for reference.
     * @param fieldEncoding the field to encode
     * @return majorType corresponding data type (see RFC8949 section 3.2)
     * @return shortCount corresponding short count (see RFC8949 section 3)
     */
    function parseFieldEncoding(
        bytes1 fieldEncoding
    )
        internal
        pure
        returns (
            /*Spec.*/
            MajorType majorType,
            uint8 shortCount
        )
    {
        uint8 data = uint8(fieldEncoding);
        majorType = /*Spec.*/ MajorType((data /*Spec.*/ & MAJOR_BITMASK) >> 5);
        shortCount = data /*Spec.*/ & SHORTCOUNT_BITMASK;
    }

    // Convert an hexadecimal character to their value
    function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        }
        if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        }
        if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
            return 10 + c - uint8(bytes1("A"));
        }
        revert("fail");
    }

    // Convert an hexadecimal string to raw bytes
    function fromHex(string memory s) public pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length % 2 == 0); // length must be even
        bytes memory r = new bytes(ss.length / 2);
        for (uint256 i = 0; i < ss.length / 2; ++i) {
            r[i] = bytes1(
                fromHexChar(uint8(ss[2 * i])) *
                    16 +
                    fromHexChar(uint8(ss[2 * i + 1]))
            );
        }
        return r;
    }
}
