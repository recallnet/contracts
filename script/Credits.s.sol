// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Credits} from "../src/Credits.sol";
import {Environment} from "../src/util/Types.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

contract DeployScript is Script {
    string constant PRIVATE_KEY = "PRIVATE_KEY";
    address public proxyAddress;

    function setUp() public {}

    function run(Environment env) public returns (Credits) {
        if (vm.envExists(PRIVATE_KEY)) {
            uint256 privateKey = vm.envUint(PRIVATE_KEY);
            vm.startBroadcast(privateKey);
        } else if (env == Environment.Local) {
            vm.startBroadcast();
        } else {
            revert("PRIVATE_KEY not set in non-local environment");
        }

        Credits credits = new Credits();

        vm.stopBroadcast();

        return credits;
    }
}
