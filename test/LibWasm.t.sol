// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {Base32} from "../src/util/Base32.sol";
import {InvalidValue, KeyValue, LibWasm} from "../src/util/LibWasm.sol";

contract LibWasmTest is Test {
    function testDecodeCborArray() public view {
        bytes[] memory arrayNull = LibWasm.decodeCborArrayToBytes(hex"f6");
        assertEq(arrayNull.length, 0);

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
        require(LibWasm.decodeCborBigIntToUint256(hex"820080") == 0, "it should be zero for empty");
        require(LibWasm.decodeCborBigIntToUint256(hex"82008100") == 0, "it should be zero for zero array");
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

    function testInvalidArrayLengthOrSign() public {
        // Invalid bigint value (zero value will be 0x820080, so 0x810080 is invalid)
        bytes memory expectedError = abi.encodeWithSelector(InvalidValue.selector, "Invalid array length or sign value");
        vm.expectRevert(expectedError);
        this.externalDecodeCborBigIntToUint256(hex"810080");

        // Invalid sign
        vm.expectRevert(expectedError);
        this.externalDecodeCborBigIntToUint256(hex"820280");

        // Invalid bigint value (array length of 9 exceeds max of 8)
        expectedError = abi.encodeWithSelector(InvalidValue.selector, "Invalid bigint value");
        vm.expectRevert(expectedError);
        this.externalDecodeCborBigIntToUint256(hex"820189");
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

    function testDecodeAddress() public view {
        bytes memory addr = hex"040a15d34aaf54267db7d7c367839aaf71a00a2c6a65";
        address result = LibWasm.decodeCborAddress(addr);
        assertEq(result, 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);

        addr = hex"00ED01";
        result = LibWasm.decodeCborAddress(addr);
        assertEq(result, 0xFf000000000000000000000000000000000000ed);
    }

    function testEncodeCborActorAddress() public pure {
        string memory addr = "t2o4gsdesxam4qui3pnd4e54ouglffoqwecfnrdzq";
        bytes memory result = LibWasm.encodeCborActorAddress(addr);
        assertEq(result, hex"02770d21925703390a236f68f84ef1d432ca5742c4");
        addr = "t2i4roxxdp6hgryxqbwfee6t7uzrkr6lyz257le7a";
        result = LibWasm.encodeCborActorAddress(addr);
        assertEq(result, hex"024722ebdc6ff1cd1c5e01b1484f4ff4cc551f2f19");
    }

    function testDecodeCborDelegatedAddressStringToAddress() public pure {
        bytes memory data = bytes("f410fsd3zx5xlfrhyoa3f46czqlq7capjhoighmzagaq");
        address result = LibWasm.decodeCborDelegatedAddressStringToAddress(data);
        assertEq(result, 0x90F79bf6EB2c4f870365E785982E1f101E93b906);
    }

    function testDecodeCborActorAddress() public pure {
        bytes memory addr = hex"02770d21925703390a236f68f84ef1d432ca5742c4";
        string memory result = LibWasm.decodeCborActorAddress(addr);
        assertEq(result, "t2o4gsdesxam4qui3pnd4e54ouglffoqwecfnrdzq");
    }

    function testDecodeCborActorIdStringToAddress() public view {
        bytes memory data = bytes("f0152");
        address result = LibWasm.decodeCborActorIdStringToAddress(data);
        assertEq(result, 0xff00000000000000000000000000000000000098);
    }

    function testDecodeCborString() public view {
        bytes memory data = hex"65696e6e6572";
        bytes memory result = LibWasm.decodeCborStringToBytes(data);
        assertEq(string(result), "inner");

        data = hex"782c66343130667364337A7835786C667268796F6133663436637A716C71376361706A686F6967686D7A61676171";
        result = LibWasm.decodeCborStringToBytes(data);
        assertEq(string(result), "f410fsd3zx5xlfrhyoa3f46czqlq7capjhoighmzagaq");
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

    function testEncodeCborFixedArray() public pure {
        bytes memory data = hex"bea674beb6e45bcc488e2fde0f7981b5460355eeec55091927868185325599ef";
        bytes memory result = LibWasm.encodeCborFixedArray(data);
        assertEq(
            result,
            hex"982018be18a6187418be18b618e4185b18cc1848188e182f18de0f1879188118b5184603185518ee18ec1855091819182718861881188518321855189918ef"
        );

        data = hex"0000000000000000000000000000000000000000000000000000000000000000";
        result = LibWasm.encodeCborFixedArray(data);
        assertEq(result, hex"98200000000000000000000000000000000000000000000000000000000000000000");
    }

    function testEncodeCborBytesArray() public {
        bytes memory data = bytes("foo");
        bytes memory result = LibWasm.encodeCborBytesArray(data);
        assertEq(result, hex"831866186f186f");

        // Max 255 length
        data = bytes(
            "foofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoo"
        );
        result = LibWasm.encodeCborBytesArray(data);
        assertEq(
            result,
            hex"98ff1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f1866186f186f"
        );

        // Exceeds max length of 255 (string is 256 length)
        data = bytes(
            "foofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofoofooo"
        );
        bytes memory expectedError = abi.encodeWithSelector(InvalidValue.selector, "Length exceeds max size of 255");
        vm.expectRevert(expectedError);
        this.externalEncodeCborBytesArray(data); // Call through external function
    }

    function externalEncodeCborBytesArray(bytes memory data) external pure returns (bytes memory) {
        return LibWasm.encodeCborBytesArray(data);
    }

    function testEncodeCborIrohNodeId() public pure {
        string memory nodeId = "4wx2ocgzy2p42egwp5cwiyjhwzz6wt4elwwrrgoujx7ady5oxm7a";
        bytes memory result = LibWasm.encodeCborBlobHashOrNodeId(nodeId);
        assertEq(
            result,
            hex"982018e518af18a70818d918c6189f18cd1018d6187f184518641861182718b6187318eb184f1884185d18ad1818189918d4184d18fe0118e318ae18bb183e"
        );
    }

    function testEncodeCborBlobHash() public pure {
        string memory blobHash = "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq";
        bytes memory result = LibWasm.encodeCborBlobHashOrNodeId(blobHash);
        assertEq(
            result,
            hex"9820188e184c187c181b189918db18fd185018e718a91851188518fe18ad185e18e11844188f18a90418a218fd18d7187818ea18f518f218db18fd1862189a1899"
        );
    }

    function testEncodeStringToBytes() public pure {
        string memory str = "hello/world";
        bytes memory result = LibWasm.encodeCborBytes(str);
        assertEq(result, hex"4b68656c6c6f2f776f726c64");
    }

    function testEncodeCborString() public pure {
        string memory str = "inner";
        bytes memory result = LibWasm.encodeCborString(str);
        assertEq(result, hex"65696E6E6572");

        str = "";
        result = LibWasm.encodeCborString(str);
        assertEq(result, hex"60");

        str = "foo";
        result = LibWasm.encodeCborString(str);
        assertEq(result, hex"63666F6F");
    }

    function testEncodeCborUint256AsBytes() public {
        uint256 value = 12345; // A credit limit of 12345 (adds padding)
        bytes memory result = LibWasm.encodeCborUint256AsBytes(value, true);
        assertEq(result, hex"4B00029D394A5D6305440000");

        value = 987654321; // A gas fee limit of 987654321 (no padding)
        result = LibWasm.encodeCborUint256AsBytes(value, false);
        assertEq(result, hex"45003ADE68B1");

        value = 10000000000000000000000000;
        result = LibWasm.encodeCborUint256AsBytes(value, true);
        assertEq(result, hex"530072CB5BD86321E38CB6CE6682E80000000000");

        value = 1000000000000000000000000000000000000;
        result = LibWasm.encodeCborUint256AsBytes(value, true);
        assertEq(result, hex"5818000A70C3C40A64E6C51999090B65F67D9240000000000000");

        value = 1000000000000000000000000000000000000000000000000000000000000000000000000;
        result = LibWasm.encodeCborUint256AsBytes(value, false);
        assertEq(result, hex"581f0090E40FBEEA1D3A4ABC8955E946FE31CDCF66F634E1000000000000000000");

        // Causes an overflow
        bytes memory expectedError = abi.encodeWithSelector(InvalidValue.selector, "value * 1e18 overflows uint256");
        vm.expectRevert(expectedError);
        value = 1000000000000000000000000000000000000000000000000000000000000000000000000;
        this.externalEncodeCborUint256AsBytes(value, true);
    }

    function externalEncodeCborUint256AsBytes(uint256 value, bool padding) external pure returns (bytes memory) {
        return LibWasm.encodeCborUint256AsBytes(value, padding);
    }

    function testDecodeCborByteStringToUint64() public pure {
        bytes memory data = hex"1a00015180";
        uint64 result = LibWasm.decodeCborByteStringToUint64(data);
        assertEq(result, 86400);
    }

    function testDecodeCborBlobHashOrNodeId() public pure {
        bytes memory data =
            hex"9820185818300918d918fc011819188d18b0150818dc186b18c918e618f10a185c18ef189118a3185d1864186d187318a518b718a8181918cd18b0184d";
        string memory result = string(LibWasm.decodeCborBlobHashOrNodeId(data));
        assertEq(result, "layatwp4aemy3mavbdogxspg6effz34runowi3ltuw32qgonwbgq");
    }
}
