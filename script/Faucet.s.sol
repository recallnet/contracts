// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Environment} from "../src/util/Types.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

import {Faucet} from "../src/Faucet.sol";

contract DeployScript is Script {
    string constant PRIVATE_KEY = "PRIVATE_KEY";
    address public proxyAddress;

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
