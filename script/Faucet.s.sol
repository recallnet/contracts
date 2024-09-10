// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {Utilities} from "../src/Utilities.sol";
import {Faucet} from "../src/Faucet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployScript is Script, Utilities {
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
        try faucet.fund{value: initialSupply}() {
            console2.log("Faucet funded with: ", initialSupply);
        } catch {
            console2.log("Faucet funding failed, need to fund manually");
        }

        vm.stopBroadcast();

        return faucet;
    }
}
