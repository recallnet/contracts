// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {Hoku} from "../src/Hoku.sol";

contract HokuScript is Script {
    Hoku public hoku;

    function setUp() public {}

    function run() public {
        // Get proxy owner account
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        hoku = new Hoku("Hoku", "tHOKU");
        vm.stopBroadcast();
    }
}
