// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {InterchainTokenExecutable} from "@axelar-network/interchain-token-service/contracts/executable/InterchainTokenExecutable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SubnetID} from "../types/CommonTypes.sol";
import {FvmAddress} from "../types/CommonTypes.sol";
import {IGatewayManagerFacet} from "./IGatewayManagerFacet.sol";

/// @title AutoDeposit
/// @notice Handles automatic token deposits from Axelar to IPC subnets
/// @dev Implements InterchainTokenExecutable for cross-chain token transfers
contract AutoDeposit is InterchainTokenExecutable {
    error WrongToken(address received, address expected);
    error TokenApprovalFailed(address token, address spender, uint256 amount);

    SubnetID public recallSubnet;
    IERC20 public immutable RECALL_TOKEN;
    IGatewayManagerFacet public immutable RECALL_GATEWAY;

    /// @notice Initializes the contract with required addresses and subnet ID
    /// @param subnet The subnet ID where tokens will be deposited
    /// @param token The address of the token to be handled
    /// @param gateway The address of the IPC gateway
    /// @param interchainTokenService_ The address of Axelar's interchain token service
    constructor(
        SubnetID memory subnet,
        address token,
        address gateway,
        address interchainTokenService_
    ) InterchainTokenExecutable(interchainTokenService_) {
        recallSubnet = subnet;
        RECALL_TOKEN = IERC20(token);
        RECALL_GATEWAY = IGatewayManagerFacet(gateway);
    }

    /// @inheritdoc InterchainTokenExecutable
    function _executeWithInterchainToken(
        bytes32, // commandId
        string calldata, // sourceChain
        bytes calldata, // sourceAddress
        bytes calldata data,
        bytes32, // tokenId
        address token,
        uint256 amount
    ) internal override {
        if (token != address(RECALL_TOKEN)) {
            revert WrongToken(token, address(RECALL_TOKEN));
        }

        bool success = RECALL_TOKEN.approve(address(RECALL_GATEWAY), amount);
        if (!success) {
            revert TokenApprovalFailed(address(RECALL_TOKEN), address(RECALL_GATEWAY), amount);
        }

        address recipient = abi.decode(data, (address));
        FvmAddress memory fvmAddress = convertToFvmAddr(recipient);

        SubnetID memory subnetCopy;
        subnetCopy.root = recallSubnet.root;
        subnetCopy.route = new address[](recallSubnet.route.length);
        for (uint256 i = 0; i < recallSubnet.route.length; i++) {
            subnetCopy.route[i] = recallSubnet.route[i];
        }

        RECALL_GATEWAY.fundWithToken({
            subnetId: subnetCopy,
            to: fvmAddress,
            amount: amount
        });
    }

    /// @notice Converts an Ethereum address to FVM address format
    /// @param _addr The Ethereum address to convert
    /// @return FVM formatted address
    function convertToFvmAddr(address _addr) internal pure returns (FvmAddress memory) {
        return FvmAddress({
            addrType: 1, // f1 address type
            payload: abi.encodePacked(_addr)
        });
    }
}