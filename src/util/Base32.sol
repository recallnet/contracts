// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

/// @dev Base32 encoding and decoding library.
library Base32 {
    /// @dev Decode a base32 encoded string to bytes.
    /// @param input The base32 encoded string (all lowercase) as bytes.
    /// @return output The decoded bytes.
    function decode(bytes memory input) internal pure returns (bytes memory) {
        uint256 length = input.length;
        uint256 outputLength = (length * 5) / 8;
        bytes memory output = new bytes(outputLength);

        assembly {
            let inputPtr := add(input, 32)
            let outputPtr := add(output, 32)
            let endPtr := add(inputPtr, length)
            let bits := 0
            let value := 0
            let index := 0

            for {} lt(inputPtr, endPtr) {} {
                let char := byte(0, mload(inputPtr))

                // Read the character value from the base32 alphabet
                let charValue := 0xFF
                for { let i := 0 } lt(i, 32) { i := add(i, 1) } {
                    // Lowercase base32 alphabet (abcdefghijklmnopqrstuvwxyz234567) represented as bytes
                    if eq(char, byte(i, 0x6162636465666768696a6b6c6d6e6f707172737475767778797a323334353637)) {
                        charValue := i
                        break
                    }
                }
                if eq(charValue, 0xFF) { revert(0, 0) } // Invalid base32 character

                value := or(shl(5, value), charValue)
                bits := add(bits, 5)

                if iszero(lt(bits, 8)) {
                    mstore8(add(outputPtr, index), shr(sub(bits, 8), value))
                    index := add(index, 1)
                    bits := sub(bits, 8)
                }

                inputPtr := add(inputPtr, 1)
            }
        }

        return output;
    }

    /// @dev Encode bytes to a base32 string.
    /// @param input The bytes to encode.
    /// @return output The base32 encoded string.
    function encode(bytes memory input) internal pure returns (bytes memory) {
        uint256 length = input.length;
        uint256 outputLength = ((length * 8) + 4) / 5; // Round up to nearest multiple of 5 bits
        bytes memory output = new bytes(outputLength);

        assembly {
            let inputPtr := add(input, 32)
            let outputPtr := add(output, 32)
            let endPtr := add(inputPtr, length)
            let bits := 0
            let value := 0
            let index := 0

            for {} lt(inputPtr, endPtr) {} {
                value := shl(8, value)
                value := or(value, byte(0, mload(inputPtr)))
                bits := add(bits, 8)

                for {} iszero(lt(bits, 5)) {} {
                    bits := sub(bits, 5)
                    let charValue := and(shr(bits, value), 0x1F)
                    // Base32 alphabet (abcdefghijklmnopqrstuvwxyz234567)
                    let char := byte(charValue, 0x6162636465666768696a6b6c6d6e6f707172737475767778797a323334353637)
                    mstore8(add(outputPtr, index), char)
                    index := add(index, 1)
                }

                inputPtr := add(inputPtr, 1)
            }

            // Handle remaining bits
            if gt(bits, 0) {
                let charValue := and(shl(sub(5, bits), value), 0x1F)
                let char := byte(charValue, 0x6162636465666768696a6b6c6d6e6f707172737475767778797a323334353637)
                mstore8(add(outputPtr, index), char)
            }
        }

        return output;
    }
}
