// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Hoku} from "../src/Hoku.sol";

contract HokuScript is Script {
    Hoku public hoku;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        hoku = new Hoku();

        vm.stopBroadcast();
    }
}
