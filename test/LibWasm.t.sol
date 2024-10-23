// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {Base32} from "../src/util/Base32.sol";
import {KeyValue, LibWasm} from "../src/util/LibWasm.sol";

contract LibWasmTest is Test {
    function testDecodeCborArray() public view {
        bytes[] memory array_null = LibWasm.decodeCborArrayToBytes(hex"f6");
        assertEq(array_null.length, 0);

        bytes[] memory array =
            LibWasm.decodeCborArrayToBytes(hex"85820181068201821a44c08d341a456391828201811936ba1a000af53da0");
        assertEq(array.length, 5);
        assertEq(array[0], hex"82018106");
        assertEq(array[1], hex"8201821a44c08d341a45639182");
        assertEq(array[2], hex"8201811936ba");
        assertEq(array[3], hex"000af53d");
        assertEq(array[4], hex"a0");
    }

    function testDecodeCborBigInt() public pure {
        // Zero, empty array, or null
        require(LibWasm.decodeCborBigIntToUint256(hex"820080") == 0, "it should be zero for empty array");
        require(LibWasm.decodeCborBigIntToUint256(hex"82008100") == 0, "it should be zero for array with zero");
        // Handles the case where WASM returns a null string for a BigInt
        require(
            LibWasm.decodeCborBigIntToUint256(hex"f6") == 0, "it should be zero if bigint serialized as null string"
        );
        // Handles the same case, but after the CBOR `decodeArray` helper converts to 0x00
        require(
            LibWasm.decodeCborBigIntToUint256(hex"00") == 0,
            "it should be zero if bigint serialized as already deserialized null string"
        );
        // 8 bits
        require(LibWasm.decodeCborBigIntToUint256(hex"82018101") == 1, "it should be one");
        require(LibWasm.decodeCborBigIntToUint256(hex"8201811801") == 1, "it should be one");
        require(LibWasm.decodeCborBigIntToUint256(hex"82018118ff") == 255, "it should be 255");
        // 16 bits
        require(LibWasm.decodeCborBigIntToUint256(hex"820181190100") == 256, "it should be 256");
        require(LibWasm.decodeCborBigIntToUint256(hex"820181190750") == 1872, "it should be 1872");
        require(LibWasm.decodeCborBigIntToUint256(hex"820181191290") == 4752, "it should be 4752");
        require(LibWasm.decodeCborBigIntToUint256(hex"820181194530") == 17712, "it should be 17712");
        require(LibWasm.decodeCborBigIntToUint256(hex"82018119ffff") == 65535, "it should be 65535");
        // 32 bits
        require(LibWasm.decodeCborBigIntToUint256(hex"8201811a00010000") == 65536, "it should be 65536");
        require(LibWasm.decodeCborBigIntToUint256(hex"8201811a00ffffff") == 16777215, "it should be 16777215");
        require(LibWasm.decodeCborBigIntToUint256(hex"8201811a01000000") == 16777216, "it should be 16777216");
        // 40 bits
        require(LibWasm.decodeCborBigIntToUint256(hex"8201821a000000001801") == 4294967296, "it should be 4294967296");
        require(
            LibWasm.decodeCborBigIntToUint256(hex"8201821affffffff18ff") == 1099511627775, "it should be 1099511627775"
        );
        // 48 bits
        require(LibWasm.decodeCborBigIntToUint256(hex"8201821a00000000190001") == 4294967296, "it should be 4294967296");
        require(
            LibWasm.decodeCborBigIntToUint256(hex"8201821affffffff19ffff") == 281474976710655,
            "it should be 281474976710655"
        );
        // 64 bits
        require(
            LibWasm.decodeCborBigIntToUint256(hex"8201821a000000001a00000001") == 4294967296, "it should be 4294967296"
        );
        require(
            LibWasm.decodeCborBigIntToUint256(hex"8201821af62c00001a29a2241a") == 3000000000000000000,
            "it should be 3000000000000000000"
        );
        require(
            LibWasm.decodeCborBigIntToUint256(hex"8201821affffffff1affffffff") == 18446744073709551615,
            "it should be 18446744073709551615"
        );
        // 96 bits
        require(
            LibWasm.decodeCborBigIntToUint256(hex"8201831a0064291e0006") == 110680464442263873822,
            "it should be 110680464442263873822"
        );
        require(
            LibWasm.decodeCborBigIntToUint256(hex"820183000001") == 18446744073709551616,
            "it should be 18446744073709551616"
        );
        require(
            LibWasm.decodeCborBigIntToUint256(hex"8201831a000000001a000000001a00000001") == 18446744073709551616,
            "it should be 18446744073709551616"
        );
        require(
            LibWasm.decodeCborBigIntToUint256(hex"8201831affffffff1affffffff1affffffff")
                == 79228162514264337593543950335,
            "it should be 79228162514264337593543950335"
        );
        // 128 bits
        require(
            LibWasm.decodeCborBigIntToUint256(hex"8201841a000000001a000000001a000000001a00000001")
                == 79228162514264337593543950336,
            "it should be 79228162514264337593543950336"
        );
        require(
            LibWasm.decodeCborBigIntToUint256(hex"8201841affffffff1affffffff1affffffff1affffffff")
                == 340282366920938463463374607431768211455,
            "it should be 340282366920938463463374607431768211455"
        );
        // 256 bits
        require(
            LibWasm.decodeCborBigIntToUint256(
                hex"8201881a000000001a000000001a000000001a000000001a000000001a000000001a000000001a00000001"
            ) == 26959946667150639794667015087019630673637144422540572481103610249216,
            "it should be 26959946667150639794667015087019630673637144422540572481103610249216"
        );
        require(
            LibWasm.decodeCborBigIntToUint256(
                hex"8201881affffffff1affffffff1affffffff1affffffff1affffffff1affffffff1affffffff1affffffff"
            ) == type(uint256).max,
            "it should be uint256 max value"
        );
    }

    function externalDecodeCborBigIntToUint256(bytes memory input) external pure returns (uint256) {
        return LibWasm.decodeCborBigIntToUint256(input);
    }

    function testDecodeArray() public view {
        bytes memory input = hex"83f6f6820080";
        bytes[] memory array = LibWasm.decodeCborArrayToBytes(input);
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

    function testEncodeUint256Zero() public pure {
        bytes memory params = LibWasm.encodeCborBigInt(0);
        assertEq(params, hex"820080");

        params = LibWasm.encodeCborBigInt(1);
        assertEq(params, hex"82018101");

        params = LibWasm.encodeCborBigInt(1099511627775);
        assertEq(params, hex"8201821affffffff18ff");

        params = LibWasm.encodeCborBigInt(65536);
        assertEq(params, hex"8201811a00010000");

        params = LibWasm.encodeCborBigInt(110680464442263873822);
        assertEq(params, hex"8201831a0064291e0006");

        params = LibWasm.encodeCborBigInt(18446744073709551616);
        assertEq(params, hex"820183000001");

        params = LibWasm.encodeCborBigInt(type(uint256).max);
        assertEq(params, hex"8201881affffffff1affffffff1affffffff1affffffff1affffffff1affffffff1affffffff1affffffff");
    }

    function testDecodeCborBigUint() public pure {
        require(LibWasm.decodeCborBigUintToUint256(hex"80") == 0, "it should be zero");
        require(LibWasm.decodeCborBigUintToUint256(hex"8101") == 1, "it should be one");
        require(
            LibWasm.decodeCborBigUintToUint256(
                hex"871affffffff1affffffff1affffffff1affffffff1affffffff1affffffff1affffffff"
            ) == 26959946667150639794667015087019630673637144422540572481103610249215,
            "it should handle large values"
        );
    }

    function testEncodeCborBigUint() public pure {
        bytes memory params = LibWasm.encodeCborBigUint(0);
        assertEq(params, hex"80");

        params = LibWasm.encodeCborBigUint(1);
        assertEq(params, hex"8101");

        params = LibWasm.encodeCborBigUint(26959946667150639794667015087019630673637144422540572481103610249215);
        assertEq(params, hex"871affffffff1affffffff1affffffff1affffffff1affffffff1affffffff1affffffff");
    }

    function testDecodeAddress() public pure {
        bytes memory addr = hex"040a15d34aaf54267db7d7c367839aaf71a00a2c6a65";
        address result = LibWasm.decodeCborAddress(addr);
        assertEq(result, 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
    }

    function testEncodeCborActorAddress() public pure {
        string memory addr = "t2o4gsdesxam4qui3pnd4e54ouglffoqwecfnrdzq";
        bytes memory result = LibWasm.encodeCborActorAddress(addr);
        assertEq(result, hex"02770d21925703390a236f68f84ef1d432ca5742c4");
        addr = "t2i4roxxdp6hgryxqbwfee6t7uzrkr6lyz257le7a";
        result = LibWasm.encodeCborActorAddress(addr);
        assertEq(result, hex"024722ebdc6ff1cd1c5e01b1484f4ff4cc551f2f19");
    }

    function testDecodeCborActorAddress() public pure {
        bytes memory addr = hex"02770d21925703390a236f68f84ef1d432ca5742c4";
        string memory result = LibWasm.decodeCborActorAddress(addr);
        assertEq(result, "t2o4gsdesxam4qui3pnd4e54ouglffoqwecfnrdzq");
    }

    function testDecodeCborString() public view {
        bytes memory data = hex"6b4f626a65637453746f726555";
        bytes memory result = LibWasm.decodeStringToBytes(data);
        assertEq(string(result), "ObjectStore");
    }

    function testDecodeCborBytesToString() public pure {
        bytes memory data = hex"8618681865186c186c186f182f";
        bytes memory result = LibWasm.decodeCborBytesArrayToBytes(data);
        assertEq(string(result), "hello/");
    }

    function testDecodeBase32() public pure {
        string memory data = "o4gsdesxam4qui3pnd4e54ouglffoqwecfnrdzq";
        bytes memory result = Base32.decode(bytes(data));
        assertEq(result, hex"770d21925703390a236f68f84ef1d432ca5742c4115b11e6");
    }

    function testEncodeBase32() public pure {
        bytes memory data = hex"770d21925703390a236f68f84ef1d432ca5742c4115b11e6";
        bytes memory result = Base32.encode(data);
        assertEq(string(result), "o4gsdesxam4qui3pnd4e54ouglffoqwecfnrdzq");
    }

    function testEncodeCborKeyValueMap() public pure {
        KeyValue[] memory params = new KeyValue[](1);
        params[0] = KeyValue("alias", "foo");
        bytes memory result = LibWasm.encodeCborKeyValueMap(params);
        assertEq(result, hex"a165616c69617363666f6f");
    }
}
