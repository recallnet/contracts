// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {StdUtils} from "forge-std/StdUtils.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript as BlobDeployer} from "../script/BlobManager.s.sol";
import {BlobManager} from "../src/BlobManager.sol";
import {Environment} from "../src/types/CommonTypes.sol";

// TODO: add integration tests once it's possible in CI
contract BlobManagerTest is Test, BlobManager {
    BlobManager internal blobs;

    function setUp() public virtual {
        BlobDeployer blobsDeployer = new BlobDeployer();
        blobs = blobsDeployer.run(Environment.Foundry);
    }
}
