// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

import {CreditManager} from "../src/CreditManager.sol";

contract DeployScript is Script {
    string constant PRIVATE_KEY = "PRIVATE_KEY";

    function setUp() public {}

    function run(string memory network) public returns (CreditManager) {
        if (vm.envExists(PRIVATE_KEY)) {
            uint256 privateKey = vm.envUint(PRIVATE_KEY);
            vm.startBroadcast(privateKey);
        } else if (Strings.equal(network, "local")) {
            vm.startBroadcast();
        } else {
            revert("PRIVATE_KEY not set in non-local environment");
        }

        CreditManager credit = new CreditManager();

        vm.stopBroadcast();

        return credit;
    }
}
