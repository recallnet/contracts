/**

Generated by the following Solidity interface...
```solidity
interface IConfigFacade {
    event ConfigAdminSet(address admin);
    event ConfigSet(uint256 blobCapacity, uint256 tokenCreditRate, uint256 blobCreditDebitInterval, uint256 blobMinTtl, uint256 blobDefaultTtl, uint256 blobDeleteBatchSize, uint256 accountDebitBatchSize);
}
```

...which was generated by the following JSON ABI:
```json
[
  {
    "type": "event",
    "name": "ConfigAdminSet",
    "inputs": [
      {
        "name": "admin",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ConfigSet",
    "inputs": [
      {
        "name": "blobCapacity",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "tokenCreditRate",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "blobCreditDebitInterval",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "blobMinTtl",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "blobDefaultTtl",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "blobDeleteBatchSize",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "accountDebitBatchSize",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  }
]
```*/
#[allow(
    non_camel_case_types,
    non_snake_case,
    clippy::pub_underscore_fields,
    clippy::style,
    clippy::empty_structs_with_brackets
)]
pub mod IConfigFacade {
    use super::*;
    use ::alloy_sol_types as alloy_sol_types;
    /// The creation / init bytecode of the contract.
    ///
    /// ```text
    ///0x
    /// ```
    #[rustfmt::skip]
    #[allow(clippy::all)]
    pub static BYTECODE: alloy_sol_types::private::Bytes = alloy_sol_types::private::Bytes::from_static(
        b"",
    );
    /// The runtime bytecode of the contract, as deployed on the network.
    ///
    /// ```text
    ///0x
    /// ```
    #[rustfmt::skip]
    #[allow(clippy::all)]
    pub static DEPLOYED_BYTECODE: alloy_sol_types::private::Bytes = alloy_sol_types::private::Bytes::from_static(
        b"",
    );
    /**Event with signature `ConfigAdminSet(address)` and selector `0x17e2ccbcd78b64c943d403837b55290b3de8fd19c8df1c0ab9cf665b934292d4`.
```solidity
event ConfigAdminSet(address admin);
```*/
    #[allow(
        non_camel_case_types,
        non_snake_case,
        clippy::pub_underscore_fields,
        clippy::style
    )]
    #[derive(Clone)]
    pub struct ConfigAdminSet {
        #[allow(missing_docs)]
        pub admin: ::alloy_sol_types::private::Address,
    }
    #[allow(
        non_camel_case_types,
        non_snake_case,
        clippy::pub_underscore_fields,
        clippy::style
    )]
    const _: () = {
        use ::alloy_sol_types as alloy_sol_types;
        #[automatically_derived]
        impl alloy_sol_types::SolEvent for ConfigAdminSet {
            type DataTuple<'a> = (::alloy_sol_types::sol_data::Address,);
            type DataToken<'a> = <Self::DataTuple<
                'a,
            > as alloy_sol_types::SolType>::Token<'a>;
            type TopicList = (alloy_sol_types::sol_data::FixedBytes<32>,);
            const SIGNATURE: &'static str = "ConfigAdminSet(address)";
            const SIGNATURE_HASH: alloy_sol_types::private::B256 = alloy_sol_types::private::B256::new([
                23u8,
                226u8,
                204u8,
                188u8,
                215u8,
                139u8,
                100u8,
                201u8,
                67u8,
                212u8,
                3u8,
                131u8,
                123u8,
                85u8,
                41u8,
                11u8,
                61u8,
                232u8,
                253u8,
                25u8,
                200u8,
                223u8,
                28u8,
                10u8,
                185u8,
                207u8,
                102u8,
                91u8,
                147u8,
                66u8,
                146u8,
                212u8,
            ]);
            const ANONYMOUS: bool = false;
            #[allow(unused_variables)]
            #[inline]
            fn new(
                topics: <Self::TopicList as alloy_sol_types::SolType>::RustType,
                data: <Self::DataTuple<'_> as alloy_sol_types::SolType>::RustType,
            ) -> Self {
                Self { admin: data.0 }
            }
            #[inline]
            fn check_signature(
                topics: &<Self::TopicList as alloy_sol_types::SolType>::RustType,
            ) -> alloy_sol_types::Result<()> {
                if topics.0 != Self::SIGNATURE_HASH {
                    return Err(
                        alloy_sol_types::Error::invalid_event_signature_hash(
                            Self::SIGNATURE,
                            topics.0,
                            Self::SIGNATURE_HASH,
                        ),
                    );
                }
                Ok(())
            }
            #[inline]
            fn tokenize_body(&self) -> Self::DataToken<'_> {
                (
                    <::alloy_sol_types::sol_data::Address as alloy_sol_types::SolType>::tokenize(
                        &self.admin,
                    ),
                )
            }
            #[inline]
            fn topics(&self) -> <Self::TopicList as alloy_sol_types::SolType>::RustType {
                (Self::SIGNATURE_HASH.into(),)
            }
            #[inline]
            fn encode_topics_raw(
                &self,
                out: &mut [alloy_sol_types::abi::token::WordToken],
            ) -> alloy_sol_types::Result<()> {
                if out.len() < <Self::TopicList as alloy_sol_types::TopicList>::COUNT {
                    return Err(alloy_sol_types::Error::Overrun);
                }
                out[0usize] = alloy_sol_types::abi::token::WordToken(
                    Self::SIGNATURE_HASH,
                );
                Ok(())
            }
        }
        #[automatically_derived]
        impl alloy_sol_types::private::IntoLogData for ConfigAdminSet {
            fn to_log_data(&self) -> alloy_sol_types::private::LogData {
                From::from(self)
            }
            fn into_log_data(self) -> alloy_sol_types::private::LogData {
                From::from(&self)
            }
        }
        #[automatically_derived]
        impl From<&ConfigAdminSet> for alloy_sol_types::private::LogData {
            #[inline]
            fn from(this: &ConfigAdminSet) -> alloy_sol_types::private::LogData {
                alloy_sol_types::SolEvent::encode_log_data(this)
            }
        }
    };
    /**Event with signature `ConfigSet(uint256,uint256,uint256,uint256,uint256,uint256,uint256)` and selector `0x3e8ad89b763b9839647a482aef0ebd06350b9fe255fd58263b81888ff1717488`.
```solidity
event ConfigSet(uint256 blobCapacity, uint256 tokenCreditRate, uint256 blobCreditDebitInterval, uint256 blobMinTtl, uint256 blobDefaultTtl, uint256 blobDeleteBatchSize, uint256 accountDebitBatchSize);
```*/
    #[allow(
        non_camel_case_types,
        non_snake_case,
        clippy::pub_underscore_fields,
        clippy::style
    )]
    #[derive(Clone)]
    pub struct ConfigSet {
        #[allow(missing_docs)]
        pub blobCapacity: ::alloy_sol_types::private::primitives::aliases::U256,
        #[allow(missing_docs)]
        pub tokenCreditRate: ::alloy_sol_types::private::primitives::aliases::U256,
        #[allow(missing_docs)]
        pub blobCreditDebitInterval: ::alloy_sol_types::private::primitives::aliases::U256,
        #[allow(missing_docs)]
        pub blobMinTtl: ::alloy_sol_types::private::primitives::aliases::U256,
        #[allow(missing_docs)]
        pub blobDefaultTtl: ::alloy_sol_types::private::primitives::aliases::U256,
        #[allow(missing_docs)]
        pub blobDeleteBatchSize: ::alloy_sol_types::private::primitives::aliases::U256,
        #[allow(missing_docs)]
        pub accountDebitBatchSize: ::alloy_sol_types::private::primitives::aliases::U256,
    }
    #[allow(
        non_camel_case_types,
        non_snake_case,
        clippy::pub_underscore_fields,
        clippy::style
    )]
    const _: () = {
        use ::alloy_sol_types as alloy_sol_types;
        #[automatically_derived]
        impl alloy_sol_types::SolEvent for ConfigSet {
            type DataTuple<'a> = (
                ::alloy_sol_types::sol_data::Uint<256>,
                ::alloy_sol_types::sol_data::Uint<256>,
                ::alloy_sol_types::sol_data::Uint<256>,
                ::alloy_sol_types::sol_data::Uint<256>,
                ::alloy_sol_types::sol_data::Uint<256>,
                ::alloy_sol_types::sol_data::Uint<256>,
                ::alloy_sol_types::sol_data::Uint<256>,
            );
            type DataToken<'a> = <Self::DataTuple<
                'a,
            > as alloy_sol_types::SolType>::Token<'a>;
            type TopicList = (alloy_sol_types::sol_data::FixedBytes<32>,);
            const SIGNATURE: &'static str = "ConfigSet(uint256,uint256,uint256,uint256,uint256,uint256,uint256)";
            const SIGNATURE_HASH: alloy_sol_types::private::B256 = alloy_sol_types::private::B256::new([
                62u8,
                138u8,
                216u8,
                155u8,
                118u8,
                59u8,
                152u8,
                57u8,
                100u8,
                122u8,
                72u8,
                42u8,
                239u8,
                14u8,
                189u8,
                6u8,
                53u8,
                11u8,
                159u8,
                226u8,
                85u8,
                253u8,
                88u8,
                38u8,
                59u8,
                129u8,
                136u8,
                143u8,
                241u8,
                113u8,
                116u8,
                136u8,
            ]);
            const ANONYMOUS: bool = false;
            #[allow(unused_variables)]
            #[inline]
            fn new(
                topics: <Self::TopicList as alloy_sol_types::SolType>::RustType,
                data: <Self::DataTuple<'_> as alloy_sol_types::SolType>::RustType,
            ) -> Self {
                Self {
                    blobCapacity: data.0,
                    tokenCreditRate: data.1,
                    blobCreditDebitInterval: data.2,
                    blobMinTtl: data.3,
                    blobDefaultTtl: data.4,
                    blobDeleteBatchSize: data.5,
                    accountDebitBatchSize: data.6,
                }
            }
            #[inline]
            fn check_signature(
                topics: &<Self::TopicList as alloy_sol_types::SolType>::RustType,
            ) -> alloy_sol_types::Result<()> {
                if topics.0 != Self::SIGNATURE_HASH {
                    return Err(
                        alloy_sol_types::Error::invalid_event_signature_hash(
                            Self::SIGNATURE,
                            topics.0,
                            Self::SIGNATURE_HASH,
                        ),
                    );
                }
                Ok(())
            }
            #[inline]
            fn tokenize_body(&self) -> Self::DataToken<'_> {
                (
                    <::alloy_sol_types::sol_data::Uint<
                        256,
                    > as alloy_sol_types::SolType>::tokenize(&self.blobCapacity),
                    <::alloy_sol_types::sol_data::Uint<
                        256,
                    > as alloy_sol_types::SolType>::tokenize(&self.tokenCreditRate),
                    <::alloy_sol_types::sol_data::Uint<
                        256,
                    > as alloy_sol_types::SolType>::tokenize(
                        &self.blobCreditDebitInterval,
                    ),
                    <::alloy_sol_types::sol_data::Uint<
                        256,
                    > as alloy_sol_types::SolType>::tokenize(&self.blobMinTtl),
                    <::alloy_sol_types::sol_data::Uint<
                        256,
                    > as alloy_sol_types::SolType>::tokenize(&self.blobDefaultTtl),
                    <::alloy_sol_types::sol_data::Uint<
                        256,
                    > as alloy_sol_types::SolType>::tokenize(&self.blobDeleteBatchSize),
                    <::alloy_sol_types::sol_data::Uint<
                        256,
                    > as alloy_sol_types::SolType>::tokenize(&self.accountDebitBatchSize),
                )
            }
            #[inline]
            fn topics(&self) -> <Self::TopicList as alloy_sol_types::SolType>::RustType {
                (Self::SIGNATURE_HASH.into(),)
            }
            #[inline]
            fn encode_topics_raw(
                &self,
                out: &mut [alloy_sol_types::abi::token::WordToken],
            ) -> alloy_sol_types::Result<()> {
                if out.len() < <Self::TopicList as alloy_sol_types::TopicList>::COUNT {
                    return Err(alloy_sol_types::Error::Overrun);
                }
                out[0usize] = alloy_sol_types::abi::token::WordToken(
                    Self::SIGNATURE_HASH,
                );
                Ok(())
            }
        }
        #[automatically_derived]
        impl alloy_sol_types::private::IntoLogData for ConfigSet {
            fn to_log_data(&self) -> alloy_sol_types::private::LogData {
                From::from(self)
            }
            fn into_log_data(self) -> alloy_sol_types::private::LogData {
                From::from(&self)
            }
        }
        #[automatically_derived]
        impl From<&ConfigSet> for alloy_sol_types::private::LogData {
            #[inline]
            fn from(this: &ConfigSet) -> alloy_sol_types::private::LogData {
                alloy_sol_types::SolEvent::encode_log_data(this)
            }
        }
    };
    ///Container for all the [`IConfigFacade`](self) events.
    pub enum IConfigFacadeEvents {
        #[allow(missing_docs)]
        ConfigAdminSet(ConfigAdminSet),
        #[allow(missing_docs)]
        ConfigSet(ConfigSet),
    }
    #[automatically_derived]
    impl IConfigFacadeEvents {
        /// All the selectors of this enum.
        ///
        /// Note that the selectors might not be in the same order as the variants.
        /// No guarantees are made about the order of the selectors.
        ///
        /// Prefer using `SolInterface` methods instead.
        pub const SELECTORS: &'static [[u8; 32usize]] = &[
            [
                23u8,
                226u8,
                204u8,
                188u8,
                215u8,
                139u8,
                100u8,
                201u8,
                67u8,
                212u8,
                3u8,
                131u8,
                123u8,
                85u8,
                41u8,
                11u8,
                61u8,
                232u8,
                253u8,
                25u8,
                200u8,
                223u8,
                28u8,
                10u8,
                185u8,
                207u8,
                102u8,
                91u8,
                147u8,
                66u8,
                146u8,
                212u8,
            ],
            [
                62u8,
                138u8,
                216u8,
                155u8,
                118u8,
                59u8,
                152u8,
                57u8,
                100u8,
                122u8,
                72u8,
                42u8,
                239u8,
                14u8,
                189u8,
                6u8,
                53u8,
                11u8,
                159u8,
                226u8,
                85u8,
                253u8,
                88u8,
                38u8,
                59u8,
                129u8,
                136u8,
                143u8,
                241u8,
                113u8,
                116u8,
                136u8,
            ],
        ];
    }
    #[automatically_derived]
    impl alloy_sol_types::SolEventInterface for IConfigFacadeEvents {
        const NAME: &'static str = "IConfigFacadeEvents";
        const COUNT: usize = 2usize;
        fn decode_raw_log(
            topics: &[alloy_sol_types::Word],
            data: &[u8],
            validate: bool,
        ) -> alloy_sol_types::Result<Self> {
            match topics.first().copied() {
                Some(<ConfigAdminSet as alloy_sol_types::SolEvent>::SIGNATURE_HASH) => {
                    <ConfigAdminSet as alloy_sol_types::SolEvent>::decode_raw_log(
                            topics,
                            data,
                            validate,
                        )
                        .map(Self::ConfigAdminSet)
                }
                Some(<ConfigSet as alloy_sol_types::SolEvent>::SIGNATURE_HASH) => {
                    <ConfigSet as alloy_sol_types::SolEvent>::decode_raw_log(
                            topics,
                            data,
                            validate,
                        )
                        .map(Self::ConfigSet)
                }
                _ => {
                    alloy_sol_types::private::Err(alloy_sol_types::Error::InvalidLog {
                        name: <Self as alloy_sol_types::SolEventInterface>::NAME,
                        log: alloy_sol_types::private::Box::new(
                            alloy_sol_types::private::LogData::new_unchecked(
                                topics.to_vec(),
                                data.to_vec().into(),
                            ),
                        ),
                    })
                }
            }
        }
    }
    #[automatically_derived]
    impl alloy_sol_types::private::IntoLogData for IConfigFacadeEvents {
        fn to_log_data(&self) -> alloy_sol_types::private::LogData {
            match self {
                Self::ConfigAdminSet(inner) => {
                    alloy_sol_types::private::IntoLogData::to_log_data(inner)
                }
                Self::ConfigSet(inner) => {
                    alloy_sol_types::private::IntoLogData::to_log_data(inner)
                }
            }
        }
        fn into_log_data(self) -> alloy_sol_types::private::LogData {
            match self {
                Self::ConfigAdminSet(inner) => {
                    alloy_sol_types::private::IntoLogData::into_log_data(inner)
                }
                Self::ConfigSet(inner) => {
                    alloy_sol_types::private::IntoLogData::into_log_data(inner)
                }
            }
        }
    }
}
