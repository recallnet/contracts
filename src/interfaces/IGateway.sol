// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.23;

import {IpcEnvelope} from "../types/CommonTypes.sol";
import {SubnetID} from "../types/CommonTypes.sol";
import {FvmAddress} from "../types/CommonTypes.sol";

/// @title Gateway interface
/// @author LimeChain team
interface IGateway {

    /// @notice fundWithToken locks the specified amount of tokens in the ERC20 contract linked to the subnet, and
    /// moves the value down the hierarchy, crediting the funds as native coins to the specified address
    /// in the destination network.
    ///
    /// This method expects the caller to have approved the gateway to spend `amount` tokens on their behalf
    /// (usually done through IERC20#approve). Tokens are locked by calling IERC20#transferFrom(caller, address(this), amount).
    /// A failure in transferring tokens to the gateway will revert the call.
    ///
    /// It's possible to call this method from an EOA or a contract. Regardless, it's recommended to approve strictly
    /// the amount that will subsequently be deposited into the subnet. Keeping outstanding approvals is not recommended.
    ///
    /// Calling this method on a subnet whose supply source is not 'ERC20' will revert with UnexpectedAsset().
    function fundWithToken(SubnetID calldata subnetId, FvmAddress calldata to, uint256 amount) external;
    
    /// @notice sendContractXnetMessage sends an arbitrary cross-message to other subnet in the hierarchy.
    // TODO: add the right comment and function name here.
    function sendContractXnetMessage(
        IpcEnvelope calldata envelope
    ) external payable returns (IpcEnvelope memory committed);

}
