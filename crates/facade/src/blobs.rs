use std::str::FromStr;
use crate::blobs_facade::iblobsfacade::IBlobsFacade::{BlobAdded, BlobDeleted, BlobFinalized, BlobPending, IBlobsFacadeCalls, IBlobsFacadeEvents};
use crate::types::{AbiEncodeReturns, TryAbiEncodeReturns, H160};
use alloy_primitives::U256;
use anyhow::Result;
use fvm_shared::address::{Address as FVMAddress};
use alloy_sol_types::{SolInterface};
use alloy_sol_types::private::Address;
use fil_actors_runtime::{actor_error, ActorError};
use fendermint_actor_blobs_shared::state::{Blob, BlobStatus, Hash, PublicKey, Subscription};
use crate::blobs_facade::iblobsfacade::IBlobsFacade;

pub use alloy_sol_types::SolCall;
use fendermint_actor_blobs_shared::params::{BlobRequest, GetStatsReturn};
use ipc_types::EthAddress;
use crate::types::BigUintWrapper;

pub fn parse_input(input: &[u8]) -> Result<IBlobsFacadeCalls, ActorError> {
    if input.len() < 4 {
        return Err(actor_error!(illegal_argument, "Input too short"));
    }

    // Get the selector (first 4 bytes)
    let mut selector = [0u8; 4];
    selector.copy_from_slice(&input[0..4]);

    // Decode the rest of the input data
    let data = &input[4..];
    IBlobsFacadeCalls::abi_decode_raw(selector, data, true).map_err(|err| {
        actor_error!(illegal_argument, format!("Invalid parameters {}", err))
    })
}

pub type Calls = IBlobsFacadeCalls;

impl AbiEncodeReturns<u64> for IBlobsFacade::getPendingBlobsCountCall {
    fn returns(&self, value: &u64) -> Vec<u8> {
        Self::abi_encode_returns(&(value,))
    }
}

impl AbiEncodeReturns<u64> for IBlobsFacade::getPendingBytesCountCall {
    fn returns(&self, value: &u64) -> Vec<u8> {
        Self::abi_encode_returns(&(value,))
    }
}

impl AbiEncodeReturns<Option<u64>> for IBlobsFacade::getStorageUsageCall {
    fn returns(&self, value: &Option<u64>) -> Vec<u8> {
        let value = value.unwrap_or(u64::default()); // Value or zero, as per Solidity
        Self::abi_encode_returns(&(U256::from(value),))
    }
}

impl AbiEncodeReturns<GetStatsReturn> for IBlobsFacade::getStorageStatsCall {
    fn returns(&self, stats: &GetStatsReturn) -> Vec<u8> {
        let storage_stats = IBlobsFacade::StorageStats {
            capacityFree: stats.capacity_free,
            capacityUsed: stats.capacity_used,
            numBlobs: stats.num_blobs,
            numResolving: stats.num_resolving,
            numAccounts: stats.num_accounts,
            bytesResolving: stats.bytes_resolving,
            numAdded: stats.num_added,
            bytesAdded: stats.bytes_added,
        };
        Self::abi_encode_returns(&(storage_stats,))
    }
}

fn blob_requests_to_tuple(blob_requests: &Vec<BlobRequest>) -> Result<Vec<IBlobsFacade::BlobTuple>, anyhow::Error> {
    blob_requests.iter().map(|blob_request| {
        let source_info: Result<Vec<IBlobsFacade::BlobSourceInfo>> = blob_request.1.iter().map(|item| {
            let address = item.0;
            let public_key = item.2;
            let subscription_id = item.1.clone();

            Ok(IBlobsFacade::BlobSourceInfo {
                subscriber: H160::try_from(address)?.into(),
                subscriptionId: subscription_id.into(),
                source: public_key.into()
            })
        }).collect::<Result<Vec<_>>>();

        let blob_hash = blob_request.0;
        Ok::<IBlobsFacade::BlobTuple, anyhow::Error>(IBlobsFacade::BlobTuple {
            blobHash: blob_hash.into(),
            sourceInfo: source_info?
        })
    }).collect::<Result<Vec<_>>>()
}

impl TryAbiEncodeReturns<Vec<BlobRequest>> for IBlobsFacade::getAddedBlobsCall {
    fn try_returns(&self, blob_requests: &Vec<BlobRequest>) -> Result<Vec<u8>, anyhow::Error> {
        let blob_tuples = blob_requests_to_tuple(blob_requests)?;
        Ok(Self::abi_encode_returns(&(blob_tuples,)))
    }
}

impl TryAbiEncodeReturns<Vec<BlobRequest>> for IBlobsFacade::getPendingBlobsCall {
    fn try_returns(&self, blob_requests: &Vec<BlobRequest>) -> Result<Vec<u8>, anyhow::Error> {
        let blob_tuples = blob_requests_to_tuple(blob_requests)?;
        Ok(Self::abi_encode_returns(&(blob_tuples,)))
    }
}

impl AbiEncodeReturns<BlobStatus> for IBlobsFacade::getBlobStatusCall {
    fn returns(&self, blob_status: &BlobStatus) -> Vec<u8> {
        let value = blob_status_as_solidity_enum(blob_status);
        Self::abi_encode_returns(&(value,))
    }
}

fn blob_status_as_solidity_enum(blob_status: &BlobStatus) -> u8 {
    match blob_status {
        BlobStatus::Added => 0,
        BlobStatus::Pending => 1,
        BlobStatus::Resolved => 2,
        BlobStatus::Failed => 3
    }
}

impl AbiEncodeReturns<Option<BlobStatus>> for IBlobsFacade::getBlobStatusCall {
    fn returns(&self, blob_status: &Option<BlobStatus>) -> Vec<u8> {
        // Use BlobStatus::Failed if None got passed
        let blob_status = blob_status.as_ref().unwrap_or(&BlobStatus::Failed);
        self.returns(blob_status)
    }
}

impl AbiEncodeReturns<GetStatsReturn> for IBlobsFacade::getSubnetStatsCall {
    fn returns(&self, stats: &GetStatsReturn) -> Vec<u8> {
        let subnet_stats = IBlobsFacade::SubnetStats {
            balance: BigUintWrapper::from(stats.balance.clone()).into(),
            capacityFree: stats.capacity_free,
            capacityUsed: stats.capacity_used,
            creditSold: BigUintWrapper::from(stats.credit_sold.clone()).into(),
            creditCommitted: BigUintWrapper::from(stats.credit_committed.clone()).into(),
            creditDebited: BigUintWrapper::from(stats.credit_debited.clone()).into(),
            tokenCreditRate: BigUintWrapper(stats.token_credit_rate.rate().clone()).into(),
            numAccounts: stats.num_accounts,
            numBlobs: stats.num_blobs,
            numAdded: stats.num_added,
            bytesAdded: stats.bytes_added,
            numResolving: stats.num_resolving,
            bytesResolving: stats.bytes_resolving,
        };
        Self::abi_encode_returns(&(subnet_stats,))
    }
}

impl TryAbiEncodeReturns<Option<Blob>> for IBlobsFacade::getBlobCall {
    fn try_returns(&self, value: &Option<Blob>) -> Result<Vec<u8>, anyhow::Error> {
        let facade_blob = if let Some(blob) = value {
            let subscribers = blob.subscribers.iter().map(|(fvm_address, subscription_group)| {
                let subscription_group = subscription_group.subscriptions.iter().map(|(subscription_id, subscription)| {
                    let delegate = subscription.delegate.map(|fvm_address| H160::try_from(fvm_address)).transpose()?.unwrap_or_default();
                    Ok(IBlobsFacade::SubscriptionGroup {
                       subscriptionId: subscription_id.into(),
                       subscription: IBlobsFacade::Subscription {
                           added: subscription.added as u64,
                           expiry: subscription.expiry as u64,
                           source: subscription.source.into(),
                           delegate: delegate.into(),
                           failed: subscription.failed,
                       },
                   })
                }).collect::<Result<Vec<_>, anyhow::Error>>()?;
                let fvm_address = FVMAddress::from_str(fvm_address)?;
                let h160_address: H160 = fvm_address.try_into()?;
                Ok(IBlobsFacade::Subscriber {
                    subscriber: h160_address.into(),
                    subscriptionGroup: subscription_group,
                })
            }).collect::<Result<Vec<_>>>()?;
            IBlobsFacade::Blob {
                size: blob.size,
                metadataHash: blob.metadata_hash.into(),
                status: blob_status_as_solidity_enum(&blob.status),
                subscribers,
            }
        } else {
            IBlobsFacade::Blob {
                size: 0,
                metadataHash: Hash::default().into(),
                status: blob_status_as_solidity_enum(&BlobStatus::Failed),
                subscribers: vec![]
            }
        };
        Ok(Self::abi_encode_returns(&(facade_blob,)))
    }
}

impl AbiEncodeReturns<()> for IBlobsFacade::addBlobCall {
    fn returns(&self, _: &()) -> Vec<u8> {
        Self::abi_encode_returns(&())
    }
}

pub trait IntoEthAddress {
    fn into_eth_address(self) -> EthAddress;
}

impl IntoEthAddress for Address {
    fn into_eth_address(self) -> EthAddress {
        EthAddress(self.0.0)
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