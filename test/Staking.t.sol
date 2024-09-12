// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Utilities} from "../src/Utilities.sol";
import {StakingDeployScript} from "../script/Staking.s.sol";
import {SubnetActorManagerFacet} from "../src/staking/SubnetActorManagerFacet.sol";

contract StakingTest is Test, Utilities {
    SubnetActorManagerFacet internal subnetActorManagerFacet;
    address[3] internal validators;
    uint256 constant initialSupply = 1000;

    function setUp() public {
        StakingDeployScript deployer = new StakingDeployScript();
        subnetActorManagerFacet = deployer.run(Environment.Local, initialSupply);

        validators[0] = address(0x1);
        validators[1] = address(0x2);
        validators[2] = address(0x3);
    }
}