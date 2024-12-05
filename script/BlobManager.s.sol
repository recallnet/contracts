// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

import {BlobManager} from "../src/BlobManager.sol";

contract DeployScript is Script {
    function run() public returns (BlobManager) {
        vm.startBroadcast();

        BlobManager blobs = new BlobManager();

        vm.stopBroadcast();

        return blobs;
    }
}
