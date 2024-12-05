// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable-next-line one-contract-per-file
pragma solidity ^0.8.26;

import {Hoku} from "../src/Hoku.sol";
import {IInterchainTokenService} from
    "@axelar-network/interchain-token-service/contracts/interfaces/IInterchainTokenService.sol";
import {ITokenManagerType} from "@axelar-network/interchain-token-service/contracts/interfaces/ITokenManagerType.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Options, Upgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Script, console} from "forge-std/Script.sol";

address constant INTERCHAIN_TOKEN_SERVICE = 0xB5FB4BE02232B1bBA4dC8f81dc24C26980dE9e3C;

contract DeployScript is Script {
    address public proxyAddress;

    function proxy() public view returns (address) {
        return proxyAddress;
    }

    function run(string memory network) public returns (Hoku) {
        vm.startBroadcast();

        string memory prefix = "";
        if (Strings.equal(network, "local")) {
            prefix = "l";
        } else if (Strings.equal(network, "testnet")) {
            prefix = "t";
        } else if (!Strings.equal(network, "ethereum") && !Strings.equal(network, "filecoin")) {
            // solhint-disable-next-line custom-errors
            revert("Unsupported network.");
        }

        bytes32 itsSalt = keccak256("HOKU_SALT");
        proxyAddress = Upgrades.deployUUPSProxy(
            "Hoku.sol", abi.encodeCall(Hoku.initialize, (prefix, INTERCHAIN_TOKEN_SERVICE, itsSalt))
        );

        // Check implementation
        address implAddr = Upgrades.getImplementationAddress(proxyAddress);
        console.log("Implementation address: ", implAddr);

        Hoku hoku = Hoku(proxyAddress);

        console.log("Deployer: ", hoku.deployer());

        if (Strings.equal(network, "filecoin") || Strings.equal(network, "ethereum")) {
            console.log("Deploying token manager");
            IInterchainTokenService itsContract = IInterchainTokenService(INTERCHAIN_TOKEN_SERVICE);
            bytes memory params = abi.encode(abi.encodePacked(hoku.deployer()), address(hoku));
            itsContract.deployTokenManager(itsSalt, "", ITokenManagerType.TokenManagerType.MINT_BURN_FROM, params, 0);
            bytes32 itsTokenId = hoku.interchainTokenId();

            console.log("Hoku Interchain Token ID: ", Strings.toHexString(uint256(itsTokenId), 32));
            address tokenManager = itsContract.tokenManagerAddress(itsTokenId);
            console.log("Token manager: ", tokenManager);

            // Grant minter role to token manager
            hoku.grantRole(hoku.MINTER_ROLE(), tokenManager);
        }
        vm.stopBroadcast();

        return hoku;
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
        opts.referenceContract = "Hoku.sol";
        vm.startBroadcast(deployerPrivateKey);
        Upgrades.upgradeProxy(proxy, "Hoku.sol", "", opts);
        vm.stopBroadcast();

        // Check new implementation
        address implNew = Upgrades.getImplementationAddress(proxy);
        console.log("Implementation address: ", implNew);

        // solhint-disable-next-line custom-errors
        require(implOld != implNew, "Implementation address unchanged");
    }
}
