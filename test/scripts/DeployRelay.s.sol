// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {Relay} from '../../src/token/Relay.sol';
import {SubnetID} from '../../src/types/CommonTypes.sol';
import {MockAxelarGateway, MockToken, MockGateway} from '../Relay.t.sol';

contract DeployRelay is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock contracts
        MockAxelarGateway axelarGateway = new MockAxelarGateway();
        MockGateway gateway = new MockGateway();
        MockToken token = new MockToken();

        // Deploy Relay
        Relay relay = new Relay(
            address(gateway),
            address(axelarGateway)
        );

        // Setup subnet
        SubnetID memory subnet = SubnetID({
            root: 1,
            route: new address[](0)
        });

        // Configure Relay
        relay.setToken(address(token));
        relay.setSubnet(subnet);

        // Mint test tokens
        token.mint(address(axelarGateway), 1000000 ether);

        console.log('Axelar Gateway deployed at:', address(axelarGateway));
        console.log('Gateway deployed at:', address(gateway));
        console.log('Token deployed at:', address(token));
        console.log('Relay deployed at:', address(relay));

        vm.stopBroadcast();
    }
} 