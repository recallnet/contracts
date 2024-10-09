// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {ICredits} from "./interfaces/ICredits.sol";
import {
    Account,
    Approval,
    Approvals,
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
    using Wrapper for address;
    using Wrapper for bytes;
    using Wrapper for uint64;
    using Wrapper for uint256;

    // Constants for the actor and method IDs of the Hoku Blobs actor
    uint64 constant ACTOR_ID = 49;
    uint64 constant METHOD_APPROVE_CREDIT = 2276438360;
    uint64 constant METHOD_BUY_CREDIT = 1035900737;
    uint64 constant METHOD_GET_ACCOUNT = 3435393067;
    uint64 constant METHOD_GET_STATS = 188400153;
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
        account.approvals = decodeApprovals(decoded[4]);
    }

    /// @dev Helper function to decode a credit approval from CBOR to solidity.
    /// @param data The encoded CBOR array of a credit approval.
    /// @return approval The decoded approval.
    function decodeCreditApproval(bytes memory data) internal view returns (CreditApproval memory approval) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return approval;
        // Note: `limit` is encoded as a BigUInt (single array with no sign bit and values) when writing data, but it
        // gets encoded as a BigInt (array with sign bit and nested array of values) when reading data.
        approval.limit = decoded[0].decodeCborBigIntToUint256();
        approval.expiry = decoded[1].decodeCborBytesToUint64();
        approval.committed = decoded[2].decodeCborBigIntToUint256();
    }

    /// @dev Helper function to decode approvals from CBOR to solidity.
    /// @param encoded The encoded CBOR mapping of approvals. This is a `HashMap<Address, HashMap<Address,
    /// <CreditApproval>>>` in Rust.
    /// @return decoded The decoded approvals, represented as a nested {Approvals} array.
    function decodeApprovals(bytes memory encoded) internal view returns (Approvals[] memory decoded) {
        bytes[2][] memory approvals = encoded.decodeCborMappingToBytes();
        decoded = new Approvals[](approvals.length);
        for (uint256 i = 0; i < approvals.length; i++) {
            decoded[i].receiver = approvals[i][0].decodeCborAddress();
            bytes[2][] memory approvalBytes = approvals[i][1].decodeCborMappingToBytes();
            decoded[i].approval = new Approval[](approvalBytes.length);
            for (uint256 j = 0; j < approvalBytes.length; j++) {
                decoded[i].approval[j].requiredCaller = approvalBytes[j][0].decodeCborAddress();
                decoded[i].approval[j].approval = decodeCreditApproval(approvalBytes[j][1]);
            }
        }
    }

    /// @dev Helper function to encode approve credit params.
    /// @param params The {ApproveCreditParams} to encode. For optional params that need to be null, use a zero value.
    /// @return encoded The encoded params.
    function encodeApproveCreditParams(ApproveCreditParams memory params) internal pure returns (bytes memory) {
        bytes memory from = params.from.encodeCborAddress();
        bytes memory receiver = params.receiver.encodeCborAddress();
        bytes memory requiredCaller =
            params.requiredCaller == address(0) ? Wrapper.encodeCborNull() : params.requiredCaller.encodeCborAddress();
        // Note: `limit` is encoded as a BigUInt (single array with no sign bit and values) when writing data, but it
        // gets encoded as a BigInt (array with sign bit and nested array of values) when reading data.
        bytes memory limit = params.limit == 0 ? Wrapper.encodeCborNull() : params.limit.encodeCborBigUint();
        bytes memory ttl = params.ttl == 0 ? Wrapper.encodeCborNull() : params.ttl.encodeCborUint64();
        bytes[] memory encoded = new bytes[](5);
        encoded[0] = from;
        encoded[1] = receiver;
        encoded[2] = requiredCaller;
        encoded[3] = limit;
        encoded[4] = ttl;
        return Wrapper.encodeCborArray(encoded);
    }

    /// @dev Helper function to encode revoke credit params.
    /// @param from The address of the account that is revoking the credit.
    /// @param receiver The address of the account that is receiving the credit.
    /// @param requiredCaller The address of the account that is required to call this method.
    /// @return encoded The encoded params.
    function encodeRevokeCreditParams(address from, address receiver, address requiredCaller)
        internal
        pure
        returns (bytes memory)
    {
        bytes[] memory encoded = new bytes[](3);
        encoded[0] = from.encodeCborAddress();
        encoded[1] = receiver.encodeCborAddress();
        encoded[2] = requiredCaller == address(0) ? Wrapper.encodeCborNull() : requiredCaller.encodeCborAddress();
        return Wrapper.encodeCborArray(encoded);
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
        bytes memory params = Wrapper.encodeCborAddress(addr);
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
    function buyCredit() external payable returns (Balance memory balance) {
        require(msg.value > 0, "Amount must be greater than zero");
        bytes memory params = Wrapper.encodeCborAddress(msg.sender);
        bytes memory data = Wrapper.writeToWasmActor(ACTOR_ID, METHOD_BUY_CREDIT, params);

        emit BuyCredit(msg.sender, msg.value);
        Account memory account = decodeAccount(data);
        balance = accountToBalance(account);
    }

    /// @dev See {ICredits-buyCredit}.
    function buyCredit(address recipient) external payable returns (Balance memory balance) {
        require(msg.value > 0, "Amount must be greater than zero");
        bytes memory params = Wrapper.encodeCborAddress(recipient);
        bytes memory data = Wrapper.writeToWasmActor(ACTOR_ID, METHOD_BUY_CREDIT, params);

        emit BuyCredit(recipient, msg.value);
        Account memory account = decodeAccount(data);
        balance = accountToBalance(account);
    }

    /// @dev See {ICredits-approveCredit}.
    function approveCredit(address receiver) external returns (CreditApproval memory approval) {
        bytes memory encodedFrom = Wrapper.encodeCborAddress(msg.sender);
        bytes memory encodedReceiver = Wrapper.encodeCborAddress(receiver);
        bytes[] memory encoded = new bytes[](2);
        encoded[0] = encodedFrom;
        encoded[1] = encodedReceiver;
        bytes memory params = Wrapper.encodeCborArrayWithNulls(encoded, 3);
        bytes memory data = Wrapper.writeToWasmActor(ACTOR_ID, METHOD_APPROVE_CREDIT, params);

        approval = decodeCreditApproval(data);
        emit ApproveCredit(msg.sender, receiver, approval);
    }

    /// @dev See {ICredits-approveCredit}.
    function approveCredit(address from, address receiver) external returns (CreditApproval memory approval) {
        bytes memory encodedFrom = Wrapper.encodeCborAddress(from);
        bytes memory encodedReceiver = Wrapper.encodeCborAddress(receiver);
        bytes[] memory encoded = new bytes[](2);
        encoded[0] = encodedFrom;
        encoded[1] = encodedReceiver;
        bytes memory params = Wrapper.encodeCborArrayWithNulls(encoded, 3);
        bytes memory data = Wrapper.writeToWasmActor(ACTOR_ID, METHOD_APPROVE_CREDIT, params);

        approval = decodeCreditApproval(data);
        emit ApproveCredit(from, receiver, approval);
    }

    /// @dev See {ICredits-approveCredit}.
    function approveCredit(ApproveCreditParams memory approveParams)
        external
        returns (CreditApproval memory approval)
    {
        bytes memory params = encodeApproveCreditParams(approveParams);
        bytes memory data = Wrapper.writeToWasmActor(ACTOR_ID, METHOD_APPROVE_CREDIT, params);

        approval = decodeCreditApproval(data);
        emit ApproveCredit(approveParams.from, approveParams.receiver, approval);
    }

    /// @dev See {ICredits-revokeCredit}.
    function revokeCredit(address receiver) external {
        bytes memory params = encodeRevokeCreditParams(msg.sender, receiver, address(0));
        Wrapper.writeToWasmActor(ACTOR_ID, METHOD_REVOKE_CREDIT, params);

        emit RevokeCredit(msg.sender, receiver);
    }

    /// @dev See {ICredits-revokeCredit}.
    function revokeCredit(address from, address receiver) external {
        bytes memory params = encodeRevokeCreditParams(from, receiver, address(0));
        Wrapper.writeToWasmActor(ACTOR_ID, METHOD_REVOKE_CREDIT, params);

        emit RevokeCredit(from, receiver);
    }

    /// @dev See {ICredits-revokeCredit}.
    function revokeCredit(address from, address receiver, address requiredCaller) external {
        bytes memory params = encodeRevokeCreditParams(from, receiver, requiredCaller);
        Wrapper.writeToWasmActor(ACTOR_ID, METHOD_REVOKE_CREDIT, params);

        emit RevokeCredit(from, receiver);
    }
}
