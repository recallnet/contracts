// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Recall} from "../src/token/Recall.sol";
import {IInterchainTokenService} from
    "@axelar-network/interchain-token-service/contracts/interfaces/IInterchainTokenService.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script, console} from "forge-std/Script.sol";

address constant INTERCHAIN_TOKEN_SERVICE = 0xB5FB4BE02232B1bBA4dC8f81dc24C26980dE9e3C;
string constant FILECOIN = "filecoin";
string constant ETHEREUM = "Ethereum";

/*
Examples of how to call each function using forge script

Command prefixes:
Ethereum:
forge script script/Bridge.s.sol:BridgeOps -vvv --rpc-url https://eth.merkle.io

Filecoin:
forge script script/Bridge.s.sol:BridgeOps -vvv -g 100000 --rpc-url https://api.node.glif.io/rpc/v1

To check if an address is a minter:
--sig "isMinter(address,address)" <proxy_address> <address_to_check>

To check the balance of an address:
--sig "checkBalance(address,address)" <proxy_address> <address_to_check>

To mint funds:
--broadcast --sig "mintFunds(address,address,uint256)" <proxy_address> <recipient_address> <amount> --private-key
<your_private_key>

To perform a cross-chain transfer:
--broadcast --sig "xChainTransfer(address,string,address,uint256)" <proxy_address> <destination_chain>
<recipient_address> <amount> --private-key <your_private_key>

To burn tokens:
--broadcast --sig "burnTokens(address,address,uint256)" <proxy_address> <account> <amount> --private-key
<your_private_key>

Note: Replace <proxy_address>, <address_to_check>, <recipient_address>, <amount>, <your_private_key>, and
<destination_chain> with actual values.
The --broadcast flag is used for functions that modify state (mintFunds and xChainTransfer).
For Filecoin, we add the -g 100000 flag due to gas price estimation issues. Adjust this value as needed.
The -vvv flag increases verbosity for more detailed output.
For <amount>, use the full token amount including decimal places. For example, if the token has 18 decimal places and
you want to transfer 1 token, use 1000000000000000000.*/

contract BridgeOps is Script {
    using Strings for string;

    function isMinter(address proxyAddress, address addressToCheck) public view {
        console.log("Proxy address: ", proxyAddress);

        // Create Recall instance
        Recall recall = Recall(proxyAddress);

        // Check if the given address has the MINTER_ROLE
        bool hasMinterRole = recall.hasRole(recall.MINTER_ROLE(), addressToCheck);

        console.log("Address to check: ", addressToCheck);
        console.log("Has MINTER_ROLE: ", hasMinterRole);
    }

    function mintFunds(address proxyAddress, address recipient, uint256 amount) public {
        console.log("Minting funds to address: ", recipient);
        console.log("Amount: ", amount);

        Recall recall = Recall(proxyAddress);
        vm.startBroadcast();
        // Ensure the caller has the MINTER_ROLE
        // solhint-disable-next-line custom-errors
        require(recall.hasRole(recall.MINTER_ROLE(), msg.sender), "Caller is not a minter");

        // Mint tokens to the recipient
        recall.mint(recipient, amount);
        vm.stopBroadcast();

        console.log("Minting successful");
    }

    function estimateGas(string memory destinationChain) public returns (uint256) {
        string memory sourceChain = destinationChain.equal(FILECOIN) ? ETHEREUM : FILECOIN;
        string[] memory inputs = new string[](3);
        inputs[0] = "bash";
        inputs[1] = "-c";
        // axelar api docs: https://docs.axelarscan.io/gmp#estimateGasFee
        inputs[2] = string(
            abi.encodePacked(
                "curl -s \'https://api.gmp.axelarscan.io?method=estimateGasFee&destinationChain=",
                destinationChain,
                "&sourceChain=",
                sourceChain,
                destinationChain.equal(FILECOIN) ? "&gasLimit=700000&gasMultiplier=1000\'" : "&gasLimit=70000\'"
            )
        );
        // Uncomment if you need to debug the curl command
        // console.log('Curl command:', inputs[2]);
        bytes memory res = vm.ffi(inputs);
        string memory resString = string(res);

        uint256 estimatedGas;
        // this party is pretty hacky. For some reason vm.ffi interprets the string containing
        // the integer as a hex if it's smaller than a certain size. 12 is just a guess.
        if (res.length < 12) {
            // Compressed/encoded value
            estimatedGas = decodeBytes(res);
        } else {
            // Plain string number
            estimatedGas = parseInt(resString);
        }

        console.log("Estimated gas:", estimatedGas);
        return estimatedGas;
    }

    function decodeBytes(bytes memory data) internal pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < data.length; i++) {
            uint8 value = uint8(data[i]);
            uint8 tens = value / 16;
            uint8 ones = value % 16;
            result = result * 100 + tens * 10 + ones;
        }
        return result;
    }

    function parseInt(string memory _value) internal pure returns (uint256) {
        bytes memory b = bytes(_value);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint8 c = uint8(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }

    function xChainTransfer(address proxyAddress, string memory destinationChain, address recipient, uint256 amount)
        public
        payable
    {
        console.log("Making cross-chain transfer");
        console.log("Destination chain: ", destinationChain);
        console.log("Recipient: ", recipient);
        console.log("Amount: ", amount);

        Recall recall = Recall(proxyAddress);

        uint256 gasEstimate = estimateGas(destinationChain);
        console.log("Gas estimate result: ", gasEstimate);

        // Convert recipient address to bytes
        // bytes memory recipientBytes = abi.encode(recipient);
        bytes memory recipientBytes = abi.encodePacked(recipient);

        vm.startBroadcast();

        // Log balance of the sender
        uint256 senderBalance = recall.balanceOf(msg.sender);
        console.log("Sender balance: ", senderBalance);

        // Approve the token manager to spend tokens on behalf of the sender
        recall.approve(INTERCHAIN_TOKEN_SERVICE, amount);
        // Log the currently approved amount for the its
        uint256 currentApproval = recall.allowance(msg.sender, INTERCHAIN_TOKEN_SERVICE);
        console.log("Current approval for ITS: ", currentApproval);

        vm.breakpoint("a");
        // Perform the interchain transfer with empty metadata
        recall.interchainTransfer{value: gasEstimate}(destinationChain, recipientBytes, amount, "");

        vm.stopBroadcast();

        console.log("Interchain transfer initiated");
    }

    function checkBalance(address proxyAddress, address accountToCheck) public view {
        console.log("Checking balance for address: ", accountToCheck);

        Recall recall = Recall(proxyAddress);
        // Get the balance of the account
        uint256 balance = recall.balanceOf(accountToCheck);

        console.log("Balance: ", balance);
    }

    function setApproval(address proxyAddress, address account, uint256 amount) public {
        console.log("Setting approval for address: ", account);
        console.log("Amount: ", amount);

        Recall recall = Recall(proxyAddress);

        vm.startBroadcast();

        uint256 currentApproval = recall.allowance(msg.sender, account);
        console.log("Current approval: ", currentApproval);

        recall.approve(account, amount + 1);

        currentApproval = recall.allowance(msg.sender, account);
        console.log("Current approval: ", currentApproval);

        vm.stopBroadcast();

        console.log("Approval set successfully");
    }
}
