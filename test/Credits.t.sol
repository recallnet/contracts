// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {StdUtils} from "forge-std/StdUtils.sol";
import {Test, Vm} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {DeployScript as CreditsDeployer} from "../script/Credits.s.sol";
import {Account as CreditAccount, Credits} from "../src/Credits.sol";
import {Approvals, Balance, Environment} from "../src/util/Types.sol";

contract CreditsTest is Test, Credits {
    Credits internal credits;

    function setUp() public virtual {
        CreditsDeployer creditsDeployer = new CreditsDeployer();
        credits = creditsDeployer.run(Environment.Foundry);
    }

    function testDecodeAccount() public view {
        bytes memory data = hex"85820181068201831ab33939da1ab8bbcad019021d8201811a6b49d2001a00010769a0";
        CreditAccount memory account = decodeAccount(data);
        assertEq(account.creditFree, 9992999999998199937498);
        assertEq(account.creditCommitted, 1800000000);
        assertEq(account.lastDebitEpoch, 67433);
    }

    function testDecodeApprovals() public view {
        bytes memory data =
            hex"a156040a15d34aaf54267db7d7c367839aaf71a00a2c6a65a156040a23618e81e3f5cdf7f54c3d65f7fbc0abf5b21e8f83f6f6820080";
        Approvals[] memory approvals = decodeApprovals(data);
        assertEq(approvals[0].receiver, 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
        assertEq(approvals[0].approval[0].requiredCaller, 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
        assertEq(approvals[0].approval[0].approval.limit, 0);
        assertEq(approvals[0].approval[0].approval.expiry, 0);
        assertEq(approvals[0].approval[0].approval.committed, 0);

        data =
            hex"a156040a15d34aaf54267db7d7c367839aaf71a00a2c6a65a256040a23618e81e3f5cdf7f54c3d65f7fbc0abf5b21e8f83f6f682008056040a9965507d1a55bcc2695c58ba16fb37d819b0a4dc83f619edf7820080";
        approvals = decodeApprovals(data);
        assertEq(approvals[0].receiver, 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
        assertEq(approvals[0].approval[0].requiredCaller, 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
        assertEq(approvals[0].approval[0].approval.limit, 0);
        assertEq(approvals[0].approval[0].approval.expiry, 0);
        assertEq(approvals[0].approval[0].approval.committed, 0);
        assertEq(approvals[0].approval[1].requiredCaller, 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
        assertEq(approvals[0].approval[1].approval.limit, 0);
        assertEq(approvals[0].approval[1].approval.expiry, 60919);
        assertEq(approvals[0].approval[1].approval.committed, 0);
    }
}
