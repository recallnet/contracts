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
use fvm_shared::econ::TokenAmount;
use fil_actors_runtime::ActorError;
use fil_actors_evm_shared::address::EthAddress;

const EAM_ACTOR_ID: ActorID = 10;

#[derive(Default, Serialize_tuple, Deserialize_tuple)]
#[serde(transparent)]
pub struct InvokeContractParams {
    #[serde(with = "strict_bytes")]
    pub input_data: Vec<u8>,
}

/// EVM call with selector (first 4 bytes) and calldata (remaining bytes)
pub struct InputData(Vec<u8>);

impl TryFrom<InvokeContractParams> for InputData {
    type Error = ActorError;

    fn try_from(value: InvokeContractParams) -> Result<Self, Self::Error> {
        if value.input_data.len() < 4 {
            return Err(ActorError::illegal_argument("input too short".to_string()));
        }
        Ok(InputData(value.input_data))
    }
}

#[derive(Serialize_tuple, Deserialize_tuple)]
#[serde(transparent)]
pub struct InvokeContractReturn {
    #[serde(with = "strict_bytes")]
    pub output_data: Vec<u8>,
}

pub trait AbiEncodeReturns<T> {
    fn returns(&self, value: T) -> Vec<u8>;
}

pub trait TryAbiEncodeReturns<T> {
    fn try_returns(&self, value: T) -> anyhow::Result<Vec<u8>, anyhow::Error>;
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

impl Default for H160 {
    fn default() -> Self {
        H160([0u8; 20])
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

impl Into<EthAddress> for H160 {
    fn into(self) -> EthAddress {
        EthAddress(self.0)
    }
}

impl From<H160> for Address {
    fn from(value: H160) -> Self {
        Address::from(value.to_fixed_bytes())
    }
}

impl From<Address> for H160 {
    fn from(value: Address) -> Self {
        H160::from_slice(&value.0.0)
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

impl From<TokenAmount> for BigUintWrapper {
    fn from(amount: TokenAmount) -> Self {
        Self(amount.atto().to_biguint().unwrap_or_default())
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