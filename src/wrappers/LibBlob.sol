// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {
    Account,
    AddBlobParams,
    Approval,
    Balance,
    Blob,
    BlobSourceInfo,
    BlobStatus,
    BlobTuple,
    CreditApproval,
    CreditStats,
    StorageStats,
    SubnetStats,
    Subscriber,
    Subscription,
    SubscriptionGroup
} from "../types/BlobTypes.sol";
import {KeyValue} from "../types/CommonTypes.sol";
import {InvalidValue, LibWasm} from "./LibWasm.sol";

/// @title Blobs Library
/// @dev Utility functions for interacting with the Recall Blobs actor.
library LibBlob {
    using LibWasm for *;

    // Constants for the actor and method IDs of the Recall Blobs actor
    uint64 internal constant ACTOR_ID = 66;

    // User methods
    uint64 internal constant METHOD_ADD_BLOB = 913855558;
    uint64 internal constant METHOD_APPROVE_CREDIT = 2276438360;
    uint64 internal constant METHOD_BUY_CREDIT = 1035900737;
    uint64 internal constant METHOD_GET_ACCOUNT = 3435393067;
    uint64 internal constant METHOD_GET_BLOB = 1739171512;
    uint64 internal constant METHOD_GET_CREDIT_APPROVAL = 4218154481;
    uint64 internal constant METHOD_DELETE_BLOB = 4230608948;
    uint64 internal constant METHOD_OVERWRITE_BLOB = 609646161;
    uint64 internal constant METHOD_REVOKE_CREDIT = 37550845;
    uint64 internal constant METHOD_SET_ACCOUNT_SPONSOR = 228279820;

    // System methods
    uint64 internal constant METHOD_GET_ADDED_BLOBS = 2462124090;
    uint64 internal constant METHOD_GET_BLOB_STATUS = 3505892271;
    uint64 internal constant METHOD_GET_PENDING_BLOBS = 799531123;
    uint64 internal constant METHOD_GET_PENDING_BLOBS_COUNT = 1694235671;
    uint64 internal constant METHOD_GET_PENDING_BYTES_COUNT = 3795566289;

    // Metrics methods
    uint64 internal constant METHOD_GET_STATS = 188400153;

    /// @dev Helper function to decode the subnet stats from CBOR to solidity.
    /// @param data The encoded CBOR array of stats.
    /// @return stats The decoded stats.
    function decodeSubnetStats(bytes memory data) internal view returns (SubnetStats memory stats) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return stats;
        stats.balance = decoded[0].decodeCborBytesToUint256();
        stats.capacityFree = decoded[1].decodeCborBytesToUint64();
        stats.capacityUsed = decoded[2].decodeCborBytesToUint64();
        stats.creditSold = decoded[3].decodeCborBytesToUint256();
        stats.creditCommitted = decoded[4].decodeCborBytesToUint256();
        stats.creditDebited = decoded[5].decodeCborBytesToUint256();
        stats.tokenCreditRate = decodeTokenCreditRate(decoded[6]);
        stats.numAccounts = decoded[7].decodeCborBytesToUint64();
        stats.numBlobs = decoded[8].decodeCborBytesToUint64();
        stats.numAdded = decoded[9].decodeCborBytesToUint64();
        stats.bytesAdded = decoded[10].decodeCborBytesToUint64();
        stats.numResolving = decoded[11].decodeCborBytesToUint64();
        stats.bytesResolving = decoded[12].decodeCborBytesToUint64();
    }

    /// @dev Helper function to decode an account from CBOR to solidity.
    /// @param data The encoded CBOR array of the account.
    /// @return account The decoded account.
    function decodeAccount(bytes memory data) internal view returns (Account memory account) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return account;
        account.capacityUsed = decoded[0].decodeCborBytesToUint64();
        account.creditFree = decoded[1].decodeCborBytesToUint256();
        account.creditCommitted = decoded[2].decodeCborBytesToUint256();
        account.creditSponsor = decoded[3][0] == 0x00 ? address(0) : decoded[3].decodeCborAddress();
        account.lastDebitEpoch = decoded[4].decodeCborBytesToUint64();
        account.approvalsTo = decodeApprovals(decoded[5]);
        account.approvalsFrom = decodeApprovals(decoded[6]);
        account.maxTtl = decoded[7].decodeCborBytesToUint64();
        account.gasAllowance = decoded[8].decodeCborBytesToUint256();
    }

    /// @dev Helper function to decode a credit approval from CBOR to solidity.
    /// @param data The encoded CBOR array of a credit approval.
    /// @return approval The decoded approval.
    function decodeCreditApproval(bytes memory data) internal view returns (CreditApproval memory approval) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return approval;
        // Note: `limit` is encoded as a BigUInt (single array with no sign bit and values) when writing data, but it
        // gets encoded as a BigInt (array with sign bit and nested array of values) when reading data.
        approval.creditLimit = decoded[0].decodeCborBytesToUint256();
        approval.gasFeeLimit = decoded[1].decodeCborBytesToUint256();
        approval.expiry = decoded[2].decodeCborBytesToUint64();
        approval.creditUsed = decoded[3].decodeCborBytesToUint256();
        approval.gasFeeUsed = decoded[4].decodeCborBytesToUint256();
    }

    /// @dev Helper function to decode approvals from CBOR to solidity.
    /// @param data The encoded CBOR mapping of approvals. This is a `HashMap<Address, HashMap<Address,
    /// <CreditApproval>>>` in Rust.
    /// @return approvals The decoded approvals, represented as a nested {Approvals} array.
    function decodeApprovals(bytes memory data) internal view returns (Approval[] memory approvals) {
        bytes[2][] memory decoded = data.decodeCborMappingToBytes();
        approvals = new Approval[](decoded.length);
        for (uint256 i = 0; i < decoded.length; i++) {
            // The `addr` value is an delegated address as bytes like `040A14DC79964DA2C08B23698B3D3CC7CA32193D9955`
            approvals[i].addr = decoded[i][0].decodeCborAddress();
            approvals[i].approval = decodeCreditApproval(decoded[i][1]);
        }
    }

    /// @dev Convert a string to a blob status.
    /// @param status The string representation of the blob status, either "Added", "Pending", "Resolved", or "Failed".
    /// @return status The blob status.
    function decodeBlobStatus(bytes memory status) internal pure returns (BlobStatus) {
        bytes32 statusBytes = keccak256(status);
        if (statusBytes == keccak256(bytes("Added"))) {
            return BlobStatus.Added;
        } else if (statusBytes == keccak256(bytes("Pending"))) {
            return BlobStatus.Pending;
        } else if (statusBytes == keccak256(bytes("Resolved"))) {
            return BlobStatus.Resolved;
        } else {
            return BlobStatus.Failed;
        }
    }

    /// @dev Decode a subscription ID from CBOR.
    /// @param data The encoded subscription ID.
    /// @return decoded The decoded subscription ID.
    function decodeSubscriptionId(bytes memory data) internal view returns (string memory) {
        // Decode the mapping and return subscription ID bytes
        bytes[2][] memory decoded = data.decodeCborMappingToBytes();
        // An empty string gets decoded into 0x00 via `decodeCborMappingToBytes`
        return (decoded[0][1].length == 1 && decoded[0][1][0] == hex"00") ? "" : string(decoded[0][1]);
    }

    /// @dev Decode a subscription from CBOR.
    /// @param data The encoded CBOR array of a subscription.
    /// @return subscription The decoded subscription.
    function decodeSubscription(bytes memory data) internal view returns (Subscription memory subscription) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        subscription.added = decoded[0].decodeCborBytesToUint64();
        subscription.expiry = decoded[1].decodeCborBytesToUint64();
        subscription.source = string(decoded[2].decodeCborBlobHashOrNodeId());
        subscription.delegate = decoded[3].isCborNull() ? address(0) : decoded[3].decodeCborAddress();
        subscription.failed = decoded[4].decodeCborBool();
    }

    /// @dev Decode a subscription group from CBOR.
    /// @param data The encoded subscription group bytes
    /// @return group The decoded subscription group
    function decodeSubscriptionGroup(bytes memory data) internal view returns (SubscriptionGroup[] memory group) {
        bytes[2][] memory decoded = data.decodeCborMappingToBytes();
        group = new SubscriptionGroup[](decoded.length);
        for (uint256 j = 0; j < decoded.length; j++) {
            // String encoded in `SubscriptionGroup` (`HashMap<String, Subscription>`), not as `SubscriptionId` mapping
            group[j].subscriptionId = string(decoded[j][0]);
            group[j].subscription = decodeSubscription(decoded[j][1]);
        }
    }

    /// @dev Decode subscribers from CBOR.
    /// @param data The encoded CBOR mapping of subscribers.
    /// @return subscribers The decoded subscribers.
    function decodeSubscribers(bytes memory data) internal view returns (Subscriber[] memory subscribers) {
        bytes[2][] memory decoded = data.decodeCborMappingToBytes();
        subscribers = new Subscriber[](decoded.length);
        for (uint256 i = 0; i < decoded.length; i++) {
            subscribers[i].subscriptionId = decodeSubscriptionId(decoded[i][0]);
            subscribers[i].expiry = decoded[i][1].decodeCborBytesToUint64();
        }
    }

    /// @dev Decode a blob from CBOR.
    /// @param data The encoded CBOR array of a blob.
    /// @return blob The decoded blob.
    function decodeBlob(bytes memory data) internal view returns (Blob memory blob) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return blob;

        blob.size = decoded[0].decodeCborBytesToUint64();
        blob.metadataHash = string(decoded[1].decodeCborBlobHashOrNodeId());
        blob.subscribers = decodeSubscribers(decoded[2]);
        blob.status = decodeBlobStatus(decoded[3]);
    }

    /// @dev Decode a blob source info from CBOR.
    /// @param data The encoded CBOR array of a blob source info.
    /// @return sourceInfo The decoded blob source info.
    function decodeBlobSourceInfo(bytes memory data) internal view returns (BlobSourceInfo[] memory sourceInfo) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return sourceInfo;
        sourceInfo = new BlobSourceInfo[](decoded.length);
        for (uint256 i = 0; i < decoded.length; i++) {
            bytes[] memory decodedInner = decoded[i].decodeCborArrayToBytes();
            sourceInfo[i].subscriber = decodedInner[0].decodeCborAddress();
            sourceInfo[i].subscriptionId = decodeSubscriptionId(decodedInner[1]);
            sourceInfo[i].source = string(decodedInner[2].decodeCborBlobHashOrNodeId());
        }
    }

    /// @dev Decode pending blobs from CBOR.
    /// @param data The encoded CBOR array of pending blobs.
    /// @return blobs The decoded pending blobs.
    function decodeAddedOrPendingBlobs(bytes memory data) internal view returns (BlobTuple[] memory blobs) {
        bytes[] memory decoded = data.decodeCborArrayToBytes();
        if (decoded.length == 0) return blobs;
        blobs = new BlobTuple[](decoded.length);
        for (uint256 i = 0; i < decoded.length; i++) {
            bytes[] memory blobTuple = decoded[i].decodeCborArrayToBytes();
            blobs[i].blobHash = string(blobTuple[0].decodeCborBlobHashOrNodeId());
            blobs[i].sourceInfo = decodeBlobSourceInfo(blobTuple[1]);
        }
    }

    /// @dev Decode a token credit rate from CBOR.
    /// @param data The encoded CBOR array of a token credit rate.
    /// @return rate The decoded token credit rate.
    function decodeTokenCreditRate(bytes memory data) internal view returns (uint256) {
        bytes[2][] memory decoded = data.decodeCborMappingToBytes();
        // The TokenCreditRate mapping is `{rate: <value>}`, so we grab the value
        return decoded[0][1].decodeCborBigUintToUint256();
    }

    /// @dev Helper function to encode approve credit params.
    /// @param from (address): Account address that is approving the credit.
    /// @param to (address): Account address that is receiving the approval.
    /// @param caller (address): Optional restriction on caller address, e.g., an object store. Use zero address
    /// if unused, indicating a null value.
    /// @param creditLimit (uint256): Optional credit approval limit. Use zero if unused, indicating a null value.
    /// @param gasFeeLimit (uint256): Optional gas fee approval limit. Use zero if unused, indicating a null value.
    /// @param ttl (uint64): Optional credit approval time-to-live epochs. Minimum value is 3600 (1 hour). Use zero if
    /// unused, indicating a null value.
    /// @return encoded The encoded params.
    function encodeApproveCreditParams(
        address from,
        address to,
        address[] memory caller,
        uint256 creditLimit,
        uint256 gasFeeLimit,
        uint64 ttl
    ) internal pure returns (bytes memory) {
        bytes[] memory encoded = new bytes[](6);
        encoded[0] = from.encodeCborAddress();
        encoded[1] = to.encodeCborAddress();
        encoded[2] = encodeCallerAllowlist(caller);
        encoded[3] = creditLimit == 0 ? LibWasm.encodeCborNull() : creditLimit.encodeCborUint256AsBytes(true);
        encoded[4] = gasFeeLimit == 0 ? LibWasm.encodeCborNull() : gasFeeLimit.encodeCborUint256AsBytes(false);
        encoded[5] = ttl == 0 ? LibWasm.encodeCborNull() : ttl.encodeCborUint64();

        return encoded.encodeCborArray();
    }

    /// @dev Helper function to encode caller allowlist.
    /// @param caller The caller allowlist.
    /// @return encoded The encoded caller allowlist.
    function encodeCallerAllowlist(address[] memory caller) internal pure returns (bytes memory) {
        if (caller.length == 0) return LibWasm.encodeCborNull();
        bytes[] memory encoded = new bytes[](caller.length);
        for (uint256 i = 0; i < caller.length; i++) {
            encoded[i] = caller[i].encodeCborAddress();
        }
        return encoded.encodeCborArray();
    }

    /// @dev Helper function to encode set credit sponsor params.
    /// @param from The address of the account.
    /// @param sponsor The address of the sponsor. Use zero address if unused.
    /// @return encoded The encoded params.
    function encodeSetAccountSponsorParams(address from, address sponsor) internal pure returns (bytes memory) {
        bytes[] memory encoded = new bytes[](2);
        encoded[0] = from.encodeCborAddress();
        encoded[1] = sponsor == address(0) ? LibWasm.encodeCborNull() : sponsor.encodeCborAddress();
        return encoded.encodeCborArray();
    }

    /// @dev Helper function to encode revoke credit params.
    /// @param from The address of the account that is revoking the credit.
    /// @param to The address of the account that is receiving the credit.
    /// @param caller The address of the account that is required to call this method. Use zero address
    /// if unused, indicating a null value.
    /// @return encoded The encoded params.
    function encodeRevokeCreditParams(address from, address to, address caller) internal pure returns (bytes memory) {
        bytes[] memory encoded = new bytes[](3);
        encoded[0] = from.encodeCborAddress();
        encoded[1] = to.encodeCborAddress();
        encoded[2] = caller == address(0) ? LibWasm.encodeCborNull() : caller.encodeCborAddress();

        return encoded.encodeCborArray();
    }

    /// @dev Encode a subscription ID.
    /// @param subscriptionId The subscription ID.
    /// @return encoded The encoded subscription ID.
    function encodeSubscriptionId(string memory subscriptionId) internal pure returns (bytes memory) {
        // Encoded as a 1 value mapping with `inner` key and value of the subscription ID as bytes
        bytes[] memory encoded = new bytes[](3);
        encoded[0] = hex"a1";
        encoded[1] = "inner".encodeCborString();
        encoded[2] = subscriptionId.encodeCborString();
        return encoded.concatBytes();
    }

    /// @dev Encode add blob params.
    /// @param params The parameters for adding a blob.
    /// @return encoded The encoded parameters.
    function encodeAddBlobParams(AddBlobParams memory params) internal pure returns (bytes memory) {
        bytes[] memory encoded = new bytes[](8);
        encoded[0] = params.sponsor == address(0) ? LibWasm.encodeCborNull() : params.sponsor.encodeCborAddress();
        encoded[1] = params.source.encodeCborBlobHashOrNodeId();
        encoded[2] = params.blobHash.encodeCborBlobHashOrNodeId();
        // TODO: this value is currently hardcoded, but it'll eventually use the same method above
        encoded[3] = bytes(params.metadataHash).length == 0
            ? hex"0000000000000000000000000000000000000000000000000000000000000000".encodeCborFixedArray()
            : params.metadataHash.encodeCborBlobHashOrNodeId();
        encoded[4] = encodeSubscriptionId(params.subscriptionId);
        encoded[5] = params.size.encodeCborUint64();
        encoded[6] = params.ttl == 0 ? LibWasm.encodeCborNull() : params.ttl.encodeCborUint64();
        encoded[7] = params.from.encodeCborAddress();
        return encoded.encodeCborArray();
    }

    /// @dev Helper function to convert a credit account to a balance.
    /// @param account The account to convert.
    /// @return balance The balance of the account.
    function accountToBalance(Account memory account) internal pure returns (Balance memory balance) {
        balance.creditFree = account.creditFree;
        balance.creditCommitted = account.creditCommitted;
        balance.creditSponsor = account.creditSponsor;
        balance.lastDebitEpoch = account.lastDebitEpoch;
        balance.approvalsTo = account.approvalsTo;
        balance.approvalsFrom = account.approvalsFrom;
        balance.gasAllowance = account.gasAllowance;
    }

    /// @dev Helper function to convert subnet stats to storage stats.
    /// @param subnetStats The subnet stats to convert.
    /// @return stats The storage stats.
    function subnetStatsToStorageStats(SubnetStats memory subnetStats)
        internal
        pure
        returns (StorageStats memory stats)
    {
        stats.capacityFree = subnetStats.capacityFree;
        stats.capacityUsed = subnetStats.capacityUsed;
        stats.numBlobs = subnetStats.numBlobs;
        stats.numResolving = subnetStats.numResolving;
        stats.numAccounts = subnetStats.numAccounts;
        stats.bytesResolving = subnetStats.bytesResolving;
        stats.numAdded = subnetStats.numAdded;
        stats.bytesAdded = subnetStats.bytesAdded;
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
        stats.tokenCreditRate = subnetStats.tokenCreditRate;
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

    /// @dev Get the credit approval from one account to another, if it exists.
    /// @param from The address of the account.
    /// @param to The address of the account to check the approval for.
    /// @return approval The credit approval for the account.
    function getCreditApproval(address from, address to) external view returns (CreditApproval memory approval) {
        bytes[] memory encoded = new bytes[](2);
        encoded[0] = from.encodeCborAddress();
        encoded[1] = to.encodeCborAddress();
        bytes memory params = encoded.encodeCborArray();
        bytes memory data = LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_CREDIT_APPROVAL, params);
        return decodeCreditApproval(data);
    }

    /// @dev Get the credit balance of an account.
    /// @param addr The address of the account.
    /// @return balance The credit balance of the account.
    function getCreditBalance(address addr) external view returns (Balance memory balance) {
        Account memory account = getAccount(addr);
        return accountToBalance(account);
    }

    /// @dev Get a blob.
    /// @param blobHash The hash of the blob.
    /// @return blob The blob.
    function getBlob(string memory blobHash) external view returns (Blob memory blob) {
        bytes memory params = blobHash.encodeCborBlobHashOrNodeId();
        bytes memory data = LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_BLOB, params);
        return decodeBlob(data);
    }

    /// @dev Get the status of a blob.
    /// @param subscriber The address of the subscriber.
    /// @param blobHash The hash of the blob.
    /// @param subscriptionId The subscription ID.
    /// @return status The status of the blob.
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
        bytes memory decoded = data.decodeCborStringToBytes();
        return decodeBlobStatus(decoded);
    }

    /// @dev Get added blobs.
    /// @param size Maximum number of added blobs to return.
    /// @return blobs The added blobs.
    function getAddedBlobs(uint32 size) external view returns (BlobTuple[] memory blobs) {
        bytes memory params = size.encodeCborUint64();
        bytes memory data = LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_ADDED_BLOBS, params);
        return decodeAddedOrPendingBlobs(data);
    }

    /// @dev Get pending blobs.
    /// @param size Maximum number of added blobs to return.
    /// @return blobs The pending blobs.
    function getPendingBlobs(uint32 size) external view returns (BlobTuple[] memory blobs) {
        bytes memory params = size.encodeCborUint64();
        bytes memory data = LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_PENDING_BLOBS, params);
        return decodeAddedOrPendingBlobs(data);
    }

    /// @dev Get the number of pending blobs.
    /// @return count The number of pending blobs.
    function getPendingBlobsCount() external view returns (uint64) {
        bytes memory data = LibWasm.readFromWasmActor(ACTOR_ID, METHOD_GET_PENDING_BLOBS_COUNT);
        return data.decodeCborBytesToUint64();
    }

    /// @dev Get the number of pending bytes.
    /// @return count The number of pending bytes.
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
    /// @param to The address of the account to approve credits for.
    /// @param caller Optional restriction on caller address, e.g., an object store. Use zero address if unused.
    /// @param creditLimit Optional credit approval limit. Use zero if unused, indicating a null value.
    /// @param gasFeeLimit Optional gas fee limit. Use zero if unused, indicating a null value.
    /// @param ttl Optional credit approval time-to-live epochs. Minimum value is 3600 (1 hour). Use zero if
    /// unused, indicating a null value.
    /// @return data The credit approval (`CreditApproval`) response as bytes.
    function approveCredit(
        address from,
        address to,
        address[] memory caller,
        uint256 creditLimit,
        uint256 gasFeeLimit,
        uint64 ttl
    ) external returns (bytes memory data) {
        bytes memory params = encodeApproveCreditParams(from, to, caller, creditLimit, gasFeeLimit, ttl);
        return LibWasm.writeToWasmActor(ACTOR_ID, METHOD_APPROVE_CREDIT, params);
    }

    /// @dev Revoke credits for an account. Includes optional fields, which if set to zero, will be encoded as null.
    /// @param from The address of the account that owns the credits.
    /// @param to The address of the account to revoke credits for.
    /// @param caller Optional restriction on caller address, e.g., an object store.
    function revokeCredit(address from, address to, address caller) external {
        bytes memory params = encodeRevokeCreditParams(from, to, caller);
        // Note: response bytes are always empty
        LibWasm.writeToWasmActor(ACTOR_ID, METHOD_REVOKE_CREDIT, params);
    }

    /// @dev Set the credit sponsor for an account.
    /// @param from The address of the account.
    /// @param sponsor The address of the sponsor. Use zero address if unused.
    function setAccountSponsor(address from, address sponsor) external returns (bytes memory data) {
        bytes memory params = encodeSetAccountSponsorParams(from, sponsor);
        return LibWasm.writeToWasmActor(ACTOR_ID, METHOD_SET_ACCOUNT_SPONSOR, params);
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
    /// @param from Account address that initiated the deletion.
    function deleteBlob(address subscriber, string memory blobHash, string memory subscriptionId, address from)
        external
    {
        bytes[] memory encoded = new bytes[](4);
        encoded[0] = subscriber == address(0) ? LibWasm.encodeCborNull() : subscriber.encodeCborAddress();
        encoded[1] = blobHash.encodeCborBlobHashOrNodeId();
        encoded[2] = encodeSubscriptionId(subscriptionId);
        encoded[3] = from.encodeCborAddress();
        bytes memory params = encoded.encodeCborArray();
        // Note: response bytes are always empty
        LibWasm.writeToWasmActor(ACTOR_ID, METHOD_DELETE_BLOB, params);
    }

    /// @dev Overwrite a blob in the subnet by deleting and adding within a single transaction.
    /// @param oldHash The blake3 hash of the blob to be deleted.
    /// @param params The parameters for adding a blob.
    function overwriteBlob(string memory oldHash, AddBlobParams memory params) external returns (bytes memory data) {
        bytes[] memory encoded = new bytes[](2);
        encoded[0] = oldHash.encodeCborBlobHashOrNodeId();
        encoded[1] = encodeAddBlobParams(params);
        bytes memory _params = encoded.encodeCborArray();
        return LibWasm.writeToWasmActor(ACTOR_ID, METHOD_OVERWRITE_BLOB, _params);
    }
}
