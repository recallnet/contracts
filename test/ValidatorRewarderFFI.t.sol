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
        uint256 initialSupply = token.totalSupply();
        uint256 blocks = 52560 * 5; // 5 years
        uint256 checkpointPeriod = 600;
        uint256 numCheckpoints = blocks / checkpointPeriod;

        address[] memory claimants = new address[](3);
        claimants[0] = address(0x111);
        claimants[1] = address(0x222);
        claimants[2] = address(0x333);

        uint256[] memory blocksCommitted = new uint256[](3);
        blocksCommitted[0] = 100; // 1/6 of blocks
        blocksCommitted[1] = 200; // 1/3 of blocks
        blocksCommitted[2] = 300; // 1/2 of blocks

        // Calculate expected total tokens for all blocks (in base units)
        uint256 totalBlocks = blocks;
        uint256 expectedTotalTokens = (totalBlocks * 1 ether) / rewarder.BLOCKS_PER_TOKEN();

        console2.log("Expected total tokens for all blocks:", expectedTotalTokens);

        // Process claims checkpoint by checkpoint
        for (uint256 i = 0; i < numCheckpoints; i++) {
            uint64 currentCheckpoint = uint64((i + 1) * checkpointPeriod);

            // Calculate expected rewards for this checkpoint (in base units)
            uint256 checkpointTokens = (checkpointPeriod * 1 ether) / rewarder.BLOCKS_PER_TOKEN();

            // Run python script to calculate validator shares
            uint256[] memory params = new uint256[](3);
            params[0] = checkpointTokens; // total tokens for checkpoint (in base units)
            params[1] = checkpointPeriod; // checkpoint period
            params[2] = 0; // blocks committed (set per validator)

            string memory jsonStr;

            for (uint256 j = 0; j < claimants.length; j++) {
                // Calculate expected validator share using Python script
                params[2] = blocksCommitted[j];
                jsonStr = runPythonScript(PYTHON_SCRIPT, params);
                uint256 expectedValidatorShare = vm.parseJsonUint(jsonStr, ".validator_share");

                // Store balance before claim
                uint256 balanceBefore = token.balanceOf(claimants[j]);

                // Submit claim
                vm.prank(SUBNET_ROUTE);
                rewarder.notifyValidClaim(
                    createSubnet(), currentCheckpoint, createValidatorData(claimants[j], blocksCommitted[j])
                );

                uint256 actualReward = token.balanceOf(claimants[j]) - balanceBefore;

                // Verify validator rewards
                assertApproxEqAbs(
                    actualReward,
                    expectedValidatorShare,
                    1000, // Allow for difference of up to 1000 base units
                    string.concat("Validator reward mismatch at checkpoint ", vm.toString(currentCheckpoint))
                );
            }
        }

        // After all checkpoints are processed, verify total minted amount
        uint256 actualTotalMinted = token.totalSupply() - initialSupply;
        assertApproxEqAbs(
            actualTotalMinted,
            expectedTotalTokens,
            100000, // Allow for difference of up to 100000 base units or 0.0000000000001 tokens
            "Total minted tokens should match expected"
        );

        console2.log("Actual total tokens minted:", actualTotalMinted);
    }

    // Helper functions
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
