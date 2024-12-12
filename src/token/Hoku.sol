// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {InterchainTokenStandard} from
    "@axelar-network/interchain-token-service/contracts/interchain-token/InterchainTokenStandard.sol";
import {IInterchainTokenService} from
    "@axelar-network/interchain-token-service/contracts/interfaces/IInterchainTokenService.sol";
import {AccessControlUpgradeable} from
    "@openzeppelin/contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from
    "@openzeppelin/contracts-upgradeable/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from
    "@openzeppelin/contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

/// @title Hoku Token Contract
/// @dev Implements an upgradeable ERC20 token with additional features like pausing and minting
contract Hoku is
    ERC20BurnableUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    InterchainTokenStandard
{
    address public deployer;
    address internal _interchainTokenService;
    bytes32 internal _itsSalt;

    bytes32 public ADMIN_ROLE; // solhint-disable-line var-name-mixedcase
    bytes32 public MINTER_ROLE; // solhint-disable-line var-name-mixedcase

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract with the given environment
    /// @param prefix The prefix for the symbol
    /// @param its The interchain token service address
    /// @param itsSalt The salt for the interchain token service
    function initialize(string memory prefix, address its, bytes32 itsSalt) public initializer {
        string memory symbol = string(abi.encodePacked(prefix, "HOKU"));
        __ERC20_init("Hoku", symbol);
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        _interchainTokenService = its;
        _itsSalt = itsSalt;
        deployer = msg.sender;

        // Initialize roles
        ADMIN_ROLE = keccak256("ADMIN_ROLE");
        MINTER_ROLE = keccak256("MINTER_ROLE");

        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    /// @dev Mints new tokens
    /// @param to The address that will receive the minted tokens
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) public whenNotPaused onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /// @dev Pauses all token transfers
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @dev Unpauses all token transfers
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract
    /// @param newImplementation Address of the new implementation contract
    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(ADMIN_ROLE) {} // solhint-disable
        // no-empty-blocks

    /**
     * Axelar Interchain Token Standard, related functions
     */

    /**
     * @notice Returns the interchain token service
     * @return address The interchain token service contract
     */
    function interchainTokenService() public view override returns (address) {
        return _interchainTokenService;
    }

    /**
     * @notice Returns the tokenId for this token.
     * @return tokenId the token id.
     */
    function interchainTokenId() public view override returns (bytes32 tokenId) {
        tokenId = IInterchainTokenService(_interchainTokenService).interchainTokenId(deployer, _itsSalt);
    }

    /**
     * @notice A method to be overwritten that will decrease the allowance of the `spender` from `sender` by `amount`.
     * @dev Needs to be overwritten. This provides flexibility for the choice of ERC20 implementation used. Must revert
     * if allowance is not sufficient.
     */
    function _spendAllowance(address sender, address spender, uint256 amount)
        internal
        override(ERC20Upgradeable, InterchainTokenStandard)
    {
        uint256 _allowance = allowance(sender, spender);
        if (_allowance != type(uint256).max) {
            _approve(sender, spender, _allowance - amount);
        }
    }

    /**
     * ERC20 overrides to enable pausing
     */
    function transfer(address to, uint256 amount) public virtual override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }

    function approve(address spender, uint256 amount) public virtual override whenNotPaused returns (bool) {
        return super.approve(spender, amount);
    }

    function burn(uint256 amount) public virtual override whenNotPaused {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public virtual override whenNotPaused {
        super.burnFrom(account, amount);
    }

    /**
     * Interchain overrides to enable pausing
     */
    function _beforeInterchainTransfer(
        address from,
        string calldata destinationChain,
        bytes calldata destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) internal override(InterchainTokenStandard) whenNotPaused {}
}
