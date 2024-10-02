//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORByteUtils as ByteUtils} from "./CBORByteUtils.sol";
import {CBORSpec as Spec} from "./CBORSpec.sol";
import {CBORUtilities as Utils} from "./CBORUtilities.sol";

/// @dev Parses out CBOR primitive values
/// `CBORDataStructures.sol` handles hashes and arrays.
library CBORPrimitives {
    /// @dev Parses a CBOR-encoded integer and determines where data start/ends.
    /// @param cursor position where integer starts (in bytes)
    /// @param shortCount short data identifier included in field info
    /// @return dataStart byte position where data starts
    /// @return dataEnd byte position where data ends
    function parseInteger(
        /* We don't need encodings to tell how long (bytes) the integer is */
        /*bytes memory encoding,*/
        uint256 cursor,
        uint8 shortCount
    ) internal pure returns (uint256 dataStart, uint256 dataEnd) {
        // Save our starting cursor (past the field encoding)
        dataStart = cursor + 1;

        // Marker for how far count goes
        dataEnd = dataStart;

        // Predetermined sizes
        if (shortCount < 24) {
            // Shortcount IS the value, mark it special by returning cursor=start=end
            // TODO - maybe update this to (dataStart, dataEnd)
            return (cursor, cursor);
        } else if (shortCount == 24) {
            dataEnd += 1;
        } else if (shortCount == 25) {
            dataEnd += 2;
        } else if (shortCount == 26) {
            dataEnd += 4;
        } else if (shortCount == 27) {
            dataEnd += 8;
        } else if (shortCount >= 28) {
            revert("Invalid integer RFC Shortcode!");
        }
    }

    /// @dev Parses a CBOR-encoded strings and determines where data start/ends.
    /// @param encoding the dynamic bytes array to scan
    /// @param cursor position where integer starts (in bytes)
    /// @param shortCount short data identifier included in field info
    /// @return dataStart byte position where data starts
    /// @return dataEnd byte position where data ends
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
            (, dataEnd) = Utils.scanIndefiniteItems(encoding, dataStart, 0);
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
        uint256 count = ByteUtils.bytesToUint256(ByteUtils.sliceBytesMemory(encoding, countStart, countEnd));

        // Data starts on the next byte (non-inclusive)
        // Empty strings cannot exist at this stage (short-circuited above)
        dataStart = countEnd;
        dataEnd = countEnd + count;

        return (dataStart, dataEnd);
    }

    /// @dev Parses a CBOR-encoded tag type (big nums).
    /// @param encoding the dynamic bytes array to scan
    /// @param cursor position where integer starts (in bytes)
    /// @param shortCount short data identifier included in field info
    /// @return dataStart byte position where data starts
    /// @return dataEnd byte position where data ends
    function parseSemantic(bytes memory encoding, uint256 cursor, uint256 shortCount)
        internal
        view
        returns (uint256 dataStart, uint256 dataEnd)
    {
        // Check for BigNums
        if (shortCount == Spec.TAG_TYPE_BIGNUM || shortCount == Spec.TAG_TYPE_NEGATIVE_BIGNUM) {
            // String-encoded bignum will start at next byte
            cursor++;
            // Forward request to parseString (bignums are string-encoded)
            (, shortCount) = Utils.parseFieldEncoding(encoding[cursor]);
            (dataStart, dataEnd) = parseString(encoding, cursor, shortCount);
        } else {
            revert("Unsupported Tag Type!");
        }

        return (dataStart, dataEnd);
    }

    /// @dev Parses a CBOR-encoded special type.
    /// @param cursor position where integer starts (in bytes)
    /// @param shortCount short data identifier included in field info
    /// @return dataStart byte position where data starts
    /// @return dataEnd byte position where data ends
    function parseSpecial(
        /*bytes memory encoding,*/
        uint256 cursor,
        uint8 shortCount
    ) internal pure returns (uint256 dataStart, uint256 dataEnd) {
        // Save our starting cursor (data can exist here)
        dataStart = cursor + 1;

        // Marker for how far count goes
        dataEnd = dataStart;

        // Predetermined sizes
        if (shortCount <= 19 || shortCount >= 28) {
            revert("Invalid special RFC Shortcount!");
        } else if (shortCount >= 20 && shortCount <= 23) {
            // 20-23 are false, true, null, and undefined (respectively).
            // There's no extra data to grab.
            return (cursor, cursor);
        } else if (shortCount >= 24 && shortCount <= 27) {
            revert("Unimplemented Shortcount!");
        }
        // NOTE: - floats could be implemented in the future if needed
        // else if (shortCount == 24) dataEnd += 1;
        // else if (shortCount == 25) dataEnd += 2;
        // else if (shortCount == 26) dataEnd += 4;
        // else if (shortCount == 27) dataEnd += 8;

        // return (dataStart, dataEnd);
    }
}
