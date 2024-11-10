// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {
    Account,
    AddBlobParams,
    Approval,
    Approvals,
    Balance,
    Blob,
    BlobStatus,
    CreditApproval,
    CreditStats,
    StorageStats,
    SubnetStats,
    Subscriber,
    SubscriptionGroup
} from "../types/BlobTypes.sol";
import {KeyValue} from "../types/CommonTypes.sol";
import {InvalidValue, LibWasm} from "./LibWasm.sol";

/// @title Blobs Library
/// @dev Utility functions for interacting with the Hoku Blobs actor.
library LibBlob {
    using LibWasm for *;

    // Constants for the actor and method IDs of the Hoku Blobs actor
    uint64 internal constant ACTOR_ID = 66;
    // General getters
    uint64 internal constant METHOD_GET_ACCOUNT = 3435393067;
    uint64 internal constant METHOD_GET_STATS = 188400153;
    // Credit methods
    uint64 internal constant METHOD_APPROVE_CREDIT = 2276438360;
    uint64 internal constant METHOD_BUY_CREDIT = 1035900737;
    uint64 internal constant METHOD_REVOKE_CREDIT = 37550845;
    // Blob methods
    uint64 internal constant METHOD_ADD_BLOB = 913855558;
    uint64 internal constant METHOD_GET_BLOB = 1739171512;
    uint64 internal constant METHOD_GET_BLOB_STATUS = 3505892271;
    uint64 internal constant METHOD_GET_PENDING_BLOBS = 799531123;
    uint64 internal constant METHOD_GET_PENDING_BLOBS_COUNT = 1694235671;
    uint64 internal constant METHOD_GET_PENDING_BYTES_COUNT = 3795566289;
    uint64 internal constant METHOD_DELETE_BLOB = 4230608948;

    /// @dev Helper function to decode the subnet stats from CBOR to solidity.
    /// @param data The encoded CBOR array of stats.
    /// @return stats The decoded stats.
    function decodeSubnetStats(bytes memory data) internal view returns (SubnetStats memory stats) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return stats;
        stats.balance = decoded[0].decodeCborBytesToUint256();
        stats.capacityTotal = decoded[1].decodeCborBigIntToUint256();
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
        approval.used = decoded[2].decodeCborBigIntToUint256();
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

    /// @dev Convert a string to a blob status.
    /// @param status The string representation of the blob status, either "Resolved", "Pending" or "Failed".
    /// @return status The blob status.
    function decodeBlobStatus(bytes memory status) internal pure returns (BlobStatus) {
        bytes32 statusBytes = keccak256(status);
        if (statusBytes == keccak256(bytes("Resolved"))) {
            return BlobStatus.Resolved;
        } else if (statusBytes == keccak256(bytes("Pending"))) {
            return BlobStatus.Pending;
        } else {
            return BlobStatus.Failed;
        }
    }

    /// @dev Decode a subscription ID from CBOR.
    /// @param data The encoded subscription ID.
    /// @return decoded The decoded subscription ID.
    function decodeSubscriptionId(bytes memory data) internal view returns (string memory) {
        // If the leading indicator is `a1`, it's a mapping with a single key-value pair; else, default
        if (data[0] == hex"a1") {
            // Decode the mapping with Key and subscription ID bytes (a single key-value pair)
            bytes[2][] memory decoded = data.decodeCborMappingToBytes();
            // Second value is the subscription ID bytes (ignore the first value `Key` key)
            bytes memory subscriptionId = decoded[0][1].decodeCborBytesArrayToBytes();
            return string(subscriptionId);
        } else {
            return "Default";
        }
    }

    /// @dev Decode subscribers from CBOR.
    /// @param data The encoded CBOR mapping of subscribers.
    /// @return subscribers The decoded subscribers.
    function decodeSubscribers(bytes memory data) internal view returns (Subscriber[] memory subscribers) {
        bytes[2][] memory decoded = data.decodeCborMappingToBytes();
        subscribers = new Subscriber[](decoded.length);
        for (uint256 i = 0; i < decoded.length; i++) {
            subscribers[i].subscriber = decoded[i][0].decodeCborAddress();
            bytes[2][] memory subscriptionGroupBytes = decoded[i][1].decodeCborMappingToBytes();
            subscribers[i].subscriptionGroup = new SubscriptionGroup[](subscriptionGroupBytes.length);
            for (uint256 j = 0; j < subscriptionGroupBytes.length; j++) {
                subscribers[i].subscriptionGroup[j].subscriptionId = decodeSubscriptionId(subscriptionGroupBytes[j][0]);
                subscribers[i].subscriptionGroup[j].subscription = subscriptionGroupBytes[j][1];
            }
        }
    }

    /// @dev Decode a blob from CBOR.
    /// @param data The encoded CBOR array of a blob.
    /// @return blob The decoded blob.
    function decodeBlob(bytes memory data) internal view returns (Blob memory blob) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return blob;
        blob.size = decoded[0].decodeCborBytesToUint64();
        blob.metadataHash = string(decoded[1].decodeBlobHash());
        blob.subscribers = decodeSubscribers(decoded[2]);
        blob.status = decodeBlobStatus(decoded[3]);
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
    ) internal pure returns (bytes memory) {
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
        internal
        pure
        returns (bytes memory)
    {
        bytes[] memory encoded = new bytes[](3);
        encoded[0] = from.encodeCborAddress();
        encoded[1] = receiver.encodeCborAddress();
        encoded[2] = requiredCaller == address(0) ? LibWasm.encodeCborNull() : requiredCaller.encodeCborAddress();

        return encoded.encodeCborArray();
    }

    /// @dev Encode a subscription ID.
    /// @param subscriptionId The subscription ID.
    /// @return encoded The encoded subscription ID.
    function encodeSubscriptionId(string memory subscriptionId) internal pure returns (bytes memory) {
        if (bytes(subscriptionId).length == 0) {
            // Encoded as the raw string "Default"
            return "Default".encodeCborString();
        } else {
            // Encoded as a 1 value mapping with `Key` key and an encoded bytes array of the subscription ID
            bytes[] memory encoded = new bytes[](3);
            encoded[0] = hex"a1";
            encoded[1] = "Key".encodeCborString();
            encoded[2] = bytes(subscriptionId).encodeCborBytesArray();
            return encoded.concatBytes();
        }
    }

    /// @dev Encode add blob params.
    /// @param params The parameters for adding a blob.
    /// @return encoded The encoded parameters.
    function encodeAddBlobParams(AddBlobParams memory params) internal pure returns (bytes memory) {
        bytes[] memory encoded = new bytes[](7);
        encoded[0] = params.sponsor == address(0) ? LibWasm.encodeCborNull() : params.sponsor.encodeCborAddress();
        encoded[1] = params.source.encodeCborBlobHashOrNodeId();
        encoded[2] = params.blobHash.encodeCborBlobHashOrNodeId();
        // TODO: this value is currently hardcoded, but it'll eventually use the same method above
        encoded[3] = hex"0000000000000000000000000000000000000000000000000000000000000000".encodeCborFixedArray();
        encoded[4] = encodeSubscriptionId(params.subscriptionId);
        encoded[5] = params.size.encodeCborUint64();
        encoded[6] = params.ttl == 0 ? LibWasm.encodeCborNull() : params.ttl.encodeCborUint64();
        return encoded.encodeCborArray();
    }

    /// @dev Helper function to convert a credit account to a balance.
    /// @param account The account to convert.
    /// @return balance The balance of the account.
    function accountToBalance(Account memory account) internal pure returns (Balance memory balance) {
        balance.creditFree = account.creditFree;
        balance.creditCommitted = account.creditCommitted;
        balance.lastDebitEpoch = account.lastDebitEpoch;
    }

    /// @dev Helper function to convert subnet stats to storage stats.
    /// @param subnetStats The subnet stats to convert.
    /// @return stats The storage stats.
    function subnetStatsToStorageStats(SubnetStats memory subnetStats)
        internal
        pure
        returns (StorageStats memory stats)
    {
        stats.capacityTotal = subnetStats.capacityTotal;
        stats.capacityUsed = subnetStats.capacityUsed;
        stats.numBlobs = subnetStats.numBlobs;
        stats.numResolving = subnetStats.numResolving;
    }

    /// @dev Helper function to convert subnet stats to credit stats.
    /// @param subnetStats The subnet stats to convert.
    /// @return stats The credit stats.
    function subnetStatsToCreditStats(SubnetStats memory subnetStats)
        internal
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
    /// @return stats The subnet stats.
    function getSubnetStats() public view returns (SubnetStats memory stats) {
        bytes memory data = LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_STATS);
        return decodeSubnetStats(data);
    }

    /// @dev Get the credit account for an address.
    /// @param addr The address of the account.
    /// @return account The credit account for the address.
    function getAccount(address addr) public view returns (Account memory account) {
        bytes memory params = addr.encodeCborAddress();
        bytes memory data = LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_ACCOUNT, params);
        return decodeAccount(data);
    }

    /// @dev Get the storage usage for an account.
    /// @param addr The address of the account.
    /// @return usage The storage usage for the account.
    function getStorageUsage(address addr) external view returns (uint256) {
        Account memory account = getAccount(addr);
        return account.capacityUsed;
    }

    /// @dev Get the storage stats for the subnet.
    /// @return stats The storage stats for the subnet.
    function getStorageStats() external view returns (StorageStats memory stats) {
        SubnetStats memory subnetStats = getSubnetStats();
        return subnetStatsToStorageStats(subnetStats);
    }

    /// @dev Get the subnet-wide credit statistics.
    /// @return stats The subnet-wide credit statistics.
    function getCreditStats() external view returns (CreditStats memory stats) {
        SubnetStats memory subnetStats = getSubnetStats();
        return subnetStatsToCreditStats(subnetStats);
    }

    /// @dev Get the credit balance of an account.
    /// @param addr The address of the account.
    /// @return balance The credit balance of the account.
    function getCreditBalance(address addr) external view returns (Balance memory balance) {
        Account memory account = getAccount(addr);
        return accountToBalance(account);
    }

    function getBlob(string memory blobHash) external view returns (Blob memory blob) {
        bytes memory params = blobHash.encodeCborBlobHashOrNodeId();
        bytes memory data = LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_BLOB, params);
        return decodeBlob(data);
    }

    function getBlobStatus(address subscriber, string memory blobHash, string memory subscriptionId)
        external
        view
        returns (BlobStatus status)
    {
        bytes[] memory encoded = new bytes[](3);
        encoded[0] = subscriber.encodeCborAddress();
        encoded[1] = blobHash.encodeCborBlobHashOrNodeId();
        encoded[2] = encodeSubscriptionId(subscriptionId);
        bytes memory params = encoded.encodeCborArray();
        bytes memory data = LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_BLOB_STATUS, params);
        return decodeBlobStatus(data);
    }

    function getPendingBlobs(uint32 size) external view returns (bytes memory) {
        bytes memory params = size.encodeCborUint64();
        return LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_PENDING_BLOBS, params);
    }

    function getPendingBlobsCount() external view returns (uint64) {
        bytes memory data = LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_PENDING_BLOBS_COUNT);
        return data.decodeCborBytesToUint64();
    }

    function getPendingBytesCount() external view returns (uint64) {
        bytes memory data = LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_PENDING_BYTES_COUNT);
        return data.decodeCborBytesToUint64();
    }

    /// @dev Buy credits for a specified account with a `msg.value` for number of native currency to spend on credits.
    /// @param recipient The address of the account.
    /// @return data The balance of the account after buying credits.
    function buyCredit(address recipient) external returns (bytes memory data) {
        if (msg.value == 0) revert InvalidValue("Amount must be greater than zero");
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
    /// @return data The credit approval (`CreditApproval`) response as bytes.
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
        // Note: response bytes are always empty
        LibWasm.writeToWasmActor(ACTOR_ID, METHOD_REVOKE_CREDIT, params);
    }

    /// @dev Add a blob to the subnet.
    /// @param params The parameters for adding a blob.
    /// @return data The response from the actor.
    function addBlob(AddBlobParams memory params) external returns (bytes memory data) {
        bytes memory _params = encodeAddBlobParams(params);
        return LibWasm.writeToWasmActor(ACTOR_ID, METHOD_ADD_BLOB, _params);
    }

    /// @dev Delete a blob from the subnet.
    /// @param subscriber The address of the subscriber.
    /// @param blobHash The hash of the blob.
    /// @param subscriptionId The subscription ID.
    function deleteBlob(address subscriber, string memory blobHash, string memory subscriptionId) external {
        bytes[] memory encoded = new bytes[](3);
        encoded[0] = subscriber == address(0) ? LibWasm.encodeCborNull() : subscriber.encodeCborAddress();
        encoded[1] = blobHash.encodeCborBlobHashOrNodeId();
        encoded[2] = encodeSubscriptionId(subscriptionId);
        bytes memory params = encoded.encodeCborArray();
        // Note: response bytes are always empty
        LibWasm.writeToWasmActor(ACTOR_ID, METHOD_DELETE_BLOB, params);
    }
}
