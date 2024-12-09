// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable-next-line one-contract-per-file
pragma solidity ^0.8.26;

import {ValidatorGater} from "../src/token/ValidatorGater.sol";
import {SubnetID} from "../src/types/CommonTypes.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Options, Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Script, console2} from "forge-std/Script.sol";

contract DeployScript is Script {
    address public proxyAddress;

    function proxy() public view returns (address) {
        return proxyAddress;
    }

    function run() public returns (ValidatorGater) {
        vm.startBroadcast();

        proxyAddress = Upgrades.deployUUPSProxy("ValidatorGater.sol", abi.encodeCall(ValidatorGater.initialize, ()));
        vm.stopBroadcast();

        // Check implementation
        address implAddr = Upgrades.getImplementationAddress(proxyAddress);
        console2.log("Implementation address: ", implAddr);

        ValidatorGater gater = ValidatorGater(proxyAddress);
        return gater;
    }
}

contract UpgradeGaterProxyScript is Script {
    function run() public {
        // Get proxy owner account
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Get proxy address
        address proxy = vm.envAddress("PROXY_ADDR");
        console2.log("proxy address: ", proxy);

        // Check current implementation
        address implOld = Upgrades.getImplementationAddress(proxy);
        console2.log("Implementation address: ", implOld);

        // Upgrade proxy to new implementation
        Options memory opts;
        opts.referenceContract = "ValidatorGater.sol";
        vm.startBroadcast(deployerPrivateKey);
        Upgrades.upgradeProxy(proxy, "ValidatorGater.sol", "", opts);
        vm.stopBroadcast();

        // Check new implementation
        address implNew = Upgrades.getImplementationAddress(proxy);
        console2.log("Implementation address: ", implNew);

        // solhint-disable-next-line custom-errors
        require(implOld != implNew, "Implementation address unchanged");
    }
}
