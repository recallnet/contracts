use crate::blobs_facade::iblobsfacade::IBlobsFacade::{getPendingBlobsCountCall, getPendingBytesCountCall, getStorageStatsCall, getStorageUsageCall, BlobAdded, BlobDeleted, BlobFinalized, BlobPending, IBlobsFacadeEvents};
use crate::types::H160;
use alloy_primitives::U256;
use anyhow::Result;
use fvm_shared::address::{Address as FVMAddress};
use alloy_sol_types::SolCall;
use fil_actors_runtime::{actor_error, ActorError};
use fendermint_actor_blobs_shared::state::{Hash, PublicKey};

pub struct BlobSourceInfo<'a> {
    pub subscriber: FVMAddress,
    pub subscription_id: String,
    pub source: &'a[u8; 32],
}

pub struct BlobTuple<'a> {
    pub blob_hash: &'a [u8; 32],
    pub source_info: Vec<BlobSourceInfo<'a>>,
}

pub mod get_pending_bytes_count {
    use super::*;

    pub const SELECTOR: [u8; 4] = getPendingBytesCountCall::SELECTOR;

    pub fn abi_encode_result(value: u64) -> Vec<u8> {
        getPendingBytesCountCall::abi_encode_returns(&(value,))
    }
}

pub mod get_pending_blobs_count {
    use super::*;
    pub const SELECTOR: [u8; 4] = getPendingBlobsCountCall::SELECTOR;
    pub fn abi_encode_result(value: u64) -> Vec<u8> {
        getPendingBlobsCountCall::abi_encode_returns(&(value,))
    }
}

pub mod get_storage_usage {
    use super::*;
    pub const SELECTOR: [u8; 4] = getStorageUsageCall::SELECTOR;
    pub fn abi_decode_input(bytes: &[u8]) -> Result<getStorageUsageCall, ActorError> {
        getStorageUsageCall::abi_decode(bytes, true).map_err(|err| {
            actor_error!(illegal_argument, format!("Invalid parameters {}", err))
        })
    }
    pub fn abi_encode_result(value: u64) -> Vec<u8> {
        let u256 = U256::from(value);
        getStorageUsageCall::abi_encode_returns(&(u256,))
    }
}

pub mod get_storage_stats {
    use super::*;
    pub use crate::blobs_facade::iblobsfacade::IBlobsFacade::StorageStats;

    pub const SELECTOR: [u8; 4] = getStorageStatsCall::SELECTOR;
    pub fn abi_encode_result(value: StorageStats) -> Vec<u8> {
        getStorageStatsCall::abi_encode_returns(&(value,))
    }
}

pub mod get_subnet_stats {
    use fvm_shared::bigint::BigUint;
    use super::*;
    use crate::blobs_facade::iblobsfacade::IBlobsFacade::{getSubnetStatsCall, SubnetStats as Value};
    use crate::types::BigUintWrapper;

    pub struct SubnetStats {
        pub balance: BigUint,
        pub capacity_free: u64,
        pub capacity_used: u64,
        pub credit_sold: BigUint,
        pub credit_committed: BigUint,
        pub credit_debited: BigUint,
        pub token_credit_rate: BigUint,
        pub num_accounts: u64,
        pub num_blobs: u64,
        pub num_added: u64,
        pub bytes_added: u64,
        pub num_resolving: u64,
        pub bytes_resolving: u64,
    }

    pub const SELECTOR: [u8; 4] = getSubnetStatsCall::SELECTOR;

    pub fn abi_encode_result(value: SubnetStats) -> Vec<u8> {
        getSubnetStatsCall::abi_encode_returns(&(Value {
            balance: BigUintWrapper(value.balance).into(),
            capacityFree: value.capacity_free,
            capacityUsed: value.capacity_used,
            creditSold: BigUintWrapper(value.credit_sold).into(),
            creditCommitted: BigUintWrapper(value.credit_committed).into(),
            creditDebited: BigUintWrapper(value.credit_debited).into(),
            tokenCreditRate: BigUintWrapper(value.token_credit_rate).into(),
            numAccounts: value.num_accounts,
            numBlobs: value.num_blobs,
            numAdded: value.num_added,
            bytesAdded: value.bytes_added,
            numResolving: value.num_resolving,
            bytesResolving: value.bytes_resolving
        },))
    }
}

pub mod get_added_blobs {
    use super::*;
    use crate::blobs_facade::iblobsfacade::IBlobsFacade::{getAddedBlobsCall, BlobTuple as BlobTupleInner, BlobSourceInfo as BlobSourceInfoInner};

    pub const SELECTOR: [u8; 4] = getAddedBlobsCall::SELECTOR;

    pub fn abi_decode_input(bytes: &[u8]) -> Result<getAddedBlobsCall, ActorError> {
        getAddedBlobsCall::abi_decode(bytes, true).map_err(|err| {
            actor_error!(illegal_argument, format!("Invalid parameters {}", err))
        })
    }

    pub fn abi_encode_result(value: Vec<BlobTuple>) -> Result<Vec<u8>> {
        let returns: Vec<BlobTupleInner> = value.iter().map(|blob_tuple| {
            Ok(BlobTupleInner {
                blobHash: data_encoding::BASE32_NOPAD.encode(blob_tuple.blob_hash),
                sourceInfo: blob_tuple.source_info.iter().map(|source_info| {
                    let subscriber = H160::try_from(source_info.subscriber)?;
                    Ok(BlobSourceInfoInner {
                        subscriber: subscriber.into(),
                        subscriptionId: source_info.subscription_id.clone(),
                        source: data_encoding::BASE32_NOPAD.encode(source_info.source),
                    })
                }).collect::<Result<Vec<_>>>()?
            })
        }).collect::<Result<Vec<_>>>()?;

        Ok(getAddedBlobsCall::abi_encode_returns(&(returns,)))
    }
}

pub mod get_pending_blobs {
    use super::*;
    use crate::blobs_facade::iblobsfacade::IBlobsFacade::{getPendingBlobsCall, BlobTuple as BlobTupleInner, BlobSourceInfo as BlobSourceInfoInner};

    pub const SELECTOR: [u8; 4] = getPendingBlobsCall::SELECTOR;

    pub fn abi_decode_input(bytes: &[u8]) -> Result<getPendingBlobsCall, ActorError> {
        getPendingBlobsCall::abi_decode(bytes, true).map_err(|err| {
            actor_error!(illegal_argument, format!("Invalid parameters {}", err))
        })
    }

    pub fn abi_encode_result(value: Vec<BlobTuple>) -> Result<Vec<u8>> {
        let returns: Vec<BlobTupleInner> = value.iter().map(|blob_tuple| {
            Ok(BlobTupleInner {
                blobHash: data_encoding::BASE32_NOPAD.encode(blob_tuple.blob_hash),
                sourceInfo: blob_tuple.source_info.iter().map(|source_info| {
                    let subscriber = H160::try_from(source_info.subscriber)?;
                    Ok(BlobSourceInfoInner {
                        subscriber: subscriber.into(),
                        subscriptionId: source_info.subscription_id.clone(),
                        source: data_encoding::BASE32_NOPAD.encode(source_info.source),
                    })
                }).collect::<Result<Vec<_>>>()?
            })
        }).collect::<Result<Vec<_>>>()?;

        Ok(getPendingBlobsCall::abi_encode_returns(&(returns,)))
    }
}

pub mod get_blob_status {
    use super::*;
    use crate::blobs_facade::iblobsfacade::IBlobsFacade::getBlobStatusCall;
    use ipc_types::EthAddress;

    pub const SELECTOR: [u8; 4] = getBlobStatusCall::SELECTOR;

    pub struct Input {
        pub subscriber: EthAddress,
        pub blob_hash: String,
        pub subscription_id: String,
    }

    pub fn abi_decode_input(bytes: &[u8]) -> Result<Input, ActorError> {
        let input = getBlobStatusCall::abi_decode(bytes, true).map_err(|err| {
            actor_error!(illegal_argument, format!("Invalid parameters {}", err))
        })?;
        let h160: H160 = input.subscriber.into();
        Ok(Input {
            subscriber: h160.into(),
            blob_hash: input.blobHash,
            subscription_id: input.subscriptionId,
        })
    }

    pub fn abi_encode_result(value: u8) -> Vec<u8> {
        // There is a BlobStatus prepared by allow, but we can not use it here :((
        // Looks like encoding of return types is neglected there.
        getBlobStatusCall::abi_encode_returns(&(value,))
    }
}

pub fn blob_added(
    subscriber: FVMAddress,
    hash: Hash,
    size: u64,
    expiry: u64,
    bytes_used: u64,
) -> Result<IBlobsFacadeEvents> {
    let subscriber: H160 = subscriber.try_into()?;
    Ok(IBlobsFacadeEvents::BlobAdded(BlobAdded {
        subscriber: subscriber.into(),
        hash: hash.0.into(),
        size: U256::from(size),
        expiry: U256::from(expiry),
        bytesUsed: U256::from(bytes_used),
    }))
}

pub fn blob_pending(
    subscriber: FVMAddress,
    hash: Hash,
    source_id: PublicKey,
) -> Result<IBlobsFacadeEvents> {
    let subscriber: H160 = subscriber.try_into()?;
    Ok(IBlobsFacadeEvents::BlobPending(BlobPending {
        subscriber: subscriber.into(),
        hash: hash.0.into(),
        sourceId: source_id.0.into(),
    }))
}

pub fn blob_finalized(
    subscriber: FVMAddress,
    hash: Hash,
    resolved: bool,
) -> Result<IBlobsFacadeEvents> {
    let subscriber: H160 = subscriber.try_into()?;
    Ok(IBlobsFacadeEvents::BlobFinalized(BlobFinalized {
        subscriber: subscriber.into(),
        hash: hash.0.into(),
        resolved,
    }))
}

pub fn blob_deleted(
    subscriber: FVMAddress,
    hash: Hash,
    size: u64,
    bytes_released: u64,
) -> Result<IBlobsFacadeEvents> {
    let subscriber: H160 = subscriber.try_into()?;
    Ok(IBlobsFacadeEvents::BlobDeleted(BlobDeleted {
        subscriber: subscriber.into(),
        hash: hash.0.into(),
        size: U256::from(size),
        bytesReleased: U256::from(bytes_released),
    }))
}