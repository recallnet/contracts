// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.23;

import {LibSubnetActorStorage, SubnetActorStorage} from "./LibSubnetActorStorage.sol";
import {SubnetActorManagerFacet} from "./SubnetActorManagerFacet.sol";
import "forge-std/console.sol";

contract SubnetActorManagerFacetMock is SubnetActorManagerFacet {

    function setActiveLimit(uint16 limit) external {
        SubnetActorStorage storage s = LibSubnetActorStorage.appStorage();
        s.validatorSet.activeLimit = limit;
    }

}
