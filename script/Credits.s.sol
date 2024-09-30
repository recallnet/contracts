// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {Utilities} from "../src/util/Utilities.sol";
import {Credits} from "../src/Credits.sol";

contract DeployScript is Script {
    string constant PRIVATE_KEY = "PRIVATE_KEY";
    address public proxyAddress;

    function setUp() public {}

    function run(Utilities.Environment env) public returns (Credits) {
        if (vm.envExists(PRIVATE_KEY)) {
            uint256 privateKey = vm.envUint(PRIVATE_KEY);
            vm.startBroadcast(privateKey);
        } else if (env == Utilities.Environment.Local) {
            vm.startBroadcast();
        } else {
            revert("PRIVATE_KEY not set in non-local environment");
        }

        Credits credits = new Credits();

        vm.stopBroadcast();

        return credits;
    }
}
