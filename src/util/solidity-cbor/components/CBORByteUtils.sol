//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Helpful byte utility functions.
library CBORByteUtils {
    /// @dev Slices a dynamic bytes object from start:end (non-inclusive end)
    /// @param start position to start byte slice (inclusive)
    /// @param end position to end byte slice (non-inclusive)
    /// @return slicedData dynamic sliced bytes object
    function sliceBytesMemory(bytes memory data, uint256 start, uint256 end)
        internal
        pure
        returns (bytes memory slicedData)
    {
        // Slice our bytes
        for (uint256 i = start; i < end; i++) {
            slicedData = abi.encodePacked(slicedData, data[i]);
        }
    }

    /// @dev Converts a dynamic bytes array to a uint256
    /// @param data dynamic bytes array
    /// @return value calculated uint256 value
    function bytesToUint256(bytes memory data) internal pure returns (uint256 value) {
        for (uint256 i = 0; i < data.length; i++) {
            value += uint8(data[i]) * (2 ** (8 * (data.length - (i + 1))));
        }
    }
}
