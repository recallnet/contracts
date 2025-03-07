// Copyright 2025 Recall Contributors
// SPDX-License-Identifier: Apache-2.0, MIT

use std::fmt;

use alloy_primitives::{Address, Sign, I256, U256};
use anyhow::anyhow;
use fvm_shared::{
    address::{Address as FvmAddress, Payload},
    bigint::{BigInt, BigUint, Sign as BigSign},
    ActorID,
};

pub use alloy_sol_types::SolCall;
pub use alloy_sol_types::SolInterface;

const EAM_ACTOR_ID: ActorID = 10;

/// Fixed-size uninterpreted hash type with 20 bytes (160 bits) size.
pub struct H160([u8; 20]);

impl Default for H160 {
    fn default() -> Self {
        Self([0u8; 20])
    }
}

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

    pub fn is_null(&self) -> bool {
        self.0 == [0; 20]
    }
}

impl TryFrom<&[u8]> for H160 {
    type Error = anyhow::Error;
    fn try_from(slice: &[u8]) -> Result<Self, Self::Error> {
        if slice.len() != 20 {
            anyhow!("slice length must be exactly 20 bytes");
        }
        let mut buf = [0u8; 20];
        buf.copy_from_slice(slice);
        Ok(H160(buf))
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

impl TryInto<FvmAddress> for H160 {
    type Error = anyhow::Error;
    fn try_into(self) -> Result<FvmAddress, anyhow::Error> {
        // Copied from fil_actors_evm_shared
        let bytes = self.to_fixed_bytes();
        if bytes[0] == 0xff && bytes[1..12].iter().all(|&b| b == 0x00) {
            let id = u64::from_be_bytes(bytes[12..].try_into()?);
            Ok(FvmAddress::new_id(id))
        } else {
            Ok(FvmAddress::new_delegated(EAM_ACTOR_ID, bytes.as_slice())?)
        }
    }
}

impl From<Address> for H160 {
    fn from(address: Address) -> Self {
        H160::from_slice(address.as_ref())
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

pub mod base32 {
    pub fn encode<T: AsRef<[u8]>>(data: T) -> String {
        data_encoding::BASE32_NOPAD.encode(data.as_ref()).into()
    }

    pub fn decode(data: &[u8]) -> Result<Vec<u8>, anyhow::Error> {
        data_encoding::BASE32_NOPAD.decode(data).map_err(Into::into)
    }
}

pub struct Base32(Vec<u8>);

impl Base32 {
    pub fn from_slice(slice: &[u8]) -> Self {
        Base32(slice.to_vec())
    }
    pub fn encode(&self) -> String {
        data_encoding::BASE32.encode(self.0.as_slice())
    }
    pub fn decode(data: &[u8]) -> Result<Base32, anyhow::Error> {
        let vec = data_encoding::BASE32.decode(data).map_err(anyhow::Error::msg)?;
        Ok(Base32(vec))
    }
}

impl Default for Base32 {
    fn default() -> Self {
        Base32(Vec::default())
    }
}

impl AsRef<[u8]> for Base32 {
    fn as_ref(&self) -> &[u8] {
        self.0.as_ref()
    }
}