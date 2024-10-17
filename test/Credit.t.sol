// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {StdUtils} from "forge-std/StdUtils.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript as CreditDeployer} from "../script/Credit.s.sol";
import {Credit} from "../src/Credit.sol";
import {Environment} from "../src/types/CommonTypes.sol";
import {Account as CreditAccount, Approvals, Balance} from "../src/types/CreditTypes.sol";

contract CreditTest is Test, Credit {
    Credit internal credit;

    function setUp() public virtual {
        CreditDeployer creditDeployer = new CreditDeployer();
        credit = creditDeployer.run(Environment.Foundry);
    }

    // TODO: add integration tests once it's possible in CI
}
