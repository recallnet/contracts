// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {BigInt, Credits, GetStatsReturn} from "../src/Credits.sol";

contract FaucetTest is Test {
    Credits credits;

    function setUp() public virtual {
        vm.createSelectFork("http://localhost:8545");
        credits = new Credits();
    }

    function test_ConvertGetStatsReturn() public {
        bytes memory data = hex"8a40820182000182008082008082008082008001000000";
        GetStatsReturn memory stats = credits.decodeStats(data);
        assertEq(BigInt.unwrap(stats.capacityFree), 1);
    }

    function test_ConvertGetAccount() public {
        bytes memory data = hex"";
    }
}
