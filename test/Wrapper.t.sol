// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {Wrapper} from "../src/util/Wrapper.sol";

contract WrapperTest is Test {
    function setUp() public virtual {
        vm.createSelectFork("http://localhost:8545");
    }

    function testDecodeCborArray() public view {
        bytes[] memory array_null = Wrapper.decodeCborArrayToBytes(hex"f6");
        assertEq(array_null.length, 0);

        bytes[] memory array =
            Wrapper.decodeCborArrayToBytes(hex"85820181068201821a44c08d341a456391828201811936ba1a000af53da0");
        assertEq(array.length, 5);
        assertEq(array[0], hex"82018106");
        assertEq(array[1], hex"8201821a44c08d341a45639182");
        assertEq(array[2], hex"8201811936ba");
        assertEq(array[3], hex"000af53d");
        assertEq(array[4], hex"a0");
    }

    function testDecodeCborBigInt() public pure {
        // Zero, empty array, or null
        require(Wrapper.decodeCborBigIntToUint256(hex"820080") == 0, "it should be zero for empty array");
        require(Wrapper.decodeCborBigIntToUint256(hex"82008100") == 0, "it should be zero for array with zero");
        // Handles the case where WASM returns a null string for a BigInt
        require(
            Wrapper.decodeCborBigIntToUint256(hex"f6") == 0, "it should be zero if bigint serialized as null string"
        );
        // Handles the same case, but after the CBOR `decodeArray` helper converts to 0x00
        require(
            Wrapper.decodeCborBigIntToUint256(hex"00") == 0,
            "it should be zero if bigint serialized as already deserialized null string"
        );
        // 8 bits
        require(Wrapper.decodeCborBigIntToUint256(hex"8201811801") == 1, "it should be one");
        require(Wrapper.decodeCborBigIntToUint256(hex"82018118ff") == 255, "it should be 255");
        // 16 bits
        require(Wrapper.decodeCborBigIntToUint256(hex"820181190100") == 256, "it should be 256");
        require(Wrapper.decodeCborBigIntToUint256(hex"820181190750") == 1872, "it should be 1872");
        require(Wrapper.decodeCborBigIntToUint256(hex"820181191290") == 4752, "it should be 4752");
        require(Wrapper.decodeCborBigIntToUint256(hex"820181194530") == 17712, "it should be 17712");
        require(Wrapper.decodeCborBigIntToUint256(hex"82018119ffff") == 65535, "it should be 65535");
        // 32 bits
        require(Wrapper.decodeCborBigIntToUint256(hex"8201811a00010000") == 65536, "it should be 65536");
        require(Wrapper.decodeCborBigIntToUint256(hex"8201811a00ffffff") == 16777215, "it should be 16777215");
        require(Wrapper.decodeCborBigIntToUint256(hex"8201811a01000000") == 16777216, "it should be 16777216");
        // 40 bits
        require(Wrapper.decodeCborBigIntToUint256(hex"8201821a000000001801") == 4294967296, "it should be 4294967296");
        require(
            Wrapper.decodeCborBigIntToUint256(hex"8201821affffffff18ff") == 1099511627775, "it should be 1099511627775"
        );
        // 48 bits
        require(Wrapper.decodeCborBigIntToUint256(hex"8201821a00000000190001") == 4294967296, "it should be 4294967296");
        require(
            Wrapper.decodeCborBigIntToUint256(hex"8201821affffffff19ffff") == 281474976710655,
            "it should be 281474976710655"
        );
        // 64 bits
        require(
            Wrapper.decodeCborBigIntToUint256(hex"8201821a000000001a00000001") == 4294967296, "it should be 4294967296"
        );
        require(
            Wrapper.decodeCborBigIntToUint256(hex"8201821af62c00001a29a2241a") == 3000000000000000000,
            "it should be 3000000000000000000"
        );
        require(
            Wrapper.decodeCborBigIntToUint256(hex"8201821affffffff1affffffff") == 18446744073709551615,
            "it should be 18446744073709551615"
        );
        // 96 bits
        require(
            Wrapper.decodeCborBigIntToUint256(hex"8201831a0064291e0006") == 110680464442263873822,
            "it should be 110680464442263873822"
        );
        require(
            Wrapper.decodeCborBigIntToUint256(hex"8201831a000000001a000000001a00000001") == 18446744073709551616,
            "it should be 18446744073709551616"
        );
        require(
            Wrapper.decodeCborBigIntToUint256(hex"8201831affffffff1affffffff1affffffff")
                == 79228162514264337593543950335,
            "it should be 79228162514264337593543950335"
        );
        // 128 bits
        require(
            Wrapper.decodeCborBigIntToUint256(hex"8201841a000000001a000000001a000000001a00000001")
                == 79228162514264337593543950336,
            "it should be 79228162514264337593543950336"
        );
        require(
            Wrapper.decodeCborBigIntToUint256(hex"8201841affffffff1affffffff1affffffff1affffffff")
                == 340282366920938463463374607431768211455,
            "it should be 340282366920938463463374607431768211455"
        );
        // 256 bits
        require(
            Wrapper.decodeCborBigIntToUint256(
                hex"8201881a000000001a000000001a000000001a000000001a000000001a000000001a000000001a00000001"
            ) == 26959946667150639794667015087019630673637144422540572481103610249216,
            "it should be 26959946667150639794667015087019630673637144422540572481103610249216"
        );
        require(
            Wrapper.decodeCborBigIntToUint256(
                hex"8201881affffffff1affffffff1affffffff1affffffff1affffffff1affffffff1affffffff1affffffff"
            ) == type(uint256).max,
            "it should be uint256 max value"
        );
    }

    function externalDecodeCborBigIntToUint256(bytes memory input) external pure returns (uint256) {
        return Wrapper.decodeCborBigIntToUint256(input);
    }

    function testDecodeArray() public view {
        bytes memory input = hex"83f6f6820080";
        bytes[] memory array = Wrapper.decodeCborArrayToBytes(input);
        assertEq(array.length, 3);
        assertEq(array[0], hex"00");
        assertEq(array[1], hex"00");
        assertEq(array[2], hex"820080");
    }

    function testInvalidInitialArray() public view {
        bool hasError = false;
        try this.externalDecodeCborBigIntToUint256(hex"810080") {}
        catch Error(string memory reason) {
            hasError = true;
            assertEq(reason, "Must be array of 2 elements");
        }
        assertTrue(hasError, "Expected function to revert");
    }

    function testInvalidSign() public view {
        bool hasError = false;
        try this.externalDecodeCborBigIntToUint256(hex"820280") {}
        catch Error(string memory reason) {
            hasError = true;
            assertEq(reason, "Invalid sign value");
        }
        assertTrue(hasError, "Expected function to revert");
    }

    function testInvalidInnerArrayLength() public view {
        bool hasError = false;
        try this.externalDecodeCborBigIntToUint256(hex"820189") {}
        catch Error(string memory reason) {
            hasError = true;
            assertEq(reason, "Invalid array length");
        }
        assertTrue(hasError, "Expected function to revert");
    }

    function testEncodeAddressAsArrayWithNulls() public pure {
        assertEq(
            Wrapper.encodeAddressAsArrayWithNulls(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65, 3),
            hex"8456040a15d34aaf54267db7d7c367839aaf71a00a2c6a65f6f6f6"
        );
    }
}
