use std::collections::HashMap;
use std::str::FromStr;
use crate::credit_facade::icreditfacade::ICreditFacade::{CreditApproved, CreditDebited, CreditPurchased, CreditRevoked, ICreditFacadeCalls, ICreditFacadeEvents};
use crate::types::{BigUintWrapper, InputData, TryAbiEncodeReturns, H160};
use alloy_primitives::{Address, U256};
use alloy_sol_types::SolInterface;
use anyhow::{Error, Result};
use fvm_shared::bigint::BigUint;
use fil_actors_runtime::{actor_error, ActorError};
use crate::credit_facade::icreditfacade::ICreditFacade;
use crate::impl_empty_returns;
use crate::types::AbiEncodeReturns;
use alloy_sol_types::SolCall;
use fendermint_actor_blobs_shared::state::{Account, CreditApproval};
use fvm_shared::address::{Address as FVMAddress};
use fendermint_actor_blobs_shared::params::GetStatsReturn;

pub fn can_handle(input_data: &InputData) -> bool {
    ICreditFacadeCalls::valid_selector(input_data.selector())
}

pub fn parse_input(input: &InputData) -> Result<ICreditFacadeCalls, ActorError> {
    ICreditFacadeCalls::abi_decode_raw(input.selector(), input.calldata(), true).map_err(|e| {
        actor_error!(illegal_argument, format!("invalid call: {}", e))
    })
}

fn convert_approvals(approvals: HashMap<String, CreditApproval>) -> Result<Vec<ICreditFacade::Approval>, anyhow::Error> {
    approvals.iter().map(|(address_string, credit_approval)| {
        let address: H160 = FVMAddress::from_str(address_string)?.try_into()?;
        let address: Address = address.try_into()?;
        let approval = ICreditFacade::Approval {
            addr: address,
            approval: ICreditFacade::CreditApproval::from(credit_approval.clone()),
        };
        Ok(approval)
    }).collect::<Result<Vec<_>, anyhow::Error>>()
}

impl From<CreditApproval> for ICreditFacade::CreditApproval {
    fn from(credit_approval: CreditApproval) -> Self {
        Self {
            creditLimit: credit_approval.credit_limit.map(|credit_limit| BigUintWrapper::from(credit_limit)).unwrap_or_default().into(),
            gasFeeLimit: credit_approval.gas_fee_limit.map(|gas_fee_limit| BigUintWrapper::from(gas_fee_limit)).unwrap_or_default().into(),
            expiry: credit_approval.expiry.map(|expiry| expiry as u64).unwrap_or_default(),
            creditUsed: BigUintWrapper::from(credit_approval.credit_used).into(),
            gasFeeUsed: BigUintWrapper::from(credit_approval.gas_fee_used).into(),
        }
    }
}

impl Default for ICreditFacade::CreditApproval {
    fn default() -> Self {
        Self {
            creditLimit: U256::default(),
            gasFeeLimit: U256::default(),
            expiry: u64::default(),
            creditUsed: U256::default(),
            gasFeeUsed: U256::default(),
        }
    }
}

impl TryAbiEncodeReturns<Option<Account>> for ICreditFacade::getAccountCall {
    fn try_returns(&self, value: Option<Account>) -> Result<Vec<u8>, anyhow::Error> {
        let account_result = if let Some(account) = value {
            let credit_sponsor: Address = account.credit_sponsor.map(|address| {
                H160::try_from(address)
            }).transpose()?.map(|h160| h160.into()).unwrap_or_default();
            let approvals_from = convert_approvals(account.approvals_from)?;
            let approvals_to = convert_approvals(account.approvals_to)?;
            ICreditFacade::Account {
                capacityUsed: account.capacity_used,
                creditFree: BigUintWrapper::from(account.credit_free).into(),
                creditCommitted: BigUintWrapper::from(account.credit_committed).into(),
                creditSponsor: credit_sponsor,
                lastDebitEpoch: account.last_debit_epoch as u64,
                approvalsFrom: approvals_from,
                approvalsTo: approvals_to,
                maxTtl: account.max_ttl as u64,
                gasAllowance: BigUintWrapper::from(account.gas_allowance).into(),
            }
        } else {
            ICreditFacade::Account {
                capacityUsed: u64::default(),
                creditFree: U256::default(),
                creditCommitted: U256::default(),
                creditSponsor: Address::default(),
                lastDebitEpoch: u64::default(),
                approvalsTo: Vec::default(),
                approvalsFrom: Vec::default(),
                maxTtl: u64::default(),
                gasAllowance: U256::default(),
            }
        };
        Ok(Self::abi_encode_returns(&(account_result,)))
    }
}

impl TryAbiEncodeReturns<GetStatsReturn> for ICreditFacade::getCreditStatsCall {
    fn try_returns(&self, stats: GetStatsReturn) -> Result<Vec<u8>, anyhow::Error> {
        let credit_stats = ICreditFacade::CreditStats {
            balance: BigUintWrapper::try_from(stats.balance)?.into(),
            creditSold: BigUintWrapper::try_from(stats.credit_sold)?.into(),
            creditCommitted: BigUintWrapper::try_from(stats.credit_committed)?.into(),
            creditDebited: BigUintWrapper::try_from(stats.credit_debited)?.into(),
            tokenCreditRate: BigUintWrapper(stats.token_credit_rate.rate().clone()).into(),
            numAccounts: stats.num_accounts
        };
        Ok(Self::abi_encode_returns(&(credit_stats,)))
    }
}

impl TryAbiEncodeReturns<Option<CreditApproval>> for ICreditFacade::getCreditApprovalCall {
    fn try_returns(&self, value: Option<CreditApproval>) -> Result<Vec<u8>, Error> {
        let approval_result = if let Some(credit_approval) = value {
            ICreditFacade::CreditApproval::from(credit_approval.clone())
        } else {
            ICreditFacade::CreditApproval::default()
        };
        Ok(Self::abi_encode_returns(&(approval_result,)))
    }
}

impl TryAbiEncodeReturns<Option<Account>> for ICreditFacade::getCreditBalanceCall {
    fn try_returns(&self, value: Option<Account>) -> Result<Vec<u8>, Error> {
        let balance = if let Some(account) = value {
            ICreditFacade::Balance {
                creditFree: BigUintWrapper::try_from(account.credit_free)?.into(),
                creditCommitted: BigUintWrapper::try_from(account.credit_committed)?.into(),
                creditSponsor: account.credit_sponsor.map(|address| {
                    H160::try_from(address)
                }).transpose()?.map(|h160| h160.into()).unwrap_or_default(), // FIXME SU DRY
                lastDebitEpoch: account.last_debit_epoch as u64,
                approvalsTo: convert_approvals(account.approvals_to)?,
                approvalsFrom: convert_approvals(account.approvals_from)?,
                gasAllowance: BigUintWrapper::try_from(account.gas_allowance)?.into(),
            }
        } else {
            ICreditFacade::Balance {
                creditFree: U256::default(),
                creditCommitted: U256::default(),
                creditSponsor: Address::default(),
                lastDebitEpoch: u64::default(),
                approvalsTo: Vec::default(),
                approvalsFrom: Vec::default(),
                gasAllowance: U256::default(),
            }
        };
        Ok(Self::abi_encode_returns(&(balance,)))
    }
}

pub type Calls = ICreditFacadeCalls;

impl_empty_returns!(
    ICreditFacade::setAccountSponsorCall
);

pub fn credit_purchased(from: FVMAddress, amount: BigUint) -> Result<ICreditFacadeEvents> {
    let from: H160 = from.try_into()?;
    Ok(ICreditFacadeEvents::CreditPurchased(CreditPurchased {
        from: from.into(),
        amount: BigUintWrapper(amount).into(),
    }))
}

pub fn credit_approved(
    from: FVMAddress,
    to: FVMAddress,
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

pub fn credit_revoked(from: FVMAddress, to: FVMAddress) -> Result<ICreditFacadeEvents> {
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