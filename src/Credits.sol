// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Actor} from "@filecoin-solidity/v0.8/utils/Actor.sol";
import {FilAddresses} from "@filecoin-solidity/v0.8/utils/FilAddresses.sol";
import {CommonTypes} from "@filecoin-solidity/v0.8/types/CommonTypes.sol";
import {BytesCBOR} from "@filecoin-solidity/v0.8/cbor/BytesCbor.sol";
import {FilecoinCBOR} from "@filecoin-solidity/v0.8/cbor/FilecoinCBOR.sol";
import {CBORDecoding} from "./util/solidity-cbor/CBORDecoding.sol";
import {Utilities} from "./util/Utilities.sol";
import {ByteParser} from "./util/solidity-cbor/ByteParser.sol";

/// @dev The stored representation of a credit account.
struct Account {
    /// Total size of all blobs managed by the account.
    uint256 capacityUsed;
    /// Current free credit in byte-blocks that can be used for new commitments.
    uint256 creditFree;
    /// Current committed credit in byte-blocks that will be used for debits.
    uint256 creditCommitted;
    /// The chain epoch of the last debit.
    uint64 lastDebitEpoch;
    /// Credit approvals to other accounts, keyed by receiver, keyed by caller
    // TODO: implement from hashmap: HashMap<Address, HashMap<Address, CreditApproval>>
    // mapping(address => mapping(address => uint256)) public approvals;
    uint64 approvals;
}

/// @dev Credit ba`lance for an account.
struct Balance {
    /// Current free credit in byte-blocks that can be used for new commitments.
    uint256 creditFree;
    /// Current committed credit in byte-blocks that will be used for debits.
    uint256 creditCommitted;
    /// The chain epoch of the last debit.
    uint64 lastDebitEpoch;
}


/// @dev Params for revoking credit.
struct RevokeCreditParams {
    /// Account address that is receiving the approval.
    address receiver;
    /// Optional restriction on caller address, e.g., an object store.
    /// This allows the origin of a transaction to use an approval limited to the caller.
    address requiredCaller;
}


/// @dev Params for approving credit.
struct ApproveCreditParams {
    /// Account address that is receiving the approval.
    address receiver;
    /// Optional restriction on caller address, e.g., an object store.
    /// The receiver will only be able to use the approval via a caller contract.
    address requiredCaller;
    /// Optional credit approval limit.
    /// If specified, the approval becomes invalid once the committed credits reach the
    /// specified limit.
    uint256 limit;
    /// Optional credit approval time-to-live epochs.
    /// If specified, the approval becomes invalid after this duration.
    uint64 ttl;
}


/// @dev The stats of the blob actor.
/// This is the return type for the blobs actor `get_stats` method:
/// - The `balance` is a uint256, encoded as a CBOR byte string (e.g., 0x00010f0cf064dd59200000).
/// - The `capacityFree`, `capacityUsed`, `creditSold`, `creditCommitted`, and `creditDebited` are
/// Rust BigInt types: a CBOR array with a sign (assume non-negative) and array of numbers (e.g,. 0x8201820001).
/// - The `creditDebitRate`, `numAccounts`, `numBlobs`, and `numResolving` are uint64, encoded as a
/// CBOR byte string (e.g., 0x317).
struct SubnetStats {
    /// The current token balance earned by the subnet.
    uint256 balance;
    /// The total free storage capacity of the subnet.
    uint256 capacityFree;
    /// The total used storage capacity of the subnet.
    uint256 capacityUsed;
    /// The total number of credits sold in the subnet.
    uint256 creditSold;
    /// The total number of credits committed to active storage in the subnet.
    uint256 creditCommitted;
    /// The total number of credits debited in the subnet.
    uint256 creditDebited;
    /// The byte-blocks per atto token rate set at genesis.
    uint64 creditDebitRate;
    /// Total number of debit accounts.
    uint64 numAccounts;
    /// Total number of actively stored blobs.
    uint64 numBlobs;
    /// Total number of currently resolving blobs.
    uint64 numResolving;
}


/// @dev Subnet-wide credit statistics.
struct CreditStats {
    /// The current token balance earned by the subnet.
    uint256 balance;
    /// The total number of credits sold in the subnet.
    uint256 creditSold;
    /// The total number of credits committed to active storage in the subnet.
    uint256 creditCommitted;
    /// The total number of credits debited in the subnet.
    uint256 creditDebited;
    /// The byte-blocks per atto token rate set at genesis.
    uint64 creditDebitRate;
    /// Total number of debit accounts.
    uint64 numAccounts;
}


/// @dev Emitted when an account buys credits.
event BuyCredit(address indexed addr, uint256 amount);


/// @dev Hoku Blobs actor EVM interface for managing credits, and querying credit or storage stats.
/// See Rust implementation for details: https://github.com/hokunet/ipc/blob/develop/fendermint/actors/blobs/src/actor.rs
contract Credits is CBORDecoding, ByteParser {
    using Utilities for bytes;

    CommonTypes.FilActorId internal _actorId = CommonTypes.FilActorId.wrap(49);
    uint64 internal constant EMPTY_CODEC = 0x00;
    uint64 internal constant CBOR_CODEC = 0x51;

    constructor() {}

    /// @dev Helper function to decode the subnet stats from CBOR to solidity.
    /// @param data The encoded CBOR array of stats.
    /// @return stats The decoded stats.
    function decodeSubnetStats(bytes memory data) internal view returns (SubnetStats memory stats) {
        bytes[] memory decoded = decodeArray(data);
        stats.balance = bytesToBigNumber(decoded[0]);
        stats.capacityFree = decoded[1].decodeCborBigIntToUint256();
        stats.capacityUsed = decoded[2].decodeCborBigIntToUint256();
        stats.creditSold = decoded[3].decodeCborBigIntToUint256();
        stats.creditCommitted = decoded[4].decodeCborBigIntToUint256();
        stats.creditDebited = decoded[5].decodeCborBigIntToUint256();
        stats.creditDebitRate = bytesToUint64(decoded[6]);
        stats.numAccounts = bytesToUint64(decoded[7]);
        stats.numBlobs = bytesToUint64(decoded[8]);
        stats.numResolving = bytesToUint64(decoded[9]);
    }

    /// @dev Helper function to decode an account from CBOR to solidity.
    /// @param data The encoded CBOR array of the account.
    /// @return account The decoded account.
    function decodeAccount(bytes memory data) internal view returns (Account memory account) {
        bytes[] memory decoded = decodeArray(data);
        account.capacityUsed = decoded[0].decodeCborBigIntToUint256();
        account.creditFree = decoded[1].decodeCborBigIntToUint256();
        account.creditCommitted = decoded[2].decodeCborBigIntToUint256();
        account.lastDebitEpoch = bytesToUint64(decoded[3]);
        // TODO: implement from hashmap: HashMap<Address, HashMap<Address, CreditApproval>>
        account.approvals = 0;
    }

    /// @dev Get the subnet stats.
    /// @return stats The subnet stats.
    function getSubnetStats() public view returns (SubnetStats memory stats) {
        bytes memory raw_request = new bytes(0);
        (int256 exit, bytes memory data) = Actor.callByIDReadOnly(_actorId, uint64(188400153), EMPTY_CODEC, raw_request);

        require(exit == 0, "Actor returned an error");

        return decodeSubnetStats(data);
    }

    /// @dev Get the subnet-wide credit statistics.
    /// @return stats The subnet-wide credit statistics.
    function getCreditStats() external view returns (CreditStats memory stats) {
        SubnetStats memory subnetStats = getSubnetStats();

        stats.balance = subnetStats.balance;
        stats.creditSold = subnetStats.creditSold;
        stats.creditCommitted = subnetStats.creditCommitted;
        stats.creditDebited = subnetStats.creditDebited;
        stats.creditDebitRate = subnetStats.creditDebitRate;
        stats.numAccounts = subnetStats.numAccounts;
    }

    /// @dev Get the credit account for an address.
    /// @param addr The address of the account.
    /// @return account The credit account for the address.
    function getAccount(address addr) public view returns (Account memory account) {
        CommonTypes.FilAddress memory filAddr = FilAddresses.fromEthAddress(addr);
        bytes memory raw_request = FilecoinCBOR.serializeAddress(filAddr);
        (int256 exit, bytes memory data) = Actor.callByIDReadOnly(_actorId, uint64(3435393067), CBOR_CODEC, raw_request);

        require(exit == 0, "Actor returned an error");

        account = decodeAccount(data);
    }

    /// @dev Get the credit balance of an account.
    /// @param addr The address of the account.
    /// @return balance The credit balance of the account.
    function getCreditBalance(address addr) external view returns (Balance memory balance) {
        Account memory account = getAccount(addr);

        balance.creditFree = account.creditFree;
        balance.creditCommitted = account.creditCommitted;
        balance.lastDebitEpoch = account.lastDebitEpoch;
    }

    /// @dev Buy credits for an account with a `msg.value` for number of native currency to spend on credits.
    /// @param addr The address of the account.
    function buyCredit(address addr) external payable {
        require(msg.value > 0, "Amount must be greater than zero");
        CommonTypes.FilAddress memory filAddr = FilAddresses.fromEthAddress(addr);
        bytes memory raw_request = FilecoinCBOR.serializeAddress(filAddr); 
        (int256 exit, /* bytes memory data */) = Actor.callByID(
            _actorId,
            uint64(1035900737),
            CBOR_CODEC,
            raw_request,
            msg.value,
            false // static call
        );

        require(exit == 0, "Actor returned an error");

        emit BuyCredit(addr, msg.value);
    }

    // function approveCredit(ApproveCreditParams memory params) external {
    //     bytes memory raw_request = new bytes(0);
    //     (int256 exit, /* bytes memory data */) = Actor.callByID(
    //         _actorId,
    //         uint64(2276438360),
    //         CBOR_CODEC,
    //         raw_request,
    //         0,
    //         false //static call
    //     );

    //     require(exit == 0, "Actor returned an error");
    // }

    // function revokeCredit(RevokeCreditParams memory params) external {
    //     bytes memory raw_request = new bytes(0);
    //     (int256 exit, /* bytes memory data */) = Actor.callByID(
    //         _actorId,
    //         uint64(37550845),
    //         CBOR_CODEC,
    //         raw_request,
    //         0,
    //         false //static call
    //     );

    //     require(exit == 0, "Actor returned an error");
    // }
}
