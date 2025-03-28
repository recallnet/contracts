// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.23;

import {Test} from 'forge-std/Test.sol';
import {Relay} from '../src/token/Relay.sol';
import {IGateway} from '../src/interfaces/IGateway.sol';
import {SubnetID, FvmAddress, IpcEnvelope} from '../src/types/CommonTypes.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IInterchainTokenExecutable} from '@axelar-network/interchain-token-service/contracts/interfaces/IInterchainTokenExecutable.sol';

// Mock Axelar Gateway contract
contract MockAxelarGateway {
    function callContract(
        address destination,
        bytes32 commandId,
        string calldata sourceChain,
        bytes calldata sourceAddress,
        bytes calldata payload,
        bytes32 tokenId,
        address token,
        uint256 amount
    ) external {
        IInterchainTokenExecutable(destination).executeWithInterchainToken(
            commandId,
            sourceChain,
            sourceAddress,
            payload,
            tokenId,
            token,
            amount
        );
    }
}

// Mock Token contract
contract MockToken is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    constructor() {
        _mint(msg.sender, 1000000);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, 'ERC20: transfer amount exceeds balance');
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'ERC20: mint to the zero address');

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, 'ERC20: insufficient allowance');
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

// Mock Gateway contract
contract MockGateway is IGateway {
    mapping(bytes32 => mapping(address => uint256)) public bridgedBalances;
    mapping(address => uint256) public totalBridged;

    function fundWithToken(
        SubnetID calldata subnetId,
        FvmAddress calldata /* recipient */,  // unused in mock but required by interface
        uint256 amount
    ) external {
        // Get the token from the transaction data since msg.sender is the Relay contract
        address token = address(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a);  // Hardcode the token address for testing
        bytes32 subnetKey = keccak256(abi.encode(subnetId));
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), 'Transfer failed');
        bridgedBalances[subnetKey][token] += amount;
        totalBridged[token] += amount;
    }

    function sendContractXnetMessage(
        IpcEnvelope calldata envelope
    ) external payable returns (IpcEnvelope memory) {
        return envelope;
    }

    // Helper functions for testing
    function getBridgedAmount(SubnetID calldata subnetId, address token) external view returns (uint256) {
        bytes32 subnetKey = keccak256(abi.encode(subnetId));
        return bridgedBalances[subnetKey][token];
    }

    function getTotalBridgedAmount(address token) external view returns (uint256) {
        return totalBridged[token];
    }
}

contract RelayTest is Test {
    MockAxelarGateway axelarGateway;
    MockGateway gateway;
    MockToken token;
    Relay relay;
    string constant TOKEN_SYMBOL = 'TEST';
    address owner;

    function setUp() public {
        // Set owner address
        owner = address(this);

        // Deploy mock contracts
        axelarGateway = new MockAxelarGateway();
        gateway = new MockGateway();
        token = new MockToken();

        // Deploy Relay contract with owner
        vm.prank(owner);
        relay = new Relay(address(gateway), address(axelarGateway));

        // Setup token
        vm.prank(owner);
        relay.setToken(address(token));

        // Setup subnet
        address[] memory route = new address[](0);
        vm.prank(owner);
        relay.setSubnet(SubnetID(1, route));

        // Setup initial token balances
        token.mint(address(axelarGateway), 1000000);
    }

    function testExecuteWithInterchainToken() public {
        // Setup
        vm.startPrank(address(axelarGateway));
        token.approve(address(relay), 1000);
        token.transfer(address(relay), 1000);  // Transfer tokens to Relay first

        // Execute
        bytes32 tokenSymbol = keccak256(abi.encodePacked(TOKEN_SYMBOL));
        relay.executeWithInterchainToken(
            bytes32(uint256(1)),
            'ethereum',
            abi.encodePacked(bytes32(uint256(2))),
            abi.encodePacked(bytes32(uint256(2))),
            tokenSymbol,
            address(token),
            1000
        );
        vm.stopPrank();

        // Verify
        assertEq(token.balanceOf(address(gateway)), 1000);
        address[] memory route = new address[](0);
        assertEq(gateway.getBridgedAmount(SubnetID(1, route), address(token)), 1000);
        assertEq(gateway.getTotalBridgedAmount(address(token)), 1000);
    }

    function testExecuteWithInterchainTokenPaused() public {
        // Setup
        vm.prank(owner);
        relay.pause();

        vm.startPrank(address(axelarGateway));
        // Execute
        bytes32 tokenSymbol = keccak256(abi.encodePacked(TOKEN_SYMBOL));
        vm.expectRevert(abi.encodeWithSignature('BridgeIsPaused()'));
        relay.executeWithInterchainToken(
            bytes32(uint256(1)),
            'ethereum',
            abi.encodePacked(bytes32(uint256(2))),
            abi.encodePacked(bytes32(uint256(2))),
            tokenSymbol,
            address(token),
            1000
        );
        vm.stopPrank();
    }

    function testExecuteWithInterchainTokenUnauthorizedGateway() public {
        // Execute
        bytes32 tokenSymbol = keccak256(abi.encodePacked(TOKEN_SYMBOL));
        vm.expectRevert(abi.encodeWithSignature('UnauthorizedGateway(address)', address(this)));
        relay.executeWithInterchainToken(
            bytes32(uint256(1)),
            'ethereum',
            abi.encodePacked(bytes32(uint256(2))),
            abi.encodePacked(bytes32(uint256(2))),
            tokenSymbol,
            address(token),
            1000
        );
    }
} 