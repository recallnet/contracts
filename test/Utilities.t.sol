// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Utilities} from "../src/util/Utilities.sol";

contract UtilitiesTest is Test {
    function setUp() public virtual {
        vm.createSelectFork("http://localhost:8545");
    }

    function testDecodeCBORArray() public pure {
        // Zero / empty array
        require(
            Utilities.decodeCborBigIntToUint256(hex"820080") == 0,
            "it should be zero for empty array"
        );
        require(
            Utilities.decodeCborBigIntToUint256(hex"82008100") == 0,
            "it should be zero for array with zero"
        );
        // 8 bits
        require(
            Utilities.decodeCborBigIntToUint256(hex"8201811801") == 1,
            "it should be one"
        );
        require(
            Utilities.decodeCborBigIntToUint256(hex"82018118ff") == 255,
            "it should be 255"
        );
        // 16 bits
        require(
            Utilities.decodeCborBigIntToUint256(hex"820181190100") == 256,
            "it should be 256"
        );
        require(
            Utilities.decodeCborBigIntToUint256(hex"820181190750") == 1872,
            "it should be 1872"
        );
        require(
            Utilities.decodeCborBigIntToUint256(hex"820181191290") == 4752,
            "it should be 4752"
        );
        require(
            Utilities.decodeCborBigIntToUint256(hex"820181194530") == 17712,
            "it should be 17712"
        );
        require(
            Utilities.decodeCborBigIntToUint256(hex"82018119ffff") == 65535,
            "it should be 65535"
        );
        // 32 bits
        require(
            Utilities.decodeCborBigIntToUint256(hex"8201811a00010000") == 65536,
            "it should be 65536"
        );
        require(
            Utilities.decodeCborBigIntToUint256(hex"8201811a00ffffff") ==
                16777215,
            "it should be 16777215"
        );
        require(
            Utilities.decodeCborBigIntToUint256(hex"8201811a01000000") ==
                16777216,
            "it should be 16777216"
        );
        // 40 bits
        require(
            Utilities.decodeCborBigIntToUint256(hex"8201821a000000001801") ==
                4294967296,
            "it should be 4294967296"
        );
        require(
            Utilities.decodeCborBigIntToUint256(hex"8201821affffffff18ff") ==
                1099511627775,
            "it should be 1099511627775"
        );
        // 48 bits
        require(
            Utilities.decodeCborBigIntToUint256(hex"8201821a00000000190001") ==
                4294967296,
            "it should be 4294967296"
        );
        require(
            Utilities.decodeCborBigIntToUint256(hex"8201821affffffff19ffff") ==
                281474976710655,
            "it should be 281474976710655"
        );
        // 64 bits
        require(
            Utilities.decodeCborBigIntToUint256(
                hex"8201821a000000001a00000001"
            ) == 4294967296,
            "it should be 4294967296"
        );
        require(
            Utilities.decodeCborBigIntToUint256(
                hex"8201821af62c00001a29a2241a"
            ) == 3000000000000000000,
            "it should be 3000000000000000000"
        );
        require(
            Utilities.decodeCborBigIntToUint256(
                hex"8201821affffffff1affffffff"
            ) == 18446744073709551615,
            "it should be 18446744073709551615"
        );
        // 96 bits
        require(
            Utilities.decodeCborBigIntToUint256(hex"8201831a0064291e0006") ==
                110680464442263873822,
            "it should be 110680464442263873822"
        );
        require(
            Utilities.decodeCborBigIntToUint256(
                hex"8201831a000000001a000000001a00000001"
            ) == 18446744073709551616,
            "it should be 18446744073709551616"
        );
        require(
            Utilities.decodeCborBigIntToUint256(
                hex"8201831affffffff1affffffff1affffffff"
            ) == 79228162514264337593543950335,
            "it should be 79228162514264337593543950335"
        );
        // 128 bits
        require(
            Utilities.decodeCborBigIntToUint256(
                hex"8201841a000000001a000000001a000000001a00000001"
            ) == 79228162514264337593543950336,
            "it should be 79228162514264337593543950336"
        );
        require(
            Utilities.decodeCborBigIntToUint256(
                hex"8201841affffffff1affffffff1affffffff1affffffff"
            ) == 340282366920938463463374607431768211455,
            "it should be 340282366920938463463374607431768211455"
        );
        // 256 bits
        require(
            Utilities.decodeCborBigIntToUint256(
                hex"8201881a000000001a000000001a000000001a000000001a000000001a000000001a000000001a00000001"
            ) ==
                26959946667150639794667015087019630673637144422540572481103610249216,
            "it should be 26959946667150639794667015087019630673637144422540572481103610249216"
        );
        require(
            Utilities.decodeCborBigIntToUint256(
                hex"8201881affffffff1affffffff1affffffff1affffffff1affffffff1affffffff1affffffff1affffffff"
            ) == type(uint256).max,
            "it should be uint256 max value"
        );
    }

    function testInvalidInput() public {
        // Test invalid initial array
        try Utilities.decodeCborBigIntToUint256(hex"810080") {
            fail();
        } catch Error(string memory reason) {
            assertEq(reason, "Must be array of 2 elements");
        }

        // Test invalid sign
        try Utilities.decodeCborBigIntToUint256(hex"820280") {
            fail();
        } catch Error(string memory reason) {
            assertEq(reason, "Invalid sign value");
        }

        // Test invalid inner array length
        try Utilities.decodeCborBigIntToUint256(hex"820189") {
            fail();
        } catch Error(string memory reason) {
            assertEq(reason, "Invalid array length");
        }
    }
}
