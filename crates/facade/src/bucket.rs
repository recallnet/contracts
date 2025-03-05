use crate::bucket_facade::ibucketfacade::IBucketFacade::{IBucketFacadeCalls, IBucketFacadeEvents, ObjectAdded, ObjectDeleted, ObjectMetadataUpdated};
use anyhow::Result;
use std::collections::HashMap;
use alloy_sol_types::SolInterface;
use fvm_shared::bigint::Zero;
use fvm_shared::clock::ChainEpoch;
use fendermint_actor_bucket_shared::{AddParams, DeleteParams, Object};
use fil_actors_runtime::{actor_error, ActorError};
use crate::bucket_facade::ibucketfacade::IBucketFacade;
use crate::types::{try_into_hash, try_into_public_key, InputData, AbiEncodeReturns, TryAbiEncodeReturns, IntoEthAddress};
use fvm_shared::address::{Address as FVMAddress, Address};
use crate::impl_empty_returns;
use alloy_sol_types::SolCall;
use fendermint_actor_blobs_shared::state::Hash;

pub fn can_handle(input_data: &InputData) -> bool {
    IBucketFacadeCalls::valid_selector(input_data.selector())
}

pub fn parse_input(input: &InputData) -> Result<IBucketFacadeCalls, ActorError> {
    IBucketFacadeCalls::abi_decode_raw(input.selector(), input.calldata(), true).map_err(|e| {
        actor_error!(illegal_argument, format!("invalid call: {}", e))
    })
}

pub type Calls = IBucketFacadeCalls;

impl_empty_returns!(
    IBucketFacade::addObject_0Call,
    IBucketFacade::addObject_1Call,
    IBucketFacade::deleteObjectCall
);

impl TryInto<AddParams> for IBucketFacade::addObject_0Call {
    type Error = ActorError;
    fn try_into(self) -> Result<AddParams, Self::Error> {
        let source = try_into_public_key(self.addObjectParams.source)?;
        let key = self.addObjectParams.key.into_bytes();
        let hash = try_into_hash(self.addObjectParams.blobHash)?;
        let recovery_hash = try_into_hash(self.addObjectParams.recoveryHash)?;
        let size = self.addObjectParams.size;
        let ttl = if self.addObjectParams.ttl.is_zero() { None } else { Some(self.addObjectParams.ttl as ChainEpoch) };
        let metadata: HashMap<String, String> = HashMap::from_iter(self.addObjectParams.metadata.iter().map(|kv| {
            let kv = kv.clone();
            (kv.key, kv.value)
        }));
        let overwrite = self.addObjectParams.overwrite;
        let from: FVMAddress = self.addObjectParams.from.into_eth_address().into();
        Ok(AddParams {
            source,
            key,
            hash,
            recovery_hash,
            size,
            ttl,
            metadata,
            overwrite,
            from,
        })
    }
}

impl TryInto<AddParams> for IBucketFacade::addObject_1Call {
    type Error = ActorError;
    fn try_into(self) -> Result<AddParams, Self::Error> {
        let source = try_into_public_key(self.source)?;
        let key = self.key.into_bytes();
        let hash = try_into_hash(self.blobHash)?;
        let recovery_hash = try_into_hash(self.recoveryHash)?;
        let size = self.size;
        let from: FVMAddress = self.from.into_eth_address().into();
        Ok(AddParams {
            source,
            key,
            hash,
            recovery_hash,
            size,
            ttl: None,
            metadata: HashMap::default(),
            overwrite: false,
            from,
        })
    }
}

impl TryInto<DeleteParams> for IBucketFacade::deleteObjectCall {
    type Error = ActorError;
    fn try_into(self) -> Result<DeleteParams, Self::Error> {
        let key = self.key.into_bytes();
        let from: Address = self.from.into_eth_address().into();
        Ok(DeleteParams {
            key, from,
        })
    }
}

impl From<Object> for IBucketFacade::ObjectValue {
    fn from(object: Object) -> Self {
        let metadata = object.metadata.into_iter().map(|(key, value)| {
            IBucketFacade::KeyValue {
                key,
                value,
            }
        }).collect::<Vec<_>>();
        IBucketFacade::ObjectValue {
            blobHash: object.hash.into(),
            recoveryHash: object.recovery_hash.into(),
            size: object.size,
            expiry: object.expiry as u64,
            metadata,
        }
    }
}

impl Default for IBucketFacade::ObjectValue {
    fn default() -> Self {
        IBucketFacade::ObjectValue {
            blobHash: Hash::default().into(),
            recoveryHash: Hash::default().into(),
            size: u64::default(),
            expiry: u64::default(),
            metadata: Vec::default(),
        }
    }
}

impl AbiEncodeReturns<Option<Object>> for IBucketFacade::getObjectCall {
    fn returns(&self, value: Option<Object>) -> Vec<u8> {
        let object_value = if let Some(value) = value {
            IBucketFacade::ObjectValue::from(value)
        } else {
            IBucketFacade::ObjectValue::default()
        };
        Self::abi_encode_returns(&(object_value,))
    }
}

pub fn object_added(
    key: Vec<u8>,
    blob_hash: &[u8; 32],
    metadata: &HashMap<String, String>,
) -> Result<IBucketFacadeEvents> {
    let metadata = fvm_ipld_encoding::to_vec(metadata)?;
    Ok(IBucketFacadeEvents::ObjectAdded(ObjectAdded {
        key: key.into(),
        blobHash: blob_hash.into(),
        metadata: metadata.into(),
    }))
}

pub fn object_metadata_updated(
    key: Vec<u8>,
    metadata: &HashMap<String, String>,
) -> Result<IBucketFacadeEvents> {
    let metadata = fvm_ipld_encoding::to_vec(metadata)?;
    Ok(IBucketFacadeEvents::ObjectMetadataUpdated(
        ObjectMetadataUpdated {
            key: key.into(),
            metadata: metadata.into(),
        },
    ))
}

pub fn object_deleted(key: Vec<u8>, blob_hash: &[u8; 32]) -> Result<IBucketFacadeEvents> {
    Ok(IBucketFacadeEvents::ObjectDeleted(ObjectDeleted {
        key: key.into(),
        blobHash: blob_hash.into(),
    }))
}