// Copyright 2025 Recall Contributors
// SPDX-License-Identifier: Apache-2.0, MIT

#![allow(dead_code)]

pub use alloy_primitives as primitives;

pub mod types;

#[cfg(feature = "blob-reader")]
mod blobreader_facade;
#[cfg(feature = "blob-reader")]
pub mod blob_reader {
    use crate::blobreader_facade::iblobreaderfacade::IBlobReaderFacade::{
        IBlobReaderFacadeEvents, ReadRequestClosed, ReadRequestOpened, ReadRequestPending,
    };
    use crate::types::H160;
    use alloy_primitives::U256;
    use anyhow::Result;
    use fvm_shared::address::Address;
    use fvm_shared::MethodNum;

    pub fn read_request_opened(
        id: &[u8; 32],
        blob_hash: &[u8; 32],
        read_offset: u64,
        read_length: u64,
        callback: Address,
        method_num: MethodNum,
    ) -> Result<IBlobReaderFacadeEvents> {
        let callback: H160 = callback.try_into()?;
        Ok(IBlobReaderFacadeEvents::ReadRequestOpened(
            ReadRequestOpened {
                id: id.into(),
                blobHash: blob_hash.into(),
                readOffset: U256::from(read_offset),
                readLength: U256::from(read_length),
                callbackAddress: callback.into(),
                callbackMethod: U256::from(method_num),
            },
        ))
    }

    pub fn read_request_pending(id: &[u8; 32]) -> Result<IBlobReaderFacadeEvents> {
        Ok(IBlobReaderFacadeEvents::ReadRequestPending(
            ReadRequestPending { id: id.into() },
        ))
    }

    pub fn read_request_closed(id: &[u8; 32]) -> Result<IBlobReaderFacadeEvents> {
        Ok(IBlobReaderFacadeEvents::ReadRequestClosed(
            ReadRequestClosed { id: id.into() },
        ))
    }
}

#[cfg(feature = "blobs")]
mod blobs_facade;
#[cfg(feature = "blobs")]
pub mod blobs {
    use crate::blobs_facade::iblobsfacade::IBlobsFacade::{
        BlobAdded, BlobDeleted, BlobFinalized, BlobPending, IBlobsFacadeEvents,
    };
    use crate::types::H160;
    use alloy_primitives::U256;
    use anyhow::Result;
    use fvm_shared::address::Address;

    pub fn blob_added(
        subscriber: Address,
        hash: &[u8; 32],
        size: u64,
        expiry: u64,
        bytes_used: u64,
    ) -> Result<IBlobsFacadeEvents> {
        let subscriber: H160 = subscriber.try_into()?;
        Ok(IBlobsFacadeEvents::BlobAdded(BlobAdded {
            subscriber: subscriber.into(),
            hash: hash.into(),
            size: U256::from(size),
            expiry: U256::from(expiry),
            bytesUsed: U256::from(bytes_used),
        }))
    }

    pub fn blob_pending(
        subscriber: Address,
        hash: &[u8; 32],
        source_id: &[u8; 32],
    ) -> Result<IBlobsFacadeEvents> {
        let subscriber: H160 = subscriber.try_into()?;
        Ok(IBlobsFacadeEvents::BlobPending(BlobPending {
            subscriber: subscriber.into(),
            hash: hash.into(),
            sourceId: source_id.into(),
        }))
    }

    pub fn blob_finalized(
        subscriber: Address,
        hash: &[u8; 32],
        resolved: bool,
    ) -> Result<IBlobsFacadeEvents> {
        let subscriber: H160 = subscriber.try_into()?;
        Ok(IBlobsFacadeEvents::BlobFinalized(BlobFinalized {
            subscriber: subscriber.into(),
            hash: hash.into(),
            resolved,
        }))
    }

    pub fn blob_deleted(
        subscriber: Address,
        hash: &[u8; 32],
        size: u64,
        bytes_released: u64,
    ) -> Result<IBlobsFacadeEvents> {
        let subscriber: H160 = subscriber.try_into()?;
        Ok(IBlobsFacadeEvents::BlobDeleted(BlobDeleted {
            subscriber: subscriber.into(),
            hash: hash.into(),
            size: U256::from(size),
            bytesReleased: U256::from(bytes_released),
        }))
    }
}

#[cfg(feature = "bucket")]
mod bucket_facade;
#[cfg(feature = "bucket")]
pub mod bucket {
    pub type Event = crate::bucket_facade::ibucketfacade::IBucketFacade::IBucketFacadeEvents;
    pub type ObjectAdded = crate::bucket_facade::ibucketfacade::IBucketFacade::ObjectAdded;
    pub type ObjectDeleted = crate::bucket_facade::ibucketfacade::IBucketFacade::ObjectDeleted;
    pub type ObjectMetadataUpdated = crate::bucket_facade::ibucketfacade::IBucketFacade::ObjectMetadataUpdated;

    use crate::bucket_facade::ibucketfacade::IBucketFacade::{
        IBucketFacadeEvents,
    };
    use anyhow::Result;
    use std::collections::HashMap;

    pub fn object_deleted(key: Vec<u8>, blob_hash: &[u8; 32]) -> Result<IBucketFacadeEvents> {
        Ok(IBucketFacadeEvents::ObjectDeleted(ObjectDeleted {
            key: key.into(),
            blobHash: blob_hash.into(),
        }))
    }
}

#[cfg(feature = "config")]
mod config_facade;
#[cfg(feature = "config")]
pub mod config {
    pub type Event = crate::config_facade::iconfigfacade::IConfigFacade::IConfigFacadeEvents;
    pub type ConfigAdminSet = crate::config_facade::iconfigfacade::IConfigFacade::ConfigAdminSet;
    pub type ConfigSet = crate::config_facade::iconfigfacade::IConfigFacade::ConfigSet;
}

#[cfg(feature = "credit")]
mod credit_facade;
#[cfg(feature = "credit")]
pub mod credit {
    pub type Event = crate::credit_facade::icreditfacade::ICreditFacade::ICreditFacadeEvents;
    pub type CreditApproved = crate::credit_facade::icreditfacade::ICreditFacade::CreditApproved;
    pub type CreditDebited = crate::credit_facade::icreditfacade::ICreditFacade::CreditDebited;
    pub type CreditPurchased = crate::credit_facade::icreditfacade::ICreditFacade::CreditPurchased;
    pub type CreditRevoked = crate::credit_facade::icreditfacade::ICreditFacade::CreditRevoked;
}

#[cfg(feature = "gas")]
mod gas_facade;
#[cfg(feature = "gas")]
pub mod gas {
    pub type Event = crate::gas_facade::igasfacade::IGasFacade::IGasFacadeEvents;
    pub type GasSponsorSet = crate::gas_facade::igasfacade::IGasFacade::GasSponsorSet;
    pub type GasSponsorUnset = crate::gas_facade::igasfacade::IGasFacade::GasSponsorUnset;
}

#[cfg(feature = "machine")]
mod machine_facade;

#[cfg(feature = "machine")]
pub mod machine {
    pub type Event = crate::machine_facade::imachinefacade::IMachineFacade::IMachineFacadeEvents;
    pub type MachineCreated = crate::machine_facade::imachinefacade::IMachineFacade::MachineCreated;
    pub type MachineInitialized = crate::machine_facade::imachinefacade::IMachineFacade::MachineInitialized;
}

#[cfg(feature = "timehub")]
mod timehub_facade;

#[cfg(feature = "timehub")]
pub mod timehub {
    pub type Event = crate::timehub_facade::itimehubfacade::ITimehubFacade::ITimehubFacadeEvents;
    pub type EventPushed = crate::timehub_facade::itimehubfacade::ITimehubFacade::EventPushed;
}
