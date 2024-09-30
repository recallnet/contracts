//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORSpec as Spec} from "./CBORSpec.sol";
import {CBORPrimitives as Primitives} from "./CBORPrimitives.sol";
import {CBORDataStructures as DataStructures} from "./CBORDataStructures.sol";
import {CBORByteUtils as ByteUtils} from "./CBORByteUtils.sol";

/**
 * @dev Solidity library built for decoding CBOR data.
 *
 */
library CBORUtilities {
    /**
     * @dev Intelligently parses supported CBOR-encoded types.
     * @param encoding the dynamic bytes array
     * @param cursor position where type starts (in bytes)
     * @return majorType the type of the data sliced
     * @return shortCount the corresponding shortCount for the data
     * @return start position where the data starts (in bytes)
     * @return end position where the data ends (in bytes)
     * @return next position to find the next field (in bytes)
     */
    function parseField(
        bytes memory encoding,
        uint256 cursor
    )
        internal
        view
        returns (
            Spec.MajorType majorType,
            uint8 shortCount,
            uint256 start,
            uint256 end,
            uint256 next
        )
    {
        // Parse field encoding
        (majorType, shortCount) = parseFieldEncoding(encoding[cursor]);

        // Switch case on data type

        // Integers (Major Types: 0,1)
        if (
            majorType == Spec.MajorType.UnsignedInteger ||
            majorType == Spec.MajorType.NegativeInteger
        )
            (start, end) = Primitives.parseInteger(cursor, shortCount);

            // Strings (Major Types: 2,3)
        else if (
            majorType == Spec.MajorType.ByteString ||
            majorType == Spec.MajorType.TextString
        )
            (start, end) = Primitives.parseString(encoding, cursor, shortCount);

            // Arrays (Major Type: 4,5)
        else if (
            majorType == Spec.MajorType.Array || majorType == Spec.MajorType.Map
        )
            (start, end) = DataStructures.parseDataStructure(
                encoding,
                cursor,
                majorType,
                shortCount
            );

            // Semantic Tags (Major Type: 6)
        else if (majorType == Spec.MajorType.Semantic)
            (start, end) = Primitives.parseSemantic(
                encoding,
                cursor,
                shortCount
            );

            // Special / Floats (Major Type: 7)
        else if (majorType == Spec.MajorType.Special)
            (start, end) = Primitives.parseSpecial(cursor, shortCount);

            // Unsupported types (shouldn't ever really)
        else revert("Unimplemented Major Type!");

        // `end` is non-inclusive
        next = end;
        // If our data exists at field definition, nudge the cursor one
        if (start == end) next++;

        return (majorType, shortCount, start, end, next);
    }

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
        Spec.MajorType majorType,
        uint8 shortCount,
        uint256 start,
        uint256 end
    ) internal pure returns (bytes memory value) {
        if (start != end)
            // If we have a payload/count, slice it and short-circuit
            value = ByteUtils.sliceBytesMemory(encoding, start, end);
        else if (majorType == Spec.MajorType.Special) {
            // Special means data is encoded INSIDE field
            if (shortCount == 21)
                // True
                value = abi.encodePacked(Spec.UINT_TRUE);
            else if (
                // Falsy
                shortCount == 20 || // false
                shortCount == 22 || // null
                shortCount == 23 // undefined
            ) value = abi.encodePacked(Spec.UINT_FALSE);
        }
        // Data IS the shortCount (<24)
        else value = abi.encodePacked(shortCount);

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
    ) internal pure returns (Spec.MajorType majorType, uint8 shortCount) {
        uint8 data = uint8(fieldEncoding);
        majorType = Spec.MajorType((data & Spec.MAJOR_BITMASK) >> 5);
        shortCount = data & Spec.SHORTCOUNT_BITMASK;
    }

    /**
     * @notice If data structures are nested, this will be a recursive function.
     * @dev Counts encoded items until a BREAK or the end of the bytes.
     * @param encoding the encoded bytes array
     * @param cursor where to start scanning
     * @param maxItems once this number of items is reached, return. Set 0 for infinite
     * @return totalItems total items found in encoding
     * @return endCursor cursor position after scanning (non-inclusive)
     */
    function scanIndefiniteItems(
        bytes memory encoding,
        uint256 cursor,
        uint256 maxItems
    ) internal view returns (uint256 totalItems, uint256 endCursor) {
        // Loop through our indefinite-length number until break marker
        for (; cursor < encoding.length; totalItems++) {
            // If we're at a BREAK_MARKER
            if (encoding[cursor] == Spec.BREAK_MARKER) break;
            // If we've reached our max items
            else if (maxItems != 0 && totalItems == maxItems) break;

            // See where the next field starts
            (
                ,
                ,
                ,
                ,
                /*majorType*/ /*shortCount*/ /*start*/ /*end*/ uint next
            ) = parseField(encoding, cursor);

            // Update our cursor
            cursor = next;
        }

        return (totalItems, cursor);
    }
}
