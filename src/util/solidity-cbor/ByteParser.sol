//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Helpful byte utility functions.
/// Returns decoded CBOR values as their proper types.
library ByteParser {
    uint256 private constant MAX_UINT64 = 0xFFFFFFFFFFFFFFFF;

    /// @dev Converts a CBOR dynamic bytes array to a uint64
    /// @param data dynamic bytes array
    /// @return value calculated uint64 value
    function bytesToUint64(bytes memory data) public pure returns (uint64 value) {
        require(value <= MAX_UINT64, "Number too large! Use `bytesToBigNumber` instead!");
        value = uint64(bytesToBigNumber(data));
    }

    /// @dev Converts a CBOR dynamic bytes array to an int128
    /// @param data dynamic bytes array
    /// @return value calculated uint64 value
    function bytesToNegativeInt128(bytes memory data) public pure returns (int128 value) {
        value = -1 - int64(bytesToUint64(data));
    }

    /// @dev Converts a CBOR dynamic bytes array to a string
    /// @param data dynamic bytes array
    /// @return value converted string object
    function bytesToString(bytes memory data) public pure returns (string memory value) {
        value = string(data);
    }

    /// @dev Converts a CBOR dynamic bytes array to a uint256
    /// @param data dynamic bytes array
    /// @return value calculated uint256 value
    function bytesToBigNumber(bytes memory data) public pure returns (uint256 value) {
        require(data.length <= 64, "Value too large!");
        for (uint256 i = 0; i < data.length; i++) {
            value += uint8(data[i]) * uint256(2 ** (8 * (data.length - (i + 1))));
        }
    }

    /// @dev Converts a CBOR dynamic bytes array to a bool
    /// @param data dynamic bytes array
    /// @return value calculated bool value
    function bytesToBool(bytes memory data) public pure returns (bool value) {
        require(data.length == 1, "Data is not a boolean!");
        uint8 boolean = uint8(data[0]);
        if (boolean == 1) {
            value = true;
        } else if (boolean == 0) {
            value = false;
        } else {
            revert("Improper boolean!");
        }
    }

    /// @dev Converts a CBOR dynamic bytes array to an address type
    /// @param data dynamic bytes array
    /// @return value translated address
    function parseAddr(bytes memory data) public pure returns (address value) {
        /// The following function has been written by the Oraclize team, use it under the terms of the MIT license.
        /// https://github.com/provable-things/ethereum-api/blob/9f34daaa550202c44f48cdee7754245074bde65d/oraclizeAPI_0.5.sol#L872-L898
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint256 i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(data[i]));
            b2 = uint160(uint8(data[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        value = address(iaddr);
    }
}
