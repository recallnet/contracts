// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {StdUtils} from "forge-std/StdUtils.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript as BlobDeployer} from "../script/BlobManager.s.sol";

// TODO: add integration tests once it's possible in CI
contract BlobManagerTest is Test {
    address internal blobManager;

    function setUp() public virtual {
        BlobDeployer blobManagerDeployer = new BlobDeployer();
        blobManager = blobManagerDeployer.run();
    }
}
