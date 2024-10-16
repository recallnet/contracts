// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {
    Account,
    Approval,
    Approvals,
    Balance,
    CreditApproval,
    CreditStats,
    StorageStats,
    SubnetStats,
    Usage
} from "../types/CreditTypes.sol";
import {LibWasm} from "./LibWasm.sol";

library LibCredit {
    using LibWasm for *;

    // Constants for the actor and method IDs of the Hoku Blobs actor
    uint64 constant ACTOR_ID = 49;
    uint64 constant METHOD_APPROVE_CREDIT = 2276438360;
    uint64 constant METHOD_BUY_CREDIT = 1035900737;
    uint64 constant METHOD_GET_ACCOUNT = 3435393067;
    uint64 constant METHOD_GET_STATS = 188400153;
    uint64 constant METHOD_REVOKE_CREDIT = 37550845;

    /// @dev Helper function to decode the subnet stats from CBOR to solidity.
    /// @param data The encoded CBOR array of stats.
    /// @return stats The decoded stats.
    function decodeSubnetStats(bytes memory data) external view returns (SubnetStats memory stats) {
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
    function decodeAccount(bytes memory data) external view returns (Account memory account) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return account;
        account.capacityUsed = decoded[0].decodeCborBigIntToUint256();
        account.creditFree = decoded[1].decodeCborBigIntToUint256();
        account.creditCommitted = decoded[2].decodeCborBigIntToUint256();
        account.lastDebitEpoch = decoded[3].decodeCborBytesToUint64();
        account.approvals = decodeApprovals(decoded[4]);
    }

    /// @dev Helper function to decode a credit approval from CBOR to solidity.
    /// @param data The encoded CBOR array of a credit approval.
    /// @return approval The decoded approval.
    function decodeCreditApproval(bytes memory data) public view returns (CreditApproval memory approval) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return approval;
        // Note: `limit` is encoded as a BigUInt (single array with no sign bit and values) when writing data, but it
        // gets encoded as a BigInt (array with sign bit and nested array of values) when reading data.
        approval.limit = decoded[0].decodeCborBigIntToUint256();
        approval.expiry = decoded[1].decodeCborBytesToUint64();
        approval.committed = decoded[2].decodeCborBigIntToUint256();
    }

    /// @dev Helper function to decode approvals from CBOR to solidity.
    /// @param data The encoded CBOR mapping of approvals. This is a `HashMap<Address, HashMap<Address,
    /// <CreditApproval>>>` in Rust.
    /// @return approvals The decoded approvals, represented as a nested {Approvals} array.
    function decodeApprovals(bytes memory data) internal view returns (Approvals[] memory approvals) {
        bytes[2][] memory decoded = data.decodeCborMappingToBytes();
        approvals = new Approvals[](decoded.length);
        for (uint256 i = 0; i < decoded.length; i++) {
            approvals[i].receiver = decoded[i][0].decodeCborAddress();
            bytes[2][] memory approvalBytes = decoded[i][1].decodeCborMappingToBytes();
            approvals[i].approval = new Approval[](approvalBytes.length);
            for (uint256 j = 0; j < approvalBytes.length; j++) {
                approvals[i].approval[j].requiredCaller = approvalBytes[j][0].decodeCborAddress();
                approvals[i].approval[j].approval = decodeCreditApproval(approvalBytes[j][1]);
            }
        }
    }

    /// @dev Helper function to encode approve credit params.
    /// @param from (address): Account address that is approving the credit.
    /// @param receiver (address): Account address that is receiving the approval.
    /// @param requiredCaller (address): Optional restriction on caller address, e.g., an object store. Use zero address
    /// if unused, indicating a null value.
    /// @param limit (uint256): Optional credit approval limit. Use zero if unused, indicating a null value.
    /// @param ttl (uint64): Optional credit approval time-to-live epochs. Minimum value is 3600 (1 hour). Use zero if
    /// unused, indicating a null value.
    /// @return encoded The encoded params.
    function encodeApproveCreditParams(
        address from,
        address receiver,
        address requiredCaller,
        uint256 limit,
        uint64 ttl
    ) public pure returns (bytes memory) {
        bytes[] memory encoded = new bytes[](5);
        encoded[0] = from.encodeCborAddress();
        encoded[1] = receiver.encodeCborAddress();
        encoded[2] = requiredCaller == address(0) ? LibWasm.encodeCborNull() : requiredCaller.encodeCborAddress();
        // Note: `limit` is encoded as a BigUInt (single array with no sign bit and values) when writing data, but it
        // gets encoded as a BigInt (array with sign bit and nested array of values) when reading data.
        encoded[3] = limit == 0 ? LibWasm.encodeCborNull() : limit.encodeCborBigUint();
        encoded[4] = ttl == 0 ? LibWasm.encodeCborNull() : ttl.encodeCborUint64();

        return encoded.encodeCborArray();
    }

    /// @dev Helper function to encode revoke credit params.
    /// @param from The address of the account that is revoking the credit.
    /// @param receiver The address of the account that is receiving the credit.
    /// @param requiredCaller The address of the account that is required to call this method. Use zero address
    /// if unused, indicating a null value.
    /// @return encoded The encoded params.
    function encodeRevokeCreditParams(address from, address receiver, address requiredCaller)
        public
        pure
        returns (bytes memory)
    {
        bytes[] memory encoded = new bytes[](3);
        encoded[0] = from.encodeCborAddress();
        encoded[1] = receiver.encodeCborAddress();
        encoded[2] = requiredCaller == address(0) ? LibWasm.encodeCborNull() : requiredCaller.encodeCborAddress();

        return encoded.encodeCborArray();
    }

    /// @dev Helper function to convert a credit account to a balance.
    /// @param account The account to convert.
    /// @return balance The balance of the account.
    function accountToBalance(Account memory account) external pure returns (Balance memory balance) {
        balance.creditFree = account.creditFree;
        balance.creditCommitted = account.creditCommitted;
        balance.lastDebitEpoch = account.lastDebitEpoch;
    }

    /// @dev Helper function to convert subnet stats to storage stats.
    /// @param subnetStats The subnet stats to convert.
    /// @return stats The storage stats.
    function subnetStatsToStorageStats(SubnetStats memory subnetStats)
        external
        pure
        returns (StorageStats memory stats)
    {
        stats.capacityFree = subnetStats.capacityFree;
        stats.capacityUsed = subnetStats.capacityUsed;
        stats.numBlobs = subnetStats.numBlobs;
        stats.numResolving = subnetStats.numResolving;
    }

    /// @dev Helper function to convert a credit account to a usage.
    /// @param account The account to convert.
    /// @return usage The usage of the account.
    function accountToUsage(Account memory account) external pure returns (Usage memory usage) {
        usage.capacityUsed = account.capacityUsed;
    }

    /// @dev Helper function to convert subnet stats to credit stats.
    /// @param subnetStats The subnet stats to convert.
    /// @return stats The credit stats.
    function subnetStatsToCreditStats(SubnetStats memory subnetStats)
        external
        pure
        returns (CreditStats memory stats)
    {
        stats.balance = subnetStats.balance;
        stats.creditSold = subnetStats.creditSold;
        stats.creditCommitted = subnetStats.creditCommitted;
        stats.creditDebited = subnetStats.creditDebited;
        stats.creditDebitRate = subnetStats.creditDebitRate;
        stats.numAccounts = subnetStats.numAccounts;
    }

    /// @dev Get the subnet stats.
    /// @return data The subnet stats.
    function getSubnetStats() external view returns (bytes memory data) {
        return LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_STATS);
    }

    /// @dev Get the credit account for an address.
    /// @param addr The address of the account.
    /// @return data The credit account for the address.
    function getAccount(address addr) external view returns (bytes memory data) {
        bytes memory params = addr.encodeCborAddress();
        return LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_ACCOUNT, params);
    }

    /// @dev Buy credits for a specified account with a `msg.value` for number of native currency to spend on credits.
    /// @param recipient The address of the account.
    /// @return data The balance of the account after buying credits.
    function buyCredit(address recipient) external returns (bytes memory data) {
        require(msg.value > 0, "Amount must be greater than zero");
        bytes memory params = recipient.encodeCborAddress();
        return LibWasm.writeToWasmActor(ACTOR_ID, METHOD_BUY_CREDIT, params);
    }

    /// @dev Approve credits for an account. This is a simplified variant when no optional fields are needed.
    /// @param from The address of the account that owns the credits.
    /// @param receiver The address of the account to approve credits for.
    /// @param requiredCaller Optional restriction on caller address, e.g., an object store. Use zero address if unused.
    /// @param limit Optional credit approval limit. Use zero if unused, indicating a null value.
    /// @param ttl Optional credit approval time-to-live epochs. Minimum value is 3600 (1 hour). Use zero if
    /// unused, indicating a null value.
    /// @return data The credit approval response.
    function approveCredit(address from, address receiver, address requiredCaller, uint256 limit, uint64 ttl)
        external
        returns (bytes memory data)
    {
        bytes memory params = encodeApproveCreditParams(from, receiver, requiredCaller, limit, ttl);
        return LibWasm.writeToWasmActor(ACTOR_ID, METHOD_APPROVE_CREDIT, params);
    }

    /// @dev Revoke credits for an account. Includes optional fields, which if set to zero, will be encoded as null.
    /// @param from The address of the account that owns the credits.
    /// @param receiver The address of the account to revoke credits for.
    /// @param requiredCaller Optional restriction on caller address, e.g., an object store.
    function revokeCredit(address from, address receiver, address requiredCaller) external {
        bytes memory params = encodeRevokeCreditParams(from, receiver, requiredCaller);
        LibWasm.writeToWasmActor(ACTOR_ID, METHOD_REVOKE_CREDIT, params);
    }
}
