// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {console2} from "forge-std/console2.sol";
import {Credits, Account as CreditAccount} from "../src/Credits.sol";

contract CreditsTest is Test, Credits {
    Credits credits;

    function setUp() public virtual {
        vm.createSelectFork("http://localhost:8545");
        credits = new Credits();
    }

    function testDecodeAccount() public view {
        bytes
            memory data = hex"85820181068201831ab33939da1ab8bbcad019021d8201811a6b49d2001a00010769a0";
        CreditAccount memory account = decodeAccount(data);
        assertEq(account.creditFree, 9992999999998199937498);
        assertEq(account.creditCommitted, 1800000000);
        assertEq(account.lastDebitEpoch, 67433);
    }
}
