// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Credits} from "../src/Credits.sol";
import {Environment} from "../src/util/Types.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

contract DeployScript is Script {
    string constant PRIVATE_KEY = "PRIVATE_KEY";

    function setUp() public {}

    function run(Environment env) public returns (Credits) {
        if (vm.envExists(PRIVATE_KEY)) {
            uint256 privateKey = vm.envUint(PRIVATE_KEY);
            if (env == Environment.Local) {
                console.log("Deploying to local network");
            } else if (env == Environment.Testnet) {
                console.log("Deploying to testnet network");
            } else {
                revert("Mainnet is not supported");
            }
            vm.startBroadcast(privateKey);
        } else if (env == Environment.Foundry) {
            console.log("Deploying to foundry");
            vm.startBroadcast();
        } else {
            revert("PRIVATE_KEY not set");
        }

        Credits credits = new Credits();

        vm.stopBroadcast();

        return credits;
    }
}
