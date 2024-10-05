// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Utilities} from "../src/Utilities.sol";
import {SubnetID} from "../src/structs/Subnet.sol";
import {ValidatorGater} from "../src/ValidatorGater.sol";

contract DeployScript is Script, Utilities {
    string constant PRIVATE_KEY = "PRIVATE_KEY";

    function setUp() public {}

    // Deploy contract
    function run(Environment env) public returns (ValidatorGater) {
        if (vm.envExists(PRIVATE_KEY)) {
            uint256 privateKey = vm.envUint(PRIVATE_KEY);
            vm.startBroadcast(privateKey);
        } else if (env == Environment.Local) {
            vm.startBroadcast();
        } else {
            revert("PRIVATE_KEY not set in non-local environment");
        }
        ValidatorGater gater = new ValidatorGater();
        vm.stopBroadcast();
        return gater;
    }

    // Deploy contract and set subnet ID
    function run(Environment env, uint64 root, address[] calldata route) public returns (ValidatorGater) {
        if (vm.envExists(PRIVATE_KEY)) {
            uint256 privateKey = vm.envUint(PRIVATE_KEY);
            vm.startBroadcast(privateKey);
        } else if (env == Environment.Local) {
            vm.startBroadcast();
        } else {
            revert("PRIVATE_KEY not set in non-local environment");
        }
        ValidatorGater gater = new ValidatorGater();
        SubnetID memory id = SubnetID({root: root, route: route});
        gater.setSubnet(id);
        vm.stopBroadcast();
        return gater;
    }
}
