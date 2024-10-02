//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORByteUtils as ByteUtils} from "./CBORByteUtils.sol";
import {CBORSpec as Spec} from "./CBORSpec.sol";
import {CBORUtilities as Utils} from "./CBORUtilities.sol";

/// @dev Solidity library built for decoding CBOR data.
library CBORDataStructures {
    /// @dev Parses a CBOR-encoded mapping into a 2d-array of bytes.
    /// @param encoding the dynamic bytes array to scan
    /// @param cursor position where mapping starts (in bytes)
    /// @param shortCount short data identifier included in field info
    /// @return decodedMapping the mapping decoded
    function expandMapping(bytes memory encoding, uint256 cursor, uint8 shortCount)
        internal
        view
        returns (bytes[2][] memory decodedMapping)
    {
        // Track our mapping start
        uint256 mappingCursor = cursor;

        // Count up how many keys we have, set cursor
        (uint256 totalItems, uint256 dataStart,) =
            getDataStructureItemLength(encoding, mappingCursor, Spec.MajorType.Map, shortCount);
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
                Utils.parseField(encoding, mappingCursor);

            // Save our data
            decodedMapping[pair][arrayIdx] = Utils.extractValue(encoding, majorType, sc, start, end);

            // Update our cursor
            mappingCursor = next;
        }

        return decodedMapping;
    }

    /// @dev Parses a CBOR-encoded array into an array of bytes.
    /// @param encoding the dynamic bytes array to scan
    /// @param cursor position where array starts (in bytes)
    /// @param shortCount short data identifier included in field info
    /// @return decodedArray the array decoded
    function expandArray(bytes memory encoding, uint256 cursor, uint8 shortCount)
        internal
        view
        returns (bytes[] memory decodedArray)
    {
        // Track our array start
        uint256 arrayCursor = cursor;

        // Count up how many keys we have, set cursor
        (uint256 totalItems, uint256 dataStart,) =
            getDataStructureItemLength(encoding, arrayCursor, Spec.MajorType.Array, shortCount);
        arrayCursor = dataStart;

        // Allocate new array
        decodedArray = new bytes[](totalItems);

        // Position cursor and Pull out our data
        for (uint256 item = 0; item < totalItems; item++) {
            // See what our field looks like
            (Spec.MajorType majorType, uint8 sc, uint256 start, uint256 end, uint256 next) =
                Utils.parseField(encoding, arrayCursor);

            // Save our data
            decodedArray[item] = Utils.extractValue(encoding, majorType, sc, start, end);

            // Update our cursor
            arrayCursor = next;
        }

        return decodedArray;
    }

    /// @dev Returns the number of items (not pairs) and where values start/end.
    /// @param encoding the dynamic bytes array to scan
    /// @param cursor position where mapping data starts (in bytes)
    /// @param majorType the corresponding major type identifier
    /// @param shortCount short data identifier included in field info
    /// @return dataStart the position where the values for the structure begin.
    /// @return dataEnd the position where the values for the structure end.
    function parseDataStructure(bytes memory encoding, uint256 cursor, Spec.MajorType majorType, uint8 shortCount)
        internal
        view
        returns (uint256 dataStart, uint256 dataEnd)
    {
        uint256 totalItems;
        // Count how many items we have, also get start position and *maybe* end (see notice).
        (totalItems, dataStart, dataEnd) = getDataStructureItemLength(encoding, cursor, majorType, shortCount);

        // If we have an empty array, we know the end
        if (totalItems == 0) dataEnd = dataStart;

        // If didn't get dataEnd (scoreCode != 31), we need to manually fetch dataEnd
        if (dataEnd == 0) {
            (, dataEnd) = Utils.scanIndefiniteItems(encoding, dataStart, totalItems);
        }

        // If it's not the first array expansion, include data structure header for future decoding.
        // We cannot return a recusively decoded structure due to polymorphism limitations
        if (cursor != 0) {
            dataStart = cursor;

            // If we have an end marker, we need to skip past that too
            if (shortCount == 31) dataEnd++;
        }

        return (dataStart, dataEnd);
    }

    /// @notice Use `parseDataStructure` instead. This is for internal usage.
    /// Please take care when using `dataEnd`! This value is ONLY set if the data
    /// structure uses an indefinite amount of items, optimizing the efficiency when
    /// doing an initial scan to allocate arrays. If the value is not 0, the value
    /// can be relied on.
    /// @dev Returns the number of items (not pairs) in a data structure.
    /// @param encoding the dynamic bytes array to scan
    /// @param cursor position where mapping starts (in bytes)
    /// @param majorType the corresponding major type identifier
    /// @param shortCount short data identifier included in field info
    /// @return totalItems the number of total items in the data structure
    /// @return dataStart the position where the values for the structure begin.
    /// @return dataEnd the position where the values for the structure end.
    function getDataStructureItemLength(
        bytes memory encoding,
        uint256 cursor,
        Spec.MajorType majorType,
        uint8 shortCount
    ) internal view returns (uint256 totalItems, uint256 dataStart, uint256 dataEnd) {
        // Setup extended count (currently none)
        uint256 countStart = cursor + 1;
        uint256 countEnd = countStart;

        if (shortCount == 31) {
            // Indefinite count
            // Loop through our indefinite-length structure until break marker.
            (totalItems, dataEnd) = Utils.scanIndefiniteItems(encoding, countEnd, 0);
            // Data starts right where count ends (which is cursor+1)
            dataStart = countEnd;
            return (totalItems, dataStart, dataEnd);
        } else if (shortCount < 24) {
            // Count is stored in shortCount, we can short-circuit and end early
            totalItems = shortCount;
            if (majorType == Spec.MajorType.Map) totalItems *= 2;
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
        totalItems = ByteUtils.bytesToUint256(ByteUtils.sliceBytesMemory(encoding, countStart, countEnd));

        // Maps count pairs, NOT items. We want items
        if (majorType == Spec.MajorType.Map) totalItems *= 2;

        // Recalculate where our data starts
        dataStart = countEnd;

        return (totalItems, dataStart, 0); // 0 because we don't know where the data will end
    }
}
