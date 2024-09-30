// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {CommonTypes} from "../lib/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import {BytesCBOR} from "../lib/filecoin-solidity/contracts/v0.8/cbor/BytesCBOR.sol";
import {FilecoinCBOR} from "../lib/filecoin-solidity/contracts/v0.8/cbor/FilecoinCBOR.sol";
import {CBORDecoder} from "../lib/filecoin-solidity/contracts/v0.8/utils/CborDecode.sol";
import {BigInts} from "../lib/filecoin-solidity/contracts/v0.8/utils/BigInts.sol";
import {Credits, SubnetStats} from "../src/Credits.sol";
import {CBORDecoding} from "../src/util/solidity-cbor/CBORDecoding.sol";
import {ByteParser} from "../src/util/solidity-cbor/ByteParser.sol";
import {console2} from "forge-std/console2.sol";
import {Credits} from "../src/Credits.sol";

contract CreditsTest is Test, Credits {
    using BytesCBOR for bytes;
    using CBORDecoder for bytes;
    using BigInts for CommonTypes.BigInt;
    Credits credits;

    function setUp() public virtual {
        vm.createSelectFork("http://localhost:8545");
        credits = new Credits();
    }
    // 85820181068201831ab33939da1ab8bbcad019021d8201811a6b49d2001a00010769a0
    // "credit_free": "9992999999998199937498"
    // "credit_committed": "1800000000",
    // "last_debit_epoch": 67433
}
