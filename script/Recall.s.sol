// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable-next-line one-contract-per-file
pragma solidity ^0.8.26;

import {Recall} from "../src/token/Recall.sol";
import {Options, Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Script, console} from "forge-std/Script.sol";

address constant INTERCHAIN_TOKEN_SERVICE = 0xB5FB4BE02232B1bBA4dC8f81dc24C26980dE9e3C;

contract DeployScript is Script {
    address public proxyAddress;

    function proxy() public view returns (address) {
        return proxyAddress;
    }

    function run() public returns (Recall) {
        vm.startBroadcast();

        bytes32 itsSalt = keccak256("RECALL_SALT");
        proxyAddress = Upgrades.deployUUPSProxy(
            "Recall.sol", abi.encodeCall(Recall.initialize, (INTERCHAIN_TOKEN_SERVICE, itsSalt))
        );

        // Check implementation
        address implAddr = Upgrades.getImplementationAddress(proxyAddress);
        console.log("Implementation address: ", implAddr);

        Recall recall = Recall(proxyAddress);

        console.log("Deployer: ", recall.deployer());

        vm.stopBroadcast();

        return recall;
    }

    function setDefaultRoles(address proxyToken, address admin, address minter, address pauser) public {
        vm.startBroadcast();
        Recall recall = Recall(proxyToken);

        // Only grant new roles if different from current
        // Grant new roles and revoke old ones if different
        if (msg.sender != minter) {
            recall.grantRole(recall.MINTER_ROLE(), minter);
            recall.revokeRole(recall.MINTER_ROLE(), msg.sender);
        }
        if (msg.sender != pauser) {
            recall.grantRole(recall.PAUSER_ROLE(), pauser);
            recall.revokeRole(recall.PAUSER_ROLE(), msg.sender);
        }
        if (msg.sender != admin) {
            recall.grantRole(recall.ADMIN_ROLE(), admin);
            recall.revokeRole(recall.ADMIN_ROLE(), msg.sender);
        }
        vm.stopBroadcast();
    }
}

contract UpgradeProxyScript is Script {
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
        opts.referenceContract = "Recall.sol";
        vm.startBroadcast(deployerPrivateKey);
        Upgrades.upgradeProxy(proxy, "Recall.sol", "", opts);
        vm.stopBroadcast();

        // Check new implementation
        address implNew = Upgrades.getImplementationAddress(proxy);
        console.log("Implementation address: ", implNew);

        // solhint-disable-next-line custom-errors
        require(implOld != implNew, "Implementation address unchanged");
    }
}
