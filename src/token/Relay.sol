// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.23;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IInterchainTokenExecutable} from '@axelar-network/interchain-token-service/contracts/interfaces/IInterchainTokenExecutable.sol';
import {IGateway} from '../interfaces/IGateway.sol';
import {SubnetID, FvmAddress} from '../types/CommonTypes.sol';
import {FvmAddressHelper} from '../util/FvmAddressHelper.sol';
import {SubnetIDHelper} from '../util/SubnetIDHelper.sol';

/// @title Relay
/// @notice A bridge contract that accepts tokens from Axelar and bridges them to IPC child subnet
contract Relay is IInterchainTokenExecutable, Ownable {
    using SafeERC20 for IERC20;
    using SubnetIDHelper for SubnetID;

    // The IPC Gateway contract
    IGateway public immutable gateway;

    // The token contract address
    address public token;

    // The target subnet for bridging
    SubnetID public targetSubnet;

    // Axelar gateway contract that is allowed to call executeWithInterchainToken
    address public immutable axelarGateway;

    // State variables
    bool public paused;

    event TokenSet(address indexed token);
    event SubnetSet(SubnetID subnet);
    event BridgeStarted(address indexed to, uint256 amount);
    event BridgeCompleted(address indexed to, uint256 amount);
    event BridgePaused();
    event BridgeUnpaused();

    error UnknownToken();
    error UnauthorizedGateway(address sender);
    error InvalidToken(address token);
    error InvalidSubnet();
    error TokenNotSet();
    error SubnetNotSet();
    error BridgeIsPaused();
    error BridgeNotPaused();

    /**
     * @param _gateway Address of the IPC Gateway contract
     * @param _axelarGateway Address of the Axelar Gateway contract
     */
    constructor(
        address _gateway,
        address _axelarGateway
    ) Ownable(msg.sender) {
        if (_axelarGateway == address(0)) revert InvalidSubnet();
        gateway = IGateway(_gateway);
        axelarGateway = _axelarGateway;
        paused = false;
    }

    /**
     * @notice Sets the token address
     * @param _token The token address
     */
    function setToken(address _token) external onlyOwner {
        if (_token == address(0)) revert InvalidToken(_token);
        token = _token;
        emit TokenSet(_token);
    }

    /**
     * @notice Sets the target subnet
     * @param _subnet The target subnet ID
     */
    function setSubnet(SubnetID calldata _subnet) external onlyOwner {
        if (_subnet.root == 0) revert InvalidSubnet();
        targetSubnet = _subnet;
        emit SubnetSet(_subnet);
    }

    /// @notice Pauses the bridge
    function pause() external onlyOwner {
        if (paused) {
            revert BridgeIsPaused();
        }
        paused = true;
        emit BridgePaused();
    }

    /// @notice Unpauses the bridge
    function unpause() external onlyOwner {
        if (!paused) {
            revert BridgeNotPaused();
        }
        paused = false;
        emit BridgeUnpaused();
    }

    /// @notice Executes a token transfer from Axelar to the IPC child subnet
    /// @param commandId The unique identifier for this cross-chain transfer
    /// @param sourceChain The source chain of the token transfer
    /// @param sourceAddress The source address of the token transfer
    /// @param data The payload containing the destination address
    /// @param tokenId The token ID from Axelar
    /// @param _token The token address
    /// @param amount The amount of tokens being transferred
    function executeWithInterchainToken(
        bytes32 commandId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata data,
        bytes32 tokenId,
        address _token,
        uint256 amount
    ) external override returns (bytes32) {
        if (paused) {
            revert BridgeIsPaused();
        }

        if (msg.sender != axelarGateway) {
            revert UnauthorizedGateway(msg.sender);
        }

        if (_token != token) {
            revert UnknownToken();
        }

        if (token == address(0)) {
            revert TokenNotSet();
        }

        if (targetSubnet.root == 0) {
            revert SubnetNotSet();
        }

        // Decode the destination address from the payload
        address to = abi.decode(data, (address));

        // Emit event for tracking
        emit BridgeStarted(to, amount);

        // Approve the gateway to spend tokens
        IERC20(token).approve(address(gateway), amount);

        // Convert recipient address to FVM address format
        FvmAddress memory fvmRecipient = FvmAddressHelper.from(to);

        // Bridge tokens through IPC Gateway
        gateway.fundWithToken(targetSubnet, fvmRecipient, amount);

        emit BridgeCompleted(to, amount);
        
        return keccak256(abi.encodePacked(commandId, sourceChain, sourceAddress, data, tokenId, token, amount));
    }
} 