// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {Utilities} from "../src/Utilities.sol";
import {SubnetActorManagerFacetMock} from "../src/staking/SubnetActorManagerFacetMock.sol";

contract StakingDeployScript is Script, Utilities {
    string constant PRIVATE_KEY = "PRIVATE_KEY";

    function setUp() public {}

    function run(Environment env) public returns (SubnetActorManagerFacetMock) {
         if (vm.envExists(PRIVATE_KEY)) {
            uint256 privateKey = vm.envUint(PRIVATE_KEY);
            vm.startBroadcast(privateKey);
        } else if (env == Environment.Local) {
            vm.startBroadcast();
        } else {
            revert("PRIVATE_KEY not set in non-local environment");
        }
        vm.stopBroadcast();

        SubnetActorManagerFacetMock subnet = new SubnetActorManagerFacetMock();
        return subnet;
    }

}