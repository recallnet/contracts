// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Utilities} from "../src/Utilities.sol";
import {Faucet} from "../src/Faucet.sol";

contract DeployScript is Script, Utilities {
    string constant PRIVATE_KEY = "PRIVATE_KEY";

    function setUp() public {}

    function run(Environment env, uint256 initialSupply) public returns (Faucet) {
        if (vm.envExists(PRIVATE_KEY)) {
            uint256 privateKey = vm.envUint(PRIVATE_KEY);
            vm.startBroadcast(privateKey);
        } else if (env == Environment.Local) {
            vm.startBroadcast();
        } else {
            revert("PRIVATE_KEY not set in non-local environment");
        }

        Faucet faucet = new Faucet();
        faucet.fund{value: initialSupply}();

        vm.stopBroadcast();

        return faucet;
    }
}
