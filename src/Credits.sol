// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {ICredits} from "./interfaces/ICredits.sol";
import {
    Account,
    ApproveCreditParams,
    Balance,
    CreditApproval,
    CreditStats,
    StorageStats,
    SubnetStats,
    Usage
} from "./util/Types.sol";
import {Wrapper} from "./util/Wrapper.sol";

/// @title Credits Contract
/// @dev Implementation of the Hoku Blobs actor EVM interface. See {ICredits} for details.
contract Credits is ICredits {
    using Wrapper for bytes;

    // Constants for the actor and method IDs of the Hoku Blobs actor
    uint64 constant ACTOR_ID = 49;
    uint64 constant METHOD_GET_STATS = 188400153;
    uint64 constant METHOD_GET_ACCOUNT = 3435393067;
    uint64 constant METHOD_BUY_CREDIT = 1035900737;
    uint64 constant METHOD_APPROVE_CREDIT = 2276438360;
    uint64 constant METHOD_REVOKE_CREDIT = 37550845;

    constructor() {}

    /// @dev Helper function to decode the subnet stats from CBOR to solidity.
    /// @param data The encoded CBOR array of stats.
    /// @return stats The decoded stats.
    function decodeSubnetStats(bytes memory data) internal view returns (SubnetStats memory stats) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return stats;
        stats.balance = decoded[0].decodeCborBytesToUint256();
        stats.capacityFree = decoded[1].decodeCborBigIntToUint256();
        stats.capacityUsed = decoded[2].decodeCborBigIntToUint256();
        stats.creditSold = decoded[3].decodeCborBigIntToUint256();
        stats.creditCommitted = decoded[4].decodeCborBigIntToUint256();
        stats.creditDebited = decoded[5].decodeCborBigIntToUint256();
        stats.creditDebitRate = decoded[6].decodeCborBytesToUint64();
        stats.numAccounts = decoded[7].decodeCborBytesToUint64();
        stats.numBlobs = decoded[8].decodeCborBytesToUint64();
        stats.numResolving = decoded[9].decodeCborBytesToUint64();
    }

    /// @dev Helper function to decode an account from CBOR to solidity.
    /// @param data The encoded CBOR array of the account.
    /// @return account The decoded account.
    function decodeAccount(bytes memory data) internal view returns (Account memory account) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return account;
        account.capacityUsed = decoded[0].decodeCborBigIntToUint256();
        account.creditFree = decoded[1].decodeCborBigIntToUint256();
        account.creditCommitted = decoded[2].decodeCborBigIntToUint256();
        account.lastDebitEpoch = decoded[3].decodeCborBytesToUint64();
        // TODO: implement from hashmap: HashMap<Address, HashMap<Address, CreditApproval>>
        account.approvals = 0;
    }

    /// @dev Helper function to decode a credit approval from CBOR to solidity.
    /// @param data The encoded CBOR array of a credit approval.
    /// @return approval The decoded approval.
    function decodeCreditApproval(bytes memory data) internal view returns (CreditApproval memory approval) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return approval;
        approval.limit = decoded[0].decodeCborBigIntToUint256();
        approval.expiry = decoded[1].decodeCborBytesToUint64();
        approval.committed = decoded[2].decodeCborBigIntToUint256();
    }

    /// @dev Helper function to convert a credit account to a balance.
    /// @param account The account to convert.
    /// @return balance The balance of the account.
    function accountToBalance(Account memory account) internal pure returns (Balance memory balance) {
        balance.creditFree = account.creditFree;
        balance.creditCommitted = account.creditCommitted;
        balance.lastDebitEpoch = account.lastDebitEpoch;
    }

    /// @dev See {ICredits-getSubnetStats}.
    function getSubnetStats() public view returns (SubnetStats memory stats) {
        bytes memory data = Wrapper.readFromWasmActor(ACTOR_ID, METHOD_GET_STATS);

        return decodeSubnetStats(data);
    }

    /// @dev See {ICredits-getAccount}.
    function getAccount(address addr) public view returns (Account memory account) {
        bytes memory params = Wrapper.prepareParams(addr);
        bytes memory data = Wrapper.readFromWasmActor(ACTOR_ID, METHOD_GET_ACCOUNT, params);

        account = decodeAccount(data);
    }

    /// @dev See {ICredits-getStorageUsage}.
    function getStorageUsage(address addr) public view returns (Usage memory usage) {
        Account memory account = getAccount(addr);

        usage.capacityUsed = account.capacityUsed;
    }

    /// @dev See {ICredits-getStorageStats}.
    function getStorageStats() public view returns (StorageStats memory stats) {
        SubnetStats memory subnetStats = getSubnetStats();

        stats.capacityFree = subnetStats.capacityFree;
        stats.capacityUsed = subnetStats.capacityUsed;
        stats.numBlobs = subnetStats.numBlobs;
        stats.numResolving = subnetStats.numResolving;
    }

    /// @dev See {ICredits-getCreditStats}.
    function getCreditStats() external view returns (CreditStats memory stats) {
        SubnetStats memory subnetStats = getSubnetStats();

        stats.balance = subnetStats.balance;
        stats.creditSold = subnetStats.creditSold;
        stats.creditCommitted = subnetStats.creditCommitted;
        stats.creditDebited = subnetStats.creditDebited;
        stats.creditDebitRate = subnetStats.creditDebitRate;
        stats.numAccounts = subnetStats.numAccounts;
    }

    /// @dev See {ICredits-getCreditBalance}.
    function getCreditBalance(address addr) external view returns (Balance memory balance) {
        Account memory account = getAccount(addr);

        balance = accountToBalance(account);
    }

    /// @dev See {ICredits-buyCredit}.
    function buyCredit(address addr) external payable returns (Balance memory balance) {
        require(msg.value > 0, "Amount must be greater than zero");
        bytes memory params = Wrapper.prepareParams(addr);
        bytes memory data = Wrapper.writeToWasmActor(ACTOR_ID, METHOD_BUY_CREDIT, params);

        emit BuyCredit(addr, msg.value);
        Account memory account = decodeAccount(data);
        balance = accountToBalance(account);
    }

    /// @dev See {ICredits-approveCredit}.
    function approveCredit(address receiver) external returns (CreditApproval memory approval) {
        bytes memory params = Wrapper.encodeAddressAsArrayWithNulls(receiver, 3);
        // TODO: need to handle actual params instead of assuming nulls
        bytes memory data = Wrapper.writeToWasmActor(ACTOR_ID, METHOD_APPROVE_CREDIT, params);

        emit ApproveCredit(msg.sender, receiver);
        approval = decodeCreditApproval(data);
    }

    /// @dev See {ICredits-revokeCredit}.
    function revokeCredit(address receiver) external {
        bytes memory params = Wrapper.encodeAddressAsArrayWithNulls(receiver, 1);
        // TODO: need to handle actual params instead of assuming nulls
        Wrapper.writeToWasmActor(ACTOR_ID, METHOD_REVOKE_CREDIT, params);

        emit RevokeCredit(msg.sender, receiver);
    }
}
