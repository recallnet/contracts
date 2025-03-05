use crate::bucket_facade::ibucketfacade::IBucketFacade::{IBucketFacadeCalls, IBucketFacadeEvents, ObjectAdded, ObjectDeleted, ObjectMetadataUpdated};
use anyhow::Result;
use std::collections::HashMap;
use alloy_sol_types::SolInterface;
use fil_actors_runtime::{actor_error, ActorError};
use crate::types::InputData;

pub fn can_handle(input_data: &InputData) -> bool {
    IBucketFacadeCalls::valid_selector(input_data.selector())
}

pub fn parse_input(input: &InputData) -> Result<IBucketFacadeCalls, ActorError> {
    IBucketFacadeCalls::abi_decode_raw(input.selector(), input.calldata(), true).map_err(|e| {
        actor_error!(illegal_argument, format!("invalid call: {}", e))
    })
}

pub type Calls = IBucketFacadeCalls;

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