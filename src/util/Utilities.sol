// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Utilities {
    /// @dev Environment helper for setting the chain environment in scripts or contracts.
    /// - Local: Local (localnet or devnet)
    /// - Testnet: Testnet environment
    /// - Mainnet: Mainnet environment
    enum Environment {
        Local,
        Testnet,
        Mainnet
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
        bytes calldata data
    ) public pure returns (uint256) {
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
                value = uint16(bytes2(data[index + 1:index + 3]));
                index += 3;
            } else if (valueType == 0x1a) {
                value = uint32(bytes4(data[index + 1:index + 5]));
                index += 5;
            } else {
                revert("Unsupported integer type");
            }

            result |= uint256(value) << shift;
            shift += 32;
        }

        return result;
    }
}
