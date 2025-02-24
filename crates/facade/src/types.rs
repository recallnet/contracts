// Copyright 2025 Recall Contributors
// SPDX-License-Identifier: Apache-2.0, MIT

use std::fmt;

use alloy_primitives::{Address, Sign, I256, U256};
use anyhow::anyhow;
use fvm_ipld_encoding::{strict_bytes, tuple::*};
use fvm_shared::{
    address::{Address as FvmAddress, Payload},
    bigint::{BigInt, BigUint, Sign as BigSign},
    ActorID,
};
use ipc_types::ActorError;

const EAM_ACTOR_ID: ActorID = 10;

#[derive(Default, Serialize_tuple, Deserialize_tuple)]
#[serde(transparent)]
pub struct InvokeContractParams {
    #[serde(with = "strict_bytes")]
    pub input_data: Vec<u8>,
}

impl InvokeContractParams {
    pub fn selector(&self) -> Result<[u8; 4], ActorError> {
        self.input_data
            .get(0..4)
            .and_then(|s| s.try_into().ok())
            .ok_or(ActorError::illegal_argument(format!("No selector extracted")))
    }
}

#[derive(Serialize_tuple, Deserialize_tuple)]
#[serde(transparent)]
pub struct InvokeContractReturn {
    #[serde(with = "strict_bytes")]
    pub output_data: Vec<u8>,
}

/// Fixed-size uninterpreted hash type with 20 bytes (160 bits) size.
pub struct H160([u8; 20]);

impl H160 {
    pub fn from_slice(slice: &[u8]) -> Self {
        if slice.len() != 20 {
            panic!("slice length must be exactly 20 bytes");
        }
        let mut buf = [0u8; 20];
        buf.copy_from_slice(slice);
        H160(buf)
    }

    pub fn from_actor_id(id: ActorID) -> Self {
        let mut buf = [0u8; 20];
        buf[0] = 0xff;
        buf[12..].copy_from_slice(&id.to_be_bytes());
        H160(buf)
    }

    pub fn to_fixed_bytes(&self) -> [u8; 20] {
        self.0
    }
}

impl fmt::Debug for H160 {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "H160({:?})", &self.0)
    }
}

impl TryFrom<FvmAddress> for H160 {
    type Error = anyhow::Error;

    fn try_from(value: FvmAddress) -> Result<Self, Self::Error> {
        match value.payload() {
            Payload::Delegated(d)
                if d.namespace() == EAM_ACTOR_ID && d.subaddress().len() == 20 =>
            {
                Ok(H160::from_slice(d.subaddress()))
            }
            Payload::ID(id) => Ok(H160::from_actor_id(*id)),
            _ => Err(anyhow!("not an evm address: {}", value)),
        }
    }
}

impl From<H160> for Address {
    fn from(value: H160) -> Self {
        Address::from(value.to_fixed_bytes())
    }
}

pub struct BigUintWrapper(pub BigUint);

impl From<BigUintWrapper> for U256 {
    fn from(value: BigUintWrapper) -> Self {
        let digits = value.0.to_u64_digits();
        match U256::overflowing_from_limbs_slice(&digits) {
            (n, false) => n,
            (_, true) => U256::MAX,
        }
    }
}

pub struct BigIntWrapper(pub BigInt);

impl From<BigIntWrapper> for I256 {
    fn from(value: BigIntWrapper) -> Self {
        let (sign, digits) = value.0.to_u64_digits();
        let sign = match sign {
            BigSign::Minus => Sign::Negative,
            BigSign::NoSign | BigSign::Plus => Sign::Positive,
        };
        let uint = U256::saturating_from_limbs_slice(&digits);
        match I256::overflowing_from_sign_and_abs(sign, uint) {
            (n, false) => n,
            (_, true) => I256::MAX,
        }
    }
}
