// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {Upgrades, Options} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Hoku} from "../src/Hoku.sol";

contract DeployScript is Script {
    address public proxyAddress;

    function setUp() public {}

    function proxy() public view returns (address) {
        return proxyAddress;
    }

    function run(string memory prefix, address its) public returns (Hoku) {
        vm.startBroadcast();

        bytes32 itsSalt = keccak256("HOKU_SALT");
        proxyAddress = Upgrades.deployUUPSProxy("Hoku.sol", abi.encodeCall(Hoku.initialize, (prefix, its, itsSalt)));
        vm.stopBroadcast();

        // Check implementation
        address implAddr = Upgrades.getImplementationAddress(proxyAddress);
        console2.log("Implementation address: ", implAddr);

        // Verify the implementation has code
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(implAddr)
        }
        console2.log("Implementation code size:", codeSize);

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
        console2.log("proxy address: ", proxy);

        // Check current implementation
        address implOld = Upgrades.getImplementationAddress(proxy);
        console2.log("Implementation address: ", implOld);

        // Upgrade proxy to new implementation
        Options memory opts;
        opts.referenceContract = "Hoku.sol";
        vm.startBroadcast(deployerPrivateKey);
        Upgrades.upgradeProxy(proxy, "Hoku.sol", "", opts);
        vm.stopBroadcast();

        // Check new implementation
        address implNew = Upgrades.getImplementationAddress(proxy);
        console2.log("Implementation address: ", implNew);

        require(implOld != implNew, "Implementation address not changed");
    }
}
