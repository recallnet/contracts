//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORSpec as Spec} from "./CBORSpec.sol";
import {CBORUtilities as Utils} from "./CBORUtilities.sol";
import {CBORByteUtils as ByteUtils} from "./CBORByteUtils.sol";
import {CBORPrimitives as Primitives} from "./CBORPrimitives.sol";

/**
 * @dev Solidity library built for decoding CBOR data.
 *
 */
abstract contract CBORDataStructures is ByteUtils, Primitives, Spec, Utils {
    /**
     * @dev Parses a CBOR-encoded strings and determines where data start/ends.
     * @param encoding the dynamic bytes array to scan
     * @param cursor position where integer starts (in bytes)
     * @param shortCount short data identifier included in field info
     * @return dataStart byte position where data starts
     * @return dataEnd byte position where data ends
     */
    function parseString(bytes memory encoding, uint256 cursor, uint256 shortCount)
        internal
        view
        returns (uint256 dataStart, uint256 dataEnd)
    {
        // Marker for how far count goes
        uint256 countStart = cursor + 1;
        uint256 countEnd = countStart;

        // These count lengths are (mostly) universal to all major types:
        if (shortCount == 0) {
            // We have an empty string, mark it special
            return (cursor, cursor);
        } else if (shortCount < 24) {
            // Count is stored in shortCount, we can short-circuit and end early
            dataStart = cursor + 1;
            dataEnd = dataStart + shortCount;
            return (dataStart, dataEnd);
        } else if (shortCount == 31) {
            // No count field, data starts right away.
            dataStart = cursor + 1;
            // Loop through our indefinite-length number until break marker
            (, dataEnd) = scanIndefiniteItems(encoding, dataStart, 0);
            return (dataStart, dataEnd);
        } else if (shortCount == 24) {
            countEnd += 1;
        } else if (shortCount == 25) {
            countEnd += 2;
        } else if (shortCount == 26) {
            countEnd += 4;
        } else if (shortCount == 27) {
            countEnd += 8;
        } else if (shortCount >= 28 && shortCount <= 30) {
            revert("Invalid string RFC Shortcode!");
        }

        // Calculate the value of the count
        uint256 count = /*ByteUtils.*/ bytesToUint256(
            /*ByteUtils.*/
            sliceBytesMemory(encoding, countStart, countEnd)
        );

        // Data starts on the next byte (non-inclusive)
        // Empty strings cannot exist at this stage (short-circuited above)
        dataStart = countEnd;
        dataEnd = countEnd + count;

        return (dataStart, dataEnd);
    }

    /**
     * @dev Parses a CBOR-encoded tag type (big nums).
     * @param encoding the dynamic bytes array to scan
     * @param cursor position where integer starts (in bytes)
     * @param shortCount short data identifier included in field info
     * @return dataStart byte position where data starts
     * @return dataEnd byte position where data ends
     */
    function parseSemantic(bytes memory encoding, uint256 cursor, uint256 shortCount)
        internal
        view
        returns (uint256 dataStart, uint256 dataEnd)
    {
        // Check for BigNums
        if (shortCount /*Spec.*/ == TAG_TYPE_BIGNUM || shortCount /*Spec.*/ == TAG_TYPE_NEGATIVE_BIGNUM) {
            // String-encoded bignum will start at next byte
            cursor++;
            // Forward request to parseString (bignums are string-encoded)
            (, shortCount) = /*Utils.*/ parseFieldEncoding(encoding[cursor]);
            (dataStart, dataEnd) = parseString(encoding, cursor, shortCount);
        } else {
            revert("Unsupported Tag Type!");
        }

        return (dataStart, dataEnd);
    }

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
    function parseField(bytes memory encoding, uint256 cursor)
        internal
        view
        returns (
            /*Spec.*/
            MajorType majorType,
            uint8 shortCount,
            uint256 start,
            uint256 end,
            uint256 next
        )
    {
        // Parse field encoding
        (majorType, shortCount) = /*Utils.*/ parseFieldEncoding(encoding[cursor]);

        // Switch case on data type

        // Integers (Major Types: 0,1)
        if (majorType /*Spec.*/ == MajorType.UnsignedInteger || majorType /*Spec.*/ == MajorType.NegativeInteger) {
            (start, end) = /*Primitives.*/ parseInteger(cursor, shortCount);
        }
        // Strings (Major Types: 2,3)
        else if (majorType /*Spec.*/ == MajorType.ByteString || majorType /*Spec.*/ == MajorType.TextString) {
            (start, end) = parseString(encoding, cursor, shortCount);
        }
        // Arrays (Major Type: 4,5)
        else if (majorType /*Spec.*/ == MajorType.Array || majorType /*Spec.*/ == MajorType.Map) {
            (start, end) = parseDataStructure(encoding, cursor, majorType, shortCount);
        }
        // Semantic Tags (Major Type: 6)
        else if (majorType /*Spec.*/ == MajorType.Semantic) {
            (start, end) = parseSemantic(encoding, cursor, shortCount);
        }
        // Special / Floats (Major Type: 7)
        else if (majorType /*Spec.*/ == MajorType.Special) {
            (start, end) = /*Primitives.*/ parseSpecial(cursor, shortCount);
        }
        // Unsupported types (shouldn't ever really)
        else {
            revert("Unimplemented Major Type!");
        }

        // `end` is non-inclusive
        next = end;
        // If our data exists at field definition, nudge the cursor one
        if (start == end) {
            next++;
        }

        return (majorType, shortCount, start, end, next);
    }

    /**
     * @dev Returns the number of items (not pairs) and where values start/end.
     * @param encoding the dynamic bytes array to scan
     * @param cursor position where mapping data starts (in bytes)
     * @param majorType the corresponding major type identifier
     * @param shortCount short data identifier included in field info
     * @return dataStart the position where the values for the structure begin.
     * @return dataEnd the position where the values for the structure end.
     */
    function parseDataStructure(
        bytes memory encoding,
        uint256 cursor,
        /*Spec.*/
        MajorType majorType,
        uint256 shortCount
    ) internal view returns (uint256 dataStart, uint256 dataEnd) {
        uint256 totalItems;
        // Count how many items we have, also get start position and *maybe* end (see notice).
        (totalItems, dataStart, dataEnd) = getDataStructureItemLength(encoding, cursor, majorType, shortCount);

        // If we have an empty array, we know the end
        if (totalItems == 0) {
            dataEnd = dataStart;
        }

        // If didn't get dataEnd (scoreCode != 31), we need to manually fetch dataEnd
        if (dataEnd == 0) {
            (, dataEnd) = scanIndefiniteItems(encoding, dataStart, totalItems);
        }

        // If it's not the first array expansion, include data structure header for future decoding.
        // We cannot return a recusively decoded structure due to polymorphism limitations
        if (cursor != 0) {
            dataStart = cursor;

            // If we have an end marker, we need to skip past that too
            if (shortCount == 31) {
                dataEnd++;
            }
        }

        return (dataStart, dataEnd);
    }

    /**
     * @notice Use `parseDataStructure` instead. This is for internal usage.
     * Please take care when using `dataEnd`! This value is ONLY set if the data
     * structure uses an indefinite amount of items, optimizing the efficiency when
     * doing an initial scan to allocate arrays. If the value is not 0, the value
     * can be relied on.
     * @dev Returns the number of items (not pairs) in a data structure.
     * @param encoding the dynamic bytes array to scan
     * @param cursor position where mapping starts (in bytes)
     * @param majorType the corresponding major type identifier
     * @param shortCount short data identifier included in field info
     * @return totalItems the number of total items in the data structure
     * @return dataStart the position where the values for the structure begin.
     * @return dataEnd the position where the values for the structure end.
     */
    function getDataStructureItemLength(
        bytes memory encoding,
        uint256 cursor,
        /*Spec.*/
        MajorType majorType,
        uint256 shortCount
    ) internal view returns (uint256 totalItems, uint256 dataStart, uint256 dataEnd) {
        // Setup extended count (currently none)
        uint256 countStart = cursor + 1;
        uint256 countEnd = countStart;

        if (shortCount == 31) {
            // Indefinite count
            // Loop through our indefinite-length structure until break marker.
            (totalItems, dataEnd) = scanIndefiniteItems(encoding, countEnd, 0);
            // Data starts right where count ends (which is cursor+1)
            dataStart = countEnd;
            return (totalItems, dataStart, dataEnd);
        } else if (shortCount < 24) {
            // Count is stored in shortCount, we can short-circuit and end early
            totalItems = shortCount;
            if (majorType /*Spec.*/ == MajorType.Map) {
                totalItems *= 2;
            }
            // Data starts right where count ends (which is cursor+1)
            dataStart = countEnd;
            return (totalItems, dataStart, 0); // 0 because we don't know where the data will end
        } else if (shortCount == 24) {
            countEnd += 1;
        } else if (shortCount == 25) {
            countEnd += 2;
        } else if (shortCount == 26) {
            countEnd += 4;
        } else if (shortCount == 27) {
            countEnd += 8;
        } else if (shortCount >= 28 && shortCount <= 30) {
            revert("Invalid data structure RFC Shortcode!");
        }

        // We have something we need to add up / interpret
        totalItems = /*ByteUtils.*/ bytesToUint256(
            /*ByteUtils.*/
            sliceBytesMemory(encoding, countStart, countEnd)
        );

        // Maps count pairs, NOT items. We want items
        if (majorType /*Spec.*/ == MajorType.Map) {
            totalItems *= 2;
        }

        // Recalculate where our data starts
        dataStart = countEnd;

        return (totalItems, dataStart, 0); // 0 because we don't know where the data will end
    }

    /**
     * @dev Parses a CBOR-encoded mapping into a 2d-array of bytes.
     * @param encoding the dynamic bytes array to scan
     * @param cursor position where mapping starts (in bytes)
     * @param shortCount short data identifier included in field info
     * @return decodedMapping the mapping decoded
     */
    function expandMapping(bytes memory encoding, uint256 cursor, uint8 shortCount)
        internal
        view
        returns (bytes[2][] memory decodedMapping)
    {
        // Track our mapping start
        uint256 mappingCursor = cursor;

        // Count up how many keys we have, set cursor
        (uint256 totalItems, uint256 dataStart,) =
            getDataStructureItemLength(encoding, mappingCursor, /*Spec.*/ MajorType.Map, shortCount);
        require(totalItems % 2 == 0, "Invalid mapping provided!");
        mappingCursor = dataStart;

        // Allocate new array
        decodedMapping = new bytes[2][](totalItems / 2);

        // Pull out our data
        for (uint256 item = 0; item < totalItems; item++) {
            // Determine the array we're modifying
            uint256 arrayIdx = item % 2; // Alternates 0,1,0,1,...
            uint256 pair = item / 2; // 0,0,1,1,2,2..

            // See what our field looks like
            (Spec.MajorType majorType, uint8 sc, uint256 start, uint256 end, uint256 next) =
                parseField(encoding, mappingCursor);

            // Save our data
            decodedMapping[pair][arrayIdx] = /*Utils.*/ extractValue(encoding, majorType, sc, start, end);

            // Update our cursor
            mappingCursor = next;
        }

        return decodedMapping;
    }

    /**
     * @dev Parses a CBOR-encoded array into an array of bytes.
     * @param encoding the dynamic bytes array to scan
     * @param cursor position where array starts (in bytes)
     * @param shortCount short data identifier included in field info
     * @return decodedArray the array decoded
     */
    function expandArray(bytes memory encoding, uint256 cursor, uint8 shortCount)
        internal
        view
        returns (bytes[] memory decodedArray)
    {
        // Track our array start
        uint256 arrayCursor = cursor;

        // Count up how many keys we have, set cursor
        (uint256 totalItems, uint256 dataStart,) =
            getDataStructureItemLength(encoding, arrayCursor, /*Spec.*/ MajorType.Array, shortCount);
        arrayCursor = dataStart;

        // Allocate new array
        decodedArray = new bytes[](totalItems);

        // Position cursor and Pull out our data
        for (uint256 item = 0; item < totalItems; item++) {
            // See what our field looks like
            (Spec.MajorType majorType, uint8 sc, uint256 start, uint256 end, uint256 next) =
                parseField(encoding, arrayCursor);

            // Save our data
            decodedArray[item] = /*Utils.*/ extractValue(encoding, majorType, sc, start, end);

            // Update our cursor
            arrayCursor = next;
        }

        return decodedArray;
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
    function scanIndefiniteItems(bytes memory encoding, uint256 cursor, uint256 maxItems)
        internal
        view
        returns (uint256 totalItems, uint256 endCursor)
    {
        // Loop through our indefinite-length number until break marker
        for (; cursor < encoding.length; totalItems++) {
            // If we're at a BREAK_MARKER
            if (encoding[cursor] /*Spec.*/ == BREAK_MARKER) {
                break;
            }
            // If we've reached our max items
            else if (maxItems != 0 && totalItems == maxItems) {
                break;
            }

            // See where the next field starts
            ( /*majorType*/ , /*shortCount*/, /*start*/, /*end*/, uint256 next) = parseField(encoding, cursor);

            // Update our cursor
            cursor = next;
        }

        return (totalItems, cursor);
    }
}
