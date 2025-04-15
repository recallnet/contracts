// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {ValidatorRewarder} from "../src/token/ValidatorRewarder.sol";

import {SubnetID} from "../src/types/CommonTypes.sol";
import {SubnetIDHelper} from "../src/util/SubnetIDHelper.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Options, Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Script, console2} from "forge-std/Script.sol";

contract DeployScript is Script {
    string constant PRIVATE_KEY = "PRIVATE_KEY";
    address public proxyAddress;

    function setUp() public {}

    function proxy() public view returns (address) {
        return proxyAddress;
    }

    function run(address recallToken) public returns (ValidatorRewarder) {
        vm.startBroadcast();
        proxyAddress = Upgrades.deployUUPSProxy(
            "ValidatorRewarder.sol:ValidatorRewarder", abi.encodeCall(ValidatorRewarder.initialize, (recallToken))
        );
        vm.stopBroadcast();

        // Check implementation
        address implAddr = Upgrades.getImplementationAddress(proxyAddress);
        console2.log("Implementation address: ", implAddr);

        ValidatorRewarder rewarder = ValidatorRewarder(proxyAddress);
        return rewarder;
    }
}

contract UpgradeRewarderProxyScript is Script {
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
        opts.referenceContract = "ValidatorRewarder.sol:ValidatorRewarder";
        vm.startBroadcast(deployerPrivateKey);
        Upgrades.upgradeProxy(proxy, "ValidatorRewarder.sol:ValidatorRewarder", "", opts);
        vm.stopBroadcast();

        // Check new implementation
        address implNew = Upgrades.getImplementationAddress(proxy);
        console2.log("Implementation address: ", implNew);

        require(implOld != implNew, "Implementation address not changed");
    }
}
