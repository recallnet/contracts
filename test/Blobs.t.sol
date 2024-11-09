// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {StdUtils} from "forge-std/StdUtils.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript as BlobsDeployer} from "../script/Blobs.s.sol";
import {Blobs} from "../src/Blobs.sol";
import {Environment} from "../src/types/CommonTypes.sol";

// TODO: add integration tests once it's possible in CI
contract BlobsTest is Test, Blobs {
    Blobs internal blobs;

    function setUp() public virtual {
        BlobsDeployer blobsDeployer = new BlobsDeployer();
        blobs = blobsDeployer.run(Environment.Foundry);
    }
}
