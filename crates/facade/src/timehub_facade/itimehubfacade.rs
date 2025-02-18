/**

Generated by the following Solidity interface...
```solidity
interface ITimehubFacade {
    event EventPushed(uint256 index, uint256 timestamp, bytes cid);
}
```

...which was generated by the following JSON ABI:
```json
[
  {
    "type": "event",
    "name": "EventPushed",
    "inputs": [
      {
        "name": "index",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "timestamp",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "cid",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
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
pub mod ITimehubFacade {
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
    /**Event with signature `EventPushed(uint256,uint256,bytes)` and selector `0x9f2453a8c6b2912a42d606880c3eeaadcc940925c2af1349422a17b816155415`.
```solidity
event EventPushed(uint256 index, uint256 timestamp, bytes cid);
```*/
    #[allow(
        non_camel_case_types,
        non_snake_case,
        clippy::pub_underscore_fields,
        clippy::style
    )]
    #[derive(Clone)]
    pub struct EventPushed {
        #[allow(missing_docs)]
        pub index: ::alloy_sol_types::private::primitives::aliases::U256,
        #[allow(missing_docs)]
        pub timestamp: ::alloy_sol_types::private::primitives::aliases::U256,
        #[allow(missing_docs)]
        pub cid: ::alloy_sol_types::private::Bytes,
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
        impl alloy_sol_types::SolEvent for EventPushed {
            type DataTuple<'a> = (
                ::alloy_sol_types::sol_data::Uint<256>,
                ::alloy_sol_types::sol_data::Uint<256>,
                ::alloy_sol_types::sol_data::Bytes,
            );
            type DataToken<'a> = <Self::DataTuple<
                'a,
            > as alloy_sol_types::SolType>::Token<'a>;
            type TopicList = (alloy_sol_types::sol_data::FixedBytes<32>,);
            const SIGNATURE: &'static str = "EventPushed(uint256,uint256,bytes)";
            const SIGNATURE_HASH: alloy_sol_types::private::B256 = alloy_sol_types::private::B256::new([
                159u8,
                36u8,
                83u8,
                168u8,
                198u8,
                178u8,
                145u8,
                42u8,
                66u8,
                214u8,
                6u8,
                136u8,
                12u8,
                62u8,
                234u8,
                173u8,
                204u8,
                148u8,
                9u8,
                37u8,
                194u8,
                175u8,
                19u8,
                73u8,
                66u8,
                42u8,
                23u8,
                184u8,
                22u8,
                21u8,
                84u8,
                21u8,
            ]);
            const ANONYMOUS: bool = false;
            #[allow(unused_variables)]
            #[inline]
            fn new(
                topics: <Self::TopicList as alloy_sol_types::SolType>::RustType,
                data: <Self::DataTuple<'_> as alloy_sol_types::SolType>::RustType,
            ) -> Self {
                Self {
                    index: data.0,
                    timestamp: data.1,
                    cid: data.2,
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
                    > as alloy_sol_types::SolType>::tokenize(&self.index),
                    <::alloy_sol_types::sol_data::Uint<
                        256,
                    > as alloy_sol_types::SolType>::tokenize(&self.timestamp),
                    <::alloy_sol_types::sol_data::Bytes as alloy_sol_types::SolType>::tokenize(
                        &self.cid,
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
        impl alloy_sol_types::private::IntoLogData for EventPushed {
            fn to_log_data(&self) -> alloy_sol_types::private::LogData {
                From::from(self)
            }
            fn into_log_data(self) -> alloy_sol_types::private::LogData {
                From::from(&self)
            }
        }
        #[automatically_derived]
        impl From<&EventPushed> for alloy_sol_types::private::LogData {
            #[inline]
            fn from(this: &EventPushed) -> alloy_sol_types::private::LogData {
                alloy_sol_types::SolEvent::encode_log_data(this)
            }
        }
    };
    ///Container for all the [`ITimehubFacade`](self) events.
    pub enum ITimehubFacadeEvents {
        #[allow(missing_docs)]
        EventPushed(EventPushed),
    }
    #[automatically_derived]
    impl ITimehubFacadeEvents {
        /// All the selectors of this enum.
        ///
        /// Note that the selectors might not be in the same order as the variants.
        /// No guarantees are made about the order of the selectors.
        ///
        /// Prefer using `SolInterface` methods instead.
        pub const SELECTORS: &'static [[u8; 32usize]] = &[
            [
                159u8,
                36u8,
                83u8,
                168u8,
                198u8,
                178u8,
                145u8,
                42u8,
                66u8,
                214u8,
                6u8,
                136u8,
                12u8,
                62u8,
                234u8,
                173u8,
                204u8,
                148u8,
                9u8,
                37u8,
                194u8,
                175u8,
                19u8,
                73u8,
                66u8,
                42u8,
                23u8,
                184u8,
                22u8,
                21u8,
                84u8,
                21u8,
            ],
        ];
    }
    #[automatically_derived]
    impl alloy_sol_types::SolEventInterface for ITimehubFacadeEvents {
        const NAME: &'static str = "ITimehubFacadeEvents";
        const COUNT: usize = 1usize;
        fn decode_raw_log(
            topics: &[alloy_sol_types::Word],
            data: &[u8],
            validate: bool,
        ) -> alloy_sol_types::Result<Self> {
            match topics.first().copied() {
                Some(<EventPushed as alloy_sol_types::SolEvent>::SIGNATURE_HASH) => {
                    <EventPushed as alloy_sol_types::SolEvent>::decode_raw_log(
                            topics,
                            data,
                            validate,
                        )
                        .map(Self::EventPushed)
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
    impl alloy_sol_types::private::IntoLogData for ITimehubFacadeEvents {
        fn to_log_data(&self) -> alloy_sol_types::private::LogData {
            match self {
                Self::EventPushed(inner) => {
                    alloy_sol_types::private::IntoLogData::to_log_data(inner)
                }
            }
        }
        fn into_log_data(self) -> alloy_sol_types::private::LogData {
            match self {
                Self::EventPushed(inner) => {
                    alloy_sol_types::private::IntoLogData::into_log_data(inner)
                }
            }
        }
    }
}
