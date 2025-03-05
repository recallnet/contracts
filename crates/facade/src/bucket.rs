use crate::bucket_facade::ibucketfacade::IBucketFacade::{
    IBucketFacadeEvents, ObjectAdded, ObjectDeleted, ObjectMetadataUpdated,
};
use anyhow::Result;
use std::collections::HashMap;

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