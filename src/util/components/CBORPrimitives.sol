//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORSpec as Spec} from "./CBORSpec.sol";
import {CBORUtilities as Utils} from "./CBORUtilities.sol";
import {CBORByteUtils as ByteUtils} from "./CBORByteUtils.sol";

/**
 * @dev Parses out CBOR primitive values
 * `CBORDataStructures.sol` handles hashes and arrays.
 *
 */
abstract contract CBORPrimitives {
    /**
     * @dev Parses a CBOR-encoded integer and determines where data start/ends.
     * @param cursor position where integer starts (in bytes)
     * @param shortCount short data identifier included in field info
     * @return dataStart byte position where data starts
     * @return dataEnd byte position where data ends
     */
    function parseInteger(
        /* We don't need encodings to tell how long (bytes) the integer is */
        /*bytes memory encoding,*/
        uint256 cursor,
        uint256 shortCount
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

    /**
     * @dev Parses a CBOR-encoded special type.
     * @param cursor position where integer starts (in bytes)
     * @param shortCount short data identifier included in field info
     * @return dataStart byte position where data starts
     * @return dataEnd byte position where data ends
     */
    function parseSpecial(
        /*bytes memory encoding,*/
        uint256 cursor,
        uint256 shortCount
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
