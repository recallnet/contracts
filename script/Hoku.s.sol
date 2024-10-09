// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Options, Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

import {Hoku} from "../src/Hoku.sol";
import {Environment} from "../src/util/Types.sol";

contract DeployScript is Script {
    string constant PRIVATE_KEY = "PRIVATE_KEY";
    address public proxyAddress;

    function setUp() public {}

    function proxy() public view returns (address) {
        return proxyAddress;
    }

    function run(Environment env) public returns (Hoku) {
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

        proxyAddress = Upgrades.deployUUPSProxy("Hoku.sol", abi.encodeCall(Hoku.initialize, (env)));
        vm.stopBroadcast();

        // Check implementation
        address implAddr = Upgrades.getImplementationAddress(proxyAddress);
        console.log("Implementation address: ", implAddr);

        Hoku hoku = Hoku(proxyAddress);
        return hoku;
    }
}

contract UpgradeProxyScript is Script {
    function setUp() public {}

    function run() public {
        // Get proxy owner account
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Get proxy address
        address proxy = vm.envAddress("PROXY_ADDR");
        console.log("proxy address: ", proxy);

        // Check current implementation
        address implOld = Upgrades.getImplementationAddress(proxy);
        console.log("Implementation address: ", implOld);

        // Upgrade proxy to new implementation
        Options memory opts;
        opts.referenceContract = "Hoku.sol";
        vm.startBroadcast(deployerPrivateKey);
        Upgrades.upgradeProxy(proxy, "Hoku.sol", "", opts);
        vm.stopBroadcast();

        // Check new implementation
        address implNew = Upgrades.getImplementationAddress(proxy);
        console.log("Implementation address: ", implNew);

        require(implOld != implNew, "Implementation address not changed");
    }
}
