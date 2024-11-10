// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {StdUtils} from "forge-std/StdUtils.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript as CreditDeployer} from "../script/CreditManager.s.sol";
import {CreditManager} from "../src/CreditManager.sol";

// TODO: add integration tests once it's possible in CI
contract CreditTest is Test, CreditManager {
    CreditManager internal credit;

    function setUp() public virtual {
        CreditDeployer creditDeployer = new CreditDeployer();
        credit = creditDeployer.run("local");
    }
}
