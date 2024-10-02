//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORByteUtils as ByteUtils} from "./components/CBORByteUtils.sol";
import {CBORDataStructures as DataStructures} from "./components/CBORDataStructures.sol";
import {CBORPrimitives as Primitives} from "./components/CBORPrimitives.sol";
import {CBORSpec as Spec} from "./components/CBORSpec.sol";
import {CBORUtilities as Utils} from "./components/CBORUtilities.sol";

/**
 * @dev Solidity library built for decoding CBOR data.
 *
 */
library CBORDecoding {
    /**
     *
     * Mappings *
     *
     */

    /**
     * @dev Parses an encoded CBOR Mapping into a 2d array of data
     * @param encoding Encoded CBOR bytes data
     * @return decodedData Decoded CBOR data (returned in 2d array).
     * Interpretting this bytes data from bytes to it's proper object is up
     * to the implementer.
     */
    function decodeMapping(bytes memory encoding) external view returns (bytes[2][] memory decodedData) {
        uint256 cursor = 0;
        // Type check
        (Spec.MajorType majorType, uint8 shortCount) = Utils.parseFieldEncoding(encoding[cursor]);
        require(majorType == Spec.MajorType.Map, "Object is not a mapping!");

        // Decode and return
        decodedData = DataStructures.expandMapping(encoding, cursor, shortCount);
        return decodedData;
    }

    /**
     *
     * Arrays *
     *
     */

    /**
     * @dev Parses an encoded CBOR array into a bytes array of its data
     * @param encoding Encoded CBOR bytes data
     * @return decodedData Decoded CBOR data (returned in array).
     * Interpretting this bytes data from bytes to it's proper object is up
     * to the implementer.
     */
    function decodeArray(bytes memory encoding) external view returns (bytes[] memory decodedData) {
        uint256 cursor = 0;
        // Type check
        (Spec.MajorType majorType, uint8 shortCount) = Utils.parseFieldEncoding(encoding[cursor]);
        require(majorType == Spec.MajorType.Array, "Object is not an array!");

        // Decode and return
        decodedData = DataStructures.expandArray(encoding, cursor, shortCount);
        return decodedData;
    }

    /**
     *
     * Primitives *
     *
     */

    /**
     * @dev Parses an encoded CBOR dynamic bytes array into it's array of data
     * @param encoding Encoded CBOR bytes data
     * @return decodedData Decoded CBOR data (returned in structs).
     * Interpretting this bytes data from bytes to it's proper object is up
     * to the implementer.
     */
    function decodePrimitive(bytes memory encoding) external view returns (bytes memory decodedData) {
        uint256 cursor = 0;
        // See what our field looks like
        (Spec.MajorType majorType, uint8 shortCount, uint256 start, uint256 end, /*next*/ ) =
            Utils.parseField(encoding, cursor);
        require(majorType != Spec.MajorType.Array && majorType != Spec.MajorType.Map, "Encoding is not a primitive!");

        // Save our data
        decodedData = Utils.extractValue(encoding, majorType, shortCount, start, end);
        return decodedData;
    }

    // /**********************
    //  * Searching Mappings *
    //  *********************/

    /**
     * @dev Performs linear search through mapping for a key.
     * This is much cheaper than decoding an entire mapping and
     * then searching through it for a key.
     * @param encoding encoded CBOR bytes data
     * @param searchKey key to search for
     * @return value decoded CBOR data as bytes
     */
    function decodeMappingGetValue(bytes memory encoding, bytes memory searchKey)
        external
        view
        returns (bytes memory value)
    {
        // Search parameters
        uint256 cursor;
        bytes32 searchKeyHash = keccak256(searchKey);
        bool keyFound = false;

        {
            // Ensure we start with a mapping
            (Spec.MajorType majorType, uint8 shortCount) = Utils.parseFieldEncoding(encoding[0]);
            require(majorType == Spec.MajorType.Map, "Object is not a mapping!");

            // Figure out where cursor should start.
            if (shortCount == 31) {
                // Indefinite length, start at +1
                cursor++;
            }
            // Get cursor start position (either from count or shortcount)
            else {
                (, cursor,) = DataStructures.getDataStructureItemLength(encoding, cursor, majorType, shortCount);
            }
        }

        // Scan through our data
        for (uint256 itemIdx = 0; cursor < encoding.length; itemIdx++) {
            // Grab a key and it's value
            (Spec.MajorType majorType, uint8 shortCount, uint256 start, uint256 end, uint256 next) =
                Utils.parseField(encoding, cursor);

            // Update our cursor, skip every other item
            cursor = next;
            if (!keyFound && itemIdx % 2 != 0) continue;

            // Else extract item
            bytes memory currentItem = Utils.extractValue(encoding, majorType, shortCount, start, end);

            // If we found our key last iteration, this is our value (so we can return)
            if (keyFound) return currentItem;

            // This will trigger the item to be returned next time
            if (keccak256(currentItem) == searchKeyHash) keyFound = true;
        }
        // If the key doesn't exist, revert
        revert("Key not found!");
    }

    /**
     *
     * Searching Arrays *
     *
     */

    /**
     * @dev Performs linear loop through a CBOR array
     *  until `searchKey` is found, and returns the corresponding index.
     * @param encoding encoded CBOR bytes data
     * @param searchKey key to search for
     * @return index item position in items where item exists
     */
    function decodeArrayGetIndex(bytes memory encoding, bytes memory searchKey) external view returns (uint64 index) {
        // Search parameters
        uint256 cursor;
        bytes32 searchKeyHash = keccak256(searchKey);

        {
            // Ensure we start with a mapping
            (Spec.MajorType majorType, uint8 shortCount) = Utils.parseFieldEncoding(encoding[0]);
            require(majorType == Spec.MajorType.Array, "Object is not an array!");

            // Figure out where cursor should start.
            if (shortCount == 31) {
                // Indefinite length, start at +1
                cursor++;
            }
            // Get cursor start position (either from count or shortcount)
            else {
                (, cursor,) = DataStructures.getDataStructureItemLength(encoding, cursor, majorType, shortCount);
            }
        }

        // Scan through our data
        for (uint64 itemIdx = 0; cursor < encoding.length; itemIdx++) {
            // Grab a key and it's value
            (Spec.MajorType majorType, uint8 shortCount, uint256 start, uint256 end, uint256 next) =
                Utils.parseField(encoding, cursor);
            bytes memory currentItem = Utils.extractValue(encoding, majorType, shortCount, start, end);

            // This will trigger the item to be returned next time
            if (keccak256(currentItem) == searchKeyHash) return itemIdx;

            // Update our cursor
            cursor = next;
        }
        // If the key doesn't exist, revert
        revert("Item not found!");
    }

    /**
     * @dev Returns the value of the Nth item in an array.
     * @param encoding encoded CBOR bytes data
     * @param index Nth item index to grab
     * @return value decoded CBOR data as bytes
     */
    function decodeArrayGetItem(bytes memory encoding, uint64 index) external view returns (bytes memory value) {
        // Search parameters
        uint256 cursor;

        {
            // Ensure we start with a mapping
            (Spec.MajorType majorType, uint8 shortCount) = Utils.parseFieldEncoding(encoding[0]);
            require(majorType == Spec.MajorType.Array, "Object is not an array!");

            // Figure out where cursor should start.
            if (shortCount == 31) {
                // Indefinite length, start at +1
                cursor++;
            }
            // Get cursor start position (either from count or shortcount)
            else {
                (, cursor,) = DataStructures.getDataStructureItemLength(encoding, cursor, majorType, shortCount);
            }
        }

        // Scan through our data
        for (uint256 itemIdx = 0; cursor < encoding.length; itemIdx++) {
            // Grab the current item info, move cursor
            (Spec.MajorType majorType, uint8 shortCount, uint256 start, uint256 end, uint256 next) =
                Utils.parseField(encoding, cursor);

            // If this is our item, return
            if (index == itemIdx) {
                value = Utils.extractValue(encoding, majorType, shortCount, start, end);
                return value;
            }

            // Update cursor
            cursor = next;
        }
        // If the index doesn't exist in list, revert
        revert("Index provided larger than list!");
    }
}
