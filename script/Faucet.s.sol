// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

import {Faucet} from "../src/token/Faucet.sol";

contract DeployScript is Script {
    function run(uint256 initialSupply) public returns (Faucet) {
        vm.startBroadcast();

        Faucet faucet = new Faucet();
        faucet.fund{value: initialSupply}();

        vm.stopBroadcast();

        return faucet;
    }
}
