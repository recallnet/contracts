// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

import {CreditManager} from "../src/CreditManager.sol";

contract DeployScript is Script {
    function run() public returns (CreditManager) {
        vm.startBroadcast();

        CreditManager credit = new CreditManager();

        vm.stopBroadcast();

        return credit;
    }
}
