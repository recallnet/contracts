// Copyright 2025 Recall Contributors
// SPDX-License-Identifier: Apache-2.0, MIT

#![allow(dead_code)]

pub use alloy_primitives as primitives;

pub mod types;

#[cfg(feature = "blob-reader")]
mod blobreader_facade;
#[cfg(feature = "blob-reader")]
pub mod blob_reader {
    pub type Event = crate::blobreader_facade::iblobreaderfacade::IBlobReaderFacade::IBlobReaderFacadeEvents;
    pub type ReadRequestClosed = crate::blobreader_facade::iblobreaderfacade::IBlobReaderFacade::ReadRequestClosed;
    pub type ReadRequestOpened = crate::blobreader_facade::iblobreaderfacade::IBlobReaderFacade::ReadRequestOpened;
    pub type ReadRequestPending = crate::blobreader_facade::iblobreaderfacade::IBlobReaderFacade::ReadRequestPending;
}

#[cfg(feature = "blobs")]
mod blobs_facade;
#[cfg(feature = "blobs")]
pub mod blobs {
    pub type Event = crate::blobs_facade::iblobsfacade::IBlobsFacade::IBlobsFacadeEvents;
    pub type BlobAdded = crate::blobs_facade::iblobsfacade::IBlobsFacade::BlobAdded;
    pub type BlobDeleted = crate::blobs_facade::iblobsfacade::IBlobsFacade::BlobDeleted;
    pub type BlobFinalized = crate::blobs_facade::iblobsfacade::IBlobsFacade::BlobFinalized;
    pub type BlobPending = crate::blobs_facade::iblobsfacade::IBlobsFacade::BlobPending;
}

#[cfg(feature = "bucket")]
mod bucket_facade;
#[cfg(feature = "bucket")]
pub mod bucket {
    pub type Event = crate::bucket_facade::ibucketfacade::IBucketFacade::IBucketFacadeEvents;
    pub type ObjectAdded = crate::bucket_facade::ibucketfacade::IBucketFacade::ObjectAdded;
    pub type ObjectDeleted = crate::bucket_facade::ibucketfacade::IBucketFacade::ObjectDeleted;
    pub type ObjectMetadataUpdated = crate::bucket_facade::ibucketfacade::IBucketFacade::ObjectMetadataUpdated;
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
