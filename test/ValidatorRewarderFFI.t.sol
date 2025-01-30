// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {ValidatorRewarderTestBase} from "./ValidatorRewarder.t.sol";
import {console2} from "forge-std/console2.sol";

// FFI reward calculation tests
contract ValidatorRewarderFFITest is ValidatorRewarderTestBase {
    string constant PYTHON_SCRIPT = "test/scripts/calculate_rewards.py";

    function setUp() public override {
        super.setUp();
        makeScriptExecutable(PYTHON_SCRIPT);
    }

    function testRewardCalculationWithFFI() public {
        uint256 blocks = 52560 * 5; // 5 years
        uint256 checkpointPeriod = 600;
        uint256 numCheckpoints = blocks / checkpointPeriod;

        address[] memory claimants = new address[](3);
        claimants[0] = address(0x111);
        claimants[1] = address(0x222);
        claimants[2] = address(0x333);

        uint256[] memory blocksCommitted = new uint256[](3);
        blocksCommitted[0] = 100;
        blocksCommitted[1] = 200;
        blocksCommitted[2] = 300;

        // Calculate expected total increase for all blocks at once
        uint256 initialSupply = token.totalSupply();
        uint256[] memory totalParams = new uint256[](3);
        totalParams[0] = initialSupply;
        totalParams[1] = blocks;
        totalParams[2] = 0; // Not needed for total supply calculation

        string memory totalJsonStr = runPythonScript(PYTHON_SCRIPT, totalParams);
        uint256 expectedTotalIncrease = vm.parseJsonUint(totalJsonStr, ".supply_delta");

        console2.log("Expected total increase for all blocks:", expectedTotalIncrease);

        // Process claims checkpoint by checkpoint
        for (uint256 i = 0; i < numCheckpoints; i++) {
            uint64 currentCheckpoint = uint64((i + 1) * 600);
            uint256 supplyBeforeClaims = token.totalSupply();

            // Calculate expected rewards for total supply delta
            uint256[] memory params = new uint256[](3);
            params[0] = supplyBeforeClaims;
            params[1] = 600; // checkpoint period
            params[2] = 0; // blocks committed

            string memory jsonStr = runPythonScript(PYTHON_SCRIPT, params);

            for (uint256 j = 0; j < claimants.length; j++) {
                // Calculate expected validator share
                params[2] = blocksCommitted[j];
                jsonStr = runPythonScript(PYTHON_SCRIPT, params);
                uint256 expectedValidatorShare = vm.parseJsonUint(jsonStr, ".validator_share");
                uint256 expectedRewarderShare = vm.parseJsonUint(jsonStr, ".rewarder_share");

                // Store balances before claim
                uint256 balanceBefore = token.balanceOf(claimants[j]);
                uint256 currentRewarderBalance = token.balanceOf(address(rewarder));

                // Submit claim
                vm.prank(SUBNET_ROUTE);
                rewarder.notifyValidClaim(
                    createSubnet(), currentCheckpoint, createValidatorData(claimants[j], blocksCommitted[j])
                );

                // Verify validator rewards
                assertApproxEqAbs(
                    token.balanceOf(claimants[j]) - balanceBefore,
                    expectedValidatorShare,
                    1000,
                    string.concat("Validator reward mismatch at checkpoint ", vm.toString(currentCheckpoint))
                );

                // Verify rewarder balance
                if (j == 0) {
                    // After first claim, rewarder should have supply delta minus first claimant's share
                    assertApproxEqAbs(
                        token.balanceOf(address(rewarder)),
                        expectedRewarderShare,
                        1000,
                        string.concat(
                            "Rewarder balance mismatch on first claim at checkpoint ", vm.toString(currentCheckpoint)
                        )
                    );
                    currentRewarderBalance = token.balanceOf(address(rewarder));
                } else {
                    // Subsequent claims should decrease rewarder balance by current's validator share
                    assertApproxEqAbs(
                        currentRewarderBalance - token.balanceOf(address(rewarder)),
                        expectedValidatorShare,
                        1000,
                        string.concat(
                            "Rewarder balance mismatch on subsequent claim at checkpoint ",
                            vm.toString(currentCheckpoint)
                        )
                    );
                }
            }

            // Verify checkpoint is set correctly
            assertEq(
                rewarder.latestClaimedCheckpoint(),
                currentCheckpoint,
                string.concat("Checkpoint not set correctly at checkpoint ", vm.toString(currentCheckpoint))
            );
        }

        // After all checkpoints are processed, verify total increase matches
        uint256 actualTotalIncrease = token.totalSupply() - initialSupply;
        // due to rounding in each checkpoint, accumulated error over 5 years is 45,773,118
        // i.e. we print 0.000_000_000_045_679_254 RECALL more than expected!
        assertApproxEqAbs(
            actualTotalIncrease,
            expectedTotalIncrease,
            45679254,
            "Total increase after all checkpoints should match single calculation"
        );

        console2.log("Actual total increase after all checkpoints:", actualTotalIncrease);
    }

    // Helper functions moved from the original test
    function makeScriptExecutable(string memory scriptPath) internal {
        string[] memory makeExecutable = new string[](3);
        makeExecutable[0] = "chmod";
        makeExecutable[1] = "+x";
        makeExecutable[2] = scriptPath;
        vm.ffi(makeExecutable);
    }

    function runPythonScript(string memory scriptPath, uint256[] memory params) internal returns (string memory) {
        string[] memory inputs = new string[](params.length + 1);
        inputs[0] = scriptPath;

        for (uint256 i = 0; i < params.length; i++) {
            inputs[i + 1] = vm.toString(params[i]);
        }

        bytes memory result = vm.ffi(inputs);
        return string(result);
    }
}
