// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Credits, GetStatsReturn} from "../src/Credits.sol";

contract FaucetTest is Test {
    Credits credits;

    function setUp() public virtual {
        vm.createSelectFork("http://localhost:8545");
        credits = new Credits();
    }

    function test_ConvertGetStatsReturn() public {
        bytes memory data = hex"8a4200011b00000001000000000063307831633078306330783001010000";
        GetStatsReturn memory stats = credits.decodeStats(data);
        assertEq(stats.creditCommitted, uint256(1));
    }

    function test_ConvertGetAccount() public {
        bytes memory data = hex"";
    }
}
