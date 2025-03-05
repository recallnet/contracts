use std::collections::{HashMap, HashSet};
use std::str::FromStr;
use crate::credit_facade::icreditfacade::ICreditFacade::{CreditApproved, CreditDebited, CreditPurchased, CreditRevoked, ICreditFacadeCalls, ICreditFacadeEvents};
use crate::types::{AbiEncodeError, BigUintWrapper, InputData, TryAbiEncodeReturns, H160, IntoEthAddress};
use alloy_primitives::{Address, U256};
use alloy_sol_types::SolInterface;
use anyhow::Result;
use fvm_shared::bigint::BigUint;
use fil_actors_runtime::{actor_error, ActorError};
use crate::credit_facade::icreditfacade::ICreditFacade;
use crate::impl_empty_returns;
use crate::types::AbiEncodeReturns;
use alloy_sol_types::SolCall;
use fendermint_actor_blobs_shared::state::{Account, Credit, CreditApproval};
use fvm_shared::address::{Address as FVMAddress};
use fvm_shared::clock::ChainEpoch;
use fvm_shared::econ::TokenAmount;
use fendermint_actor_blobs_shared::params::{ApproveCreditParams, GetAccountParams, GetCreditApprovalParams, GetStatsReturn, RevokeCreditParams, SetSponsorParams};
use fil_actors_evm_shared::address::EthAddress;

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

impl Into<GetAccountParams> for ICreditFacade::getAccountCall {
    fn into(self) -> GetAccountParams {
        let sponsor: EthAddress = self.addr.into_eth_address();
        let sponsor: FVMAddress = sponsor.into();
        GetAccountParams(sponsor)
    }
}

impl TryAbiEncodeReturns<Option<Account>> for ICreditFacade::getAccountCall {
    fn try_returns(&self, value: Option<Account>) -> Result<Vec<u8>, AbiEncodeError> {
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
    fn try_returns(&self, stats: GetStatsReturn) -> Result<Vec<u8>, AbiEncodeError> {
        let credit_stats = ICreditFacade::CreditStats {
            balance: BigUintWrapper::from(stats.balance).into(),
            creditSold: BigUintWrapper::from(stats.credit_sold).into(),
            creditCommitted: BigUintWrapper::from(stats.credit_committed).into(),
            creditDebited: BigUintWrapper::from(stats.credit_debited).into(),
            tokenCreditRate: BigUintWrapper(stats.token_credit_rate.rate().clone()).into(),
            numAccounts: stats.num_accounts
        };
        Ok(Self::abi_encode_returns(&(credit_stats,)))
    }
}

impl Into<GetCreditApprovalParams> for ICreditFacade::getCreditApprovalCall {
    fn into(self) -> GetCreditApprovalParams {
        let from: FVMAddress = self.from.into_eth_address().into();
        let to: FVMAddress = self.to.into_eth_address().into();
        GetCreditApprovalParams { from, to }
    }
}

impl TryAbiEncodeReturns<Option<CreditApproval>> for ICreditFacade::getCreditApprovalCall {
    fn try_returns(&self, value: Option<CreditApproval>) -> Result<Vec<u8>, AbiEncodeError> {
        let approval_result = if let Some(credit_approval) = value {
            ICreditFacade::CreditApproval::from(credit_approval.clone())
        } else {
            ICreditFacade::CreditApproval::default()
        };
        Ok(Self::abi_encode_returns(&(approval_result,)))
    }
}

impl TryAbiEncodeReturns<Option<Account>> for ICreditFacade::getCreditBalanceCall {
    fn try_returns(&self, value: Option<Account>) -> Result<Vec<u8>, AbiEncodeError> {
        let balance = if let Some(account) = value {
            ICreditFacade::Balance {
                creditFree: BigUintWrapper::from(account.credit_free).into(),
                creditCommitted: BigUintWrapper::from(account.credit_committed).into(),
                creditSponsor: account.credit_sponsor.map(|address| {
                    H160::try_from(address)
                }).transpose()?.map(|h160| h160.into()).unwrap_or_default(), // FIXME SU DRY
                lastDebitEpoch: account.last_debit_epoch as u64,
                approvalsTo: convert_approvals(account.approvals_to)?,
                approvalsFrom: convert_approvals(account.approvals_from)?,
                gasAllowance: BigUintWrapper::from(account.gas_allowance).into(),
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

impl Into<SetSponsorParams> for ICreditFacade::setAccountSponsorCall {
    fn into(self) -> SetSponsorParams {
        let from: FVMAddress = self.from.into_eth_address().into();
        let sponsor: EthAddress = self.sponsor.into_eth_address();
        let sponsor: Option<FVMAddress> = if sponsor.is_null() { None } else { Some(sponsor.into()) };
        SetSponsorParams {
            from,
            sponsor,
        }
    }
}

impl Into<ApproveCreditParams> for ICreditFacade::approveCredit_1Call {
    fn into(self) -> ApproveCreditParams {
        let from: FVMAddress = self.from.into_eth_address().into();
        let to: FVMAddress = self.to.into_eth_address().into();
        let caller_allowlist: HashSet<FVMAddress> = HashSet::from_iter(self.caller.iter().map(|address| <EthAddress as Into<FVMAddress>>::into(address.into_eth_address())));
        ApproveCreditParams {
            from,
            to,
            caller_allowlist: Some(caller_allowlist),
            credit_limit: None,
            gas_fee_limit: None,
            ttl: None
        }
    }
}

impl Into<ApproveCreditParams> for ICreditFacade::approveCredit_2Call {
    fn into(self) -> ApproveCreditParams {
        let from: FVMAddress = self.from.into_eth_address().into();
        let to: FVMAddress = self.to.into_eth_address().into();
        let caller_allowlist: HashSet<FVMAddress> = HashSet::from_iter(self.caller.iter().map(|address| <EthAddress as Into<FVMAddress>>::into(address.into_eth_address())));
        let credit_limit: Credit = BigUintWrapper::from(self.creditLimit).into();
        let gas_fee_limit: TokenAmount = BigUintWrapper::from(self.gasFeeLimit).into();
        let ttl = self.ttl;
        ApproveCreditParams {
            from,
            to,
            caller_allowlist: Some(caller_allowlist),
            credit_limit: Some(credit_limit),
            gas_fee_limit: Some(gas_fee_limit),
            ttl: Some(ttl as ChainEpoch)
        }
    }
}

impl Into<ApproveCreditParams> for ICreditFacade::approveCredit_3Call {
    fn into(self) -> ApproveCreditParams {
        let from: FVMAddress = self.from.into_eth_address().into();
        let to: FVMAddress = self.to.into_eth_address().into();
        ApproveCreditParams {
            from,
            to,
            caller_allowlist: None,
            credit_limit: None,
            gas_fee_limit: None,
            ttl: None
        }
    }
}

impl Into<RevokeCreditParams> for ICreditFacade::revokeCredit_0Call {
    fn into(self) -> RevokeCreditParams {
        let from: FVMAddress = self.from.into_eth_address().into();
        let to: FVMAddress = self.to.into_eth_address().into();
        RevokeCreditParams{
            from,
            to,
            for_caller: None,
        }
    }
}

impl Into<RevokeCreditParams> for ICreditFacade::revokeCredit_2Call {
    fn into(self) -> RevokeCreditParams {
        let from: FVMAddress = self.from.into_eth_address().into();
        let to: FVMAddress = self.to.into_eth_address().into();
        let caller: FVMAddress = self.caller.into_eth_address().into();
        RevokeCreditParams {
            from,
            to,
            for_caller: Some(caller),
        }
    }
}

impl_empty_returns!(
    ICreditFacade::setAccountSponsorCall,
    ICreditFacade::approveCredit_0Call,
    ICreditFacade::approveCredit_1Call,
    ICreditFacade::approveCredit_2Call,
    ICreditFacade::approveCredit_3Call,
    ICreditFacade::buyCredit_0Call,
    ICreditFacade::buyCredit_1Call,
    ICreditFacade::revokeCredit_0Call,
    ICreditFacade::revokeCredit_1Call,
    ICreditFacade::revokeCredit_2Call
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