// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {StdUtils} from "forge-std/StdUtils.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript as BucketManagerDeployer} from "../script/BucketManager.s.sol";
import {BucketManager} from "../src/BucketManager.sol";
import {Environment} from "../src/types/CommonTypes.sol";

// TODO: add integration tests once it's possible in CI
contract BucketManagerTest is Test, BucketManager {
    BucketManager internal bucketManager;

    function setUp() public virtual {
        BucketManagerDeployer bucketManagerDeployer = new BucketManagerDeployer();
        bucketManager = bucketManagerDeployer.run(Environment.Foundry);
    }
}
