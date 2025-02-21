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
}

#[cfg(feature = "config")]
mod config_facade;
#[cfg(feature = "config")]
pub mod config {
    use crate::config_facade::iconfigfacade::IConfigFacade::{
        ConfigAdminSet, ConfigSet, IConfigFacadeEvents,
    };
    use crate::types::{BigUintWrapper, H160};
    use alloy_primitives::U256;
    use anyhow::Result;
    use fvm_shared::{address::Address, bigint::BigUint};

    pub fn config_admin_set(admin: Address) -> Result<IConfigFacadeEvents> {
        let admin: H160 = admin.try_into()?;
        Ok(IConfigFacadeEvents::ConfigAdminSet(ConfigAdminSet {
            admin: admin.into(),
        }))
    }

    pub fn config_set(
        blob_capacity: u64,
        token_credit_rate: BigUint,
        blob_credit_debit_interval: u64,
        blob_min_ttl: u64,
        blob_default_ttl: u64,
        blob_delete_batch_size: u64,
        account_debit_batch_size: u64,
    ) -> Result<IConfigFacadeEvents> {
        Ok(IConfigFacadeEvents::ConfigSet(ConfigSet {
            blobCapacity: U256::from(blob_capacity),
            tokenCreditRate: BigUintWrapper(token_credit_rate).into(),
            blobCreditDebitInterval: U256::from(blob_credit_debit_interval),
            blobMinTtl: U256::from(blob_min_ttl),
            blobDefaultTtl: U256::from(blob_default_ttl),
            blobDeleteBatchSize: U256::from(blob_delete_batch_size),
            accountDebitBatchSize: U256::from(account_debit_batch_size),
        }))
    }
}

#[cfg(feature = "credit")]
mod credit_facade;
#[cfg(feature = "credit")]
pub mod credit {
    use crate::credit_facade::icreditfacade::ICreditFacade::{
        CreditApproved, CreditDebited, CreditPurchased, CreditRevoked, ICreditFacadeEvents,
    };
    use crate::types::{BigUintWrapper, H160};
    use alloy_primitives::U256;
    use anyhow::Result;
    use fvm_shared::{address::Address, bigint::BigUint};

    pub fn credit_purchased(from: Address, amount: BigUint) -> Result<ICreditFacadeEvents> {
        let from: H160 = from.try_into()?;
        Ok(ICreditFacadeEvents::CreditPurchased(CreditPurchased {
            from: from.into(),
            amount: BigUintWrapper(amount).into(),
        }))
    }

    pub fn credit_approved(
        from: Address,
        to: Address,
        credit_limit: BigUint,
        gas_fee_limit: BigUint,
        expiry: u64,
    ) -> Result<ICreditFacadeEvents> {
        let from: H160 = from.try_into()?;
        let to: H160 = to.try_into()?;
        Ok(ICreditFacadeEvents::CreditApproved(CreditApproved {
            from: from.into(),
            to: to.into(),
            creditLimit: BigUintWrapper(credit_limit).into(),
            gasFeeLimit: BigUintWrapper(gas_fee_limit).into(),
            expiry: U256::from(expiry),
        }))
    }

    pub fn credit_revoked(from: Address, to: Address) -> Result<ICreditFacadeEvents> {
        let from: H160 = from.try_into()?;
        let to: H160 = to.try_into()?;
        Ok(ICreditFacadeEvents::CreditRevoked(CreditRevoked {
            from: from.into(),
            to: to.into(),
        }))
    }

    pub fn credit_debited(
        amount: BigUint,
        num_accounts: u64,
        more_accounts: bool,
    ) -> Result<ICreditFacadeEvents> {
        Ok(ICreditFacadeEvents::CreditDebited(CreditDebited {
            amount: BigUintWrapper(amount).into(),
            numAccounts: U256::from(num_accounts),
            moreAccounts: more_accounts,
        }))
    }
}

#[cfg(feature = "gas")]
mod gas_facade;
#[cfg(feature = "gas")]
pub mod gas {
    use crate::gas_facade::igasfacade::IGasFacade::{
        GasSponsorSet, GasSponsorUnset, IGasFacadeEvents,
    };
    use crate::types::H160;
    use anyhow::Result;
    use fvm_shared::address::Address;

    pub fn gas_sponsor_set(sponsor: Address) -> Result<IGasFacadeEvents> {
        let sponsor: H160 = sponsor.try_into()?;
        Ok(IGasFacadeEvents::GasSponsorSet(GasSponsorSet {
            sponsor: sponsor.into(),
        }))
    }

    pub fn gas_sponsor_unset() -> Result<IGasFacadeEvents> {
        Ok(IGasFacadeEvents::GasSponsorUnset(GasSponsorUnset {}))
    }
}

#[cfg(feature = "machine")]
mod machine_facade;
#[cfg(feature = "machine")]
pub mod machine {
    use crate::machine_facade::imachinefacade::IMachineFacade::{
        IMachineFacadeEvents, MachineCreated, MachineInitialized,
    };
    use crate::types::H160;
    use anyhow::Result;
    use fvm_shared::address::Address;
    use std::collections::HashMap;

    pub fn machine_created(
        kind: u8,
        owner: Address,
        metadata: &HashMap<String, String>,
    ) -> Result<IMachineFacadeEvents> {
        let owner: H160 = owner.try_into()?;
        let metadata = fvm_ipld_encoding::to_vec(metadata)?;
        Ok(IMachineFacadeEvents::MachineCreated(MachineCreated {
            kind,
            owner: owner.into(),
            metadata: metadata.into(),
        }))
    }

    pub fn machine_initialized(kind: u8, machine_address: Address) -> Result<IMachineFacadeEvents> {
        let machine_address: H160 = machine_address.try_into()?;
        Ok(IMachineFacadeEvents::MachineInitialized(
            MachineInitialized {
                kind,
                machineAddress: machine_address.into(),
            },
        ))
    }
}

#[cfg(feature = "timehub")]
mod timehub_facade;

#[cfg(feature = "timehub")]
pub mod timehub {
    use crate::timehub_facade::itimehubfacade::ITimehubFacade::{
        EventPushed, ITimehubFacadeEvents,
    };
    use alloy_primitives::U256;
    use anyhow::Result;

    pub fn event_pushed(index: u64, timestamp: u64, cid: Vec<u8>) -> Result<ITimehubFacadeEvents> {
        Ok(ITimehubFacadeEvents::EventPushed(EventPushed {
            index: U256::from(index),
            timestamp: U256::from(timestamp),
            cid: cid.into(),
        }))
    }
}
