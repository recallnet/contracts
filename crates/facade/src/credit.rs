use crate::credit_facade::icreditfacade::ICreditFacade::{CreditApproved, CreditDebited, CreditPurchased, CreditRevoked, ICreditFacadeCalls, ICreditFacadeEvents};
use crate::types::{BigUintWrapper, InputData, H160};
use alloy_primitives::U256;
use alloy_sol_types::SolInterface;
use anyhow::Result;
use fvm_shared::{address::Address, bigint::BigUint};
use fil_actors_runtime::{actor_error, ActorError};

pub fn can_handle(input_data: InputData) -> bool {
    ICreditFacadeCalls::valid_selector(input_data.selector())
}

pub fn parse_input(input: &InputData) -> Result<ICreditFacadeCalls, ActorError> {
    ICreditFacadeCalls::abi_decode_raw(input.selector(), input.calldata(), true).map_err(|e| {
        actor_error!(illegal_argument, format!("invalid call: {}", e))
    })
}

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