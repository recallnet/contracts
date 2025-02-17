/**

Generated by the following Solidity interface...
```solidity
interface IBucketFacade {
    event ObjectAdded(bytes key, bytes32 blobHash, bytes metadata);
    event ObjectDeleted(bytes key, bytes32 blobHash);
    event ObjectMetadataUpdated(bytes key, bytes metadata);
}
```

...which was generated by the following JSON ABI:
```json
[
  {
    "type": "event",
    "name": "ObjectAdded",
    "inputs": [
      {
        "name": "key",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      },
      {
        "name": "blobHash",
        "type": "bytes32",
        "indexed": false,
        "internalType": "bytes32"
      },
      {
        "name": "metadata",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ObjectDeleted",
    "inputs": [
      {
        "name": "key",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      },
      {
        "name": "blobHash",
        "type": "bytes32",
        "indexed": false,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ObjectMetadataUpdated",
    "inputs": [
      {
        "name": "key",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      },
      {
        "name": "metadata",
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
pub mod IBucketFacade {
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
    /**Event with signature `ObjectAdded(bytes,bytes32,bytes)` and selector `0x3cf4a57a6c61242c0926d9fc09a382dba36a6e92628c777f1244c459b809793c`.
```solidity
event ObjectAdded(bytes key, bytes32 blobHash, bytes metadata);
```*/
    #[allow(
        non_camel_case_types,
        non_snake_case,
        clippy::pub_underscore_fields,
        clippy::style
    )]
    #[derive(Clone)]
    pub struct ObjectAdded {
        #[allow(missing_docs)]
        pub key: ::alloy_sol_types::private::Bytes,
        #[allow(missing_docs)]
        pub blobHash: ::alloy_sol_types::private::FixedBytes<32>,
        #[allow(missing_docs)]
        pub metadata: ::alloy_sol_types::private::Bytes,
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
        impl alloy_sol_types::SolEvent for ObjectAdded {
            type DataTuple<'a> = (
                ::alloy_sol_types::sol_data::Bytes,
                ::alloy_sol_types::sol_data::FixedBytes<32>,
                ::alloy_sol_types::sol_data::Bytes,
            );
            type DataToken<'a> = <Self::DataTuple<
                'a,
            > as alloy_sol_types::SolType>::Token<'a>;
            type TopicList = (alloy_sol_types::sol_data::FixedBytes<32>,);
            const SIGNATURE: &'static str = "ObjectAdded(bytes,bytes32,bytes)";
            const SIGNATURE_HASH: alloy_sol_types::private::B256 = alloy_sol_types::private::B256::new([
                60u8,
                244u8,
                165u8,
                122u8,
                108u8,
                97u8,
                36u8,
                44u8,
                9u8,
                38u8,
                217u8,
                252u8,
                9u8,
                163u8,
                130u8,
                219u8,
                163u8,
                106u8,
                110u8,
                146u8,
                98u8,
                140u8,
                119u8,
                127u8,
                18u8,
                68u8,
                196u8,
                89u8,
                184u8,
                9u8,
                121u8,
                60u8,
            ]);
            const ANONYMOUS: bool = false;
            #[allow(unused_variables)]
            #[inline]
            fn new(
                topics: <Self::TopicList as alloy_sol_types::SolType>::RustType,
                data: <Self::DataTuple<'_> as alloy_sol_types::SolType>::RustType,
            ) -> Self {
                Self {
                    key: data.0,
                    blobHash: data.1,
                    metadata: data.2,
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
                    <::alloy_sol_types::sol_data::Bytes as alloy_sol_types::SolType>::tokenize(
                        &self.key,
                    ),
                    <::alloy_sol_types::sol_data::FixedBytes<
                        32,
                    > as alloy_sol_types::SolType>::tokenize(&self.blobHash),
                    <::alloy_sol_types::sol_data::Bytes as alloy_sol_types::SolType>::tokenize(
                        &self.metadata,
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
        impl alloy_sol_types::private::IntoLogData for ObjectAdded {
            fn to_log_data(&self) -> alloy_sol_types::private::LogData {
                From::from(self)
            }
            fn into_log_data(self) -> alloy_sol_types::private::LogData {
                From::from(&self)
            }
        }
        #[automatically_derived]
        impl From<&ObjectAdded> for alloy_sol_types::private::LogData {
            #[inline]
            fn from(this: &ObjectAdded) -> alloy_sol_types::private::LogData {
                alloy_sol_types::SolEvent::encode_log_data(this)
            }
        }
    };
    /**Event with signature `ObjectDeleted(bytes,bytes32)` and selector `0x712864228f369cc20045ca173aab7455af58fa9f6dba07491092c93d2cf7fb06`.
```solidity
event ObjectDeleted(bytes key, bytes32 blobHash);
```*/
    #[allow(
        non_camel_case_types,
        non_snake_case,
        clippy::pub_underscore_fields,
        clippy::style
    )]
    #[derive(Clone)]
    pub struct ObjectDeleted {
        #[allow(missing_docs)]
        pub key: ::alloy_sol_types::private::Bytes,
        #[allow(missing_docs)]
        pub blobHash: ::alloy_sol_types::private::FixedBytes<32>,
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
        impl alloy_sol_types::SolEvent for ObjectDeleted {
            type DataTuple<'a> = (
                ::alloy_sol_types::sol_data::Bytes,
                ::alloy_sol_types::sol_data::FixedBytes<32>,
            );
            type DataToken<'a> = <Self::DataTuple<
                'a,
            > as alloy_sol_types::SolType>::Token<'a>;
            type TopicList = (alloy_sol_types::sol_data::FixedBytes<32>,);
            const SIGNATURE: &'static str = "ObjectDeleted(bytes,bytes32)";
            const SIGNATURE_HASH: alloy_sol_types::private::B256 = alloy_sol_types::private::B256::new([
                113u8,
                40u8,
                100u8,
                34u8,
                143u8,
                54u8,
                156u8,
                194u8,
                0u8,
                69u8,
                202u8,
                23u8,
                58u8,
                171u8,
                116u8,
                85u8,
                175u8,
                88u8,
                250u8,
                159u8,
                109u8,
                186u8,
                7u8,
                73u8,
                16u8,
                146u8,
                201u8,
                61u8,
                44u8,
                247u8,
                251u8,
                6u8,
            ]);
            const ANONYMOUS: bool = false;
            #[allow(unused_variables)]
            #[inline]
            fn new(
                topics: <Self::TopicList as alloy_sol_types::SolType>::RustType,
                data: <Self::DataTuple<'_> as alloy_sol_types::SolType>::RustType,
            ) -> Self {
                Self {
                    key: data.0,
                    blobHash: data.1,
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
                    <::alloy_sol_types::sol_data::Bytes as alloy_sol_types::SolType>::tokenize(
                        &self.key,
                    ),
                    <::alloy_sol_types::sol_data::FixedBytes<
                        32,
                    > as alloy_sol_types::SolType>::tokenize(&self.blobHash),
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
        impl alloy_sol_types::private::IntoLogData for ObjectDeleted {
            fn to_log_data(&self) -> alloy_sol_types::private::LogData {
                From::from(self)
            }
            fn into_log_data(self) -> alloy_sol_types::private::LogData {
                From::from(&self)
            }
        }
        #[automatically_derived]
        impl From<&ObjectDeleted> for alloy_sol_types::private::LogData {
            #[inline]
            fn from(this: &ObjectDeleted) -> alloy_sol_types::private::LogData {
                alloy_sol_types::SolEvent::encode_log_data(this)
            }
        }
    };
    /**Event with signature `ObjectMetadataUpdated(bytes,bytes)` and selector `0xa53f68921d8ba6356e423077a756ff2a282ae6de5d4ecc617da09b01ead5d640`.
```solidity
event ObjectMetadataUpdated(bytes key, bytes metadata);
```*/
    #[allow(
        non_camel_case_types,
        non_snake_case,
        clippy::pub_underscore_fields,
        clippy::style
    )]
    #[derive(Clone)]
    pub struct ObjectMetadataUpdated {
        #[allow(missing_docs)]
        pub key: ::alloy_sol_types::private::Bytes,
        #[allow(missing_docs)]
        pub metadata: ::alloy_sol_types::private::Bytes,
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
        impl alloy_sol_types::SolEvent for ObjectMetadataUpdated {
            type DataTuple<'a> = (
                ::alloy_sol_types::sol_data::Bytes,
                ::alloy_sol_types::sol_data::Bytes,
            );
            type DataToken<'a> = <Self::DataTuple<
                'a,
            > as alloy_sol_types::SolType>::Token<'a>;
            type TopicList = (alloy_sol_types::sol_data::FixedBytes<32>,);
            const SIGNATURE: &'static str = "ObjectMetadataUpdated(bytes,bytes)";
            const SIGNATURE_HASH: alloy_sol_types::private::B256 = alloy_sol_types::private::B256::new([
                165u8,
                63u8,
                104u8,
                146u8,
                29u8,
                139u8,
                166u8,
                53u8,
                110u8,
                66u8,
                48u8,
                119u8,
                167u8,
                86u8,
                255u8,
                42u8,
                40u8,
                42u8,
                230u8,
                222u8,
                93u8,
                78u8,
                204u8,
                97u8,
                125u8,
                160u8,
                155u8,
                1u8,
                234u8,
                213u8,
                214u8,
                64u8,
            ]);
            const ANONYMOUS: bool = false;
            #[allow(unused_variables)]
            #[inline]
            fn new(
                topics: <Self::TopicList as alloy_sol_types::SolType>::RustType,
                data: <Self::DataTuple<'_> as alloy_sol_types::SolType>::RustType,
            ) -> Self {
                Self {
                    key: data.0,
                    metadata: data.1,
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
                    <::alloy_sol_types::sol_data::Bytes as alloy_sol_types::SolType>::tokenize(
                        &self.key,
                    ),
                    <::alloy_sol_types::sol_data::Bytes as alloy_sol_types::SolType>::tokenize(
                        &self.metadata,
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
        impl alloy_sol_types::private::IntoLogData for ObjectMetadataUpdated {
            fn to_log_data(&self) -> alloy_sol_types::private::LogData {
                From::from(self)
            }
            fn into_log_data(self) -> alloy_sol_types::private::LogData {
                From::from(&self)
            }
        }
        #[automatically_derived]
        impl From<&ObjectMetadataUpdated> for alloy_sol_types::private::LogData {
            #[inline]
            fn from(this: &ObjectMetadataUpdated) -> alloy_sol_types::private::LogData {
                alloy_sol_types::SolEvent::encode_log_data(this)
            }
        }
    };
    ///Container for all the [`IBucketFacade`](self) events.
    pub enum IBucketFacadeEvents {
        #[allow(missing_docs)]
        ObjectAdded(ObjectAdded),
        #[allow(missing_docs)]
        ObjectDeleted(ObjectDeleted),
        #[allow(missing_docs)]
        ObjectMetadataUpdated(ObjectMetadataUpdated),
    }
    #[automatically_derived]
    impl IBucketFacadeEvents {
        /// All the selectors of this enum.
        ///
        /// Note that the selectors might not be in the same order as the variants.
        /// No guarantees are made about the order of the selectors.
        ///
        /// Prefer using `SolInterface` methods instead.
        pub const SELECTORS: &'static [[u8; 32usize]] = &[
            [
                60u8,
                244u8,
                165u8,
                122u8,
                108u8,
                97u8,
                36u8,
                44u8,
                9u8,
                38u8,
                217u8,
                252u8,
                9u8,
                163u8,
                130u8,
                219u8,
                163u8,
                106u8,
                110u8,
                146u8,
                98u8,
                140u8,
                119u8,
                127u8,
                18u8,
                68u8,
                196u8,
                89u8,
                184u8,
                9u8,
                121u8,
                60u8,
            ],
            [
                113u8,
                40u8,
                100u8,
                34u8,
                143u8,
                54u8,
                156u8,
                194u8,
                0u8,
                69u8,
                202u8,
                23u8,
                58u8,
                171u8,
                116u8,
                85u8,
                175u8,
                88u8,
                250u8,
                159u8,
                109u8,
                186u8,
                7u8,
                73u8,
                16u8,
                146u8,
                201u8,
                61u8,
                44u8,
                247u8,
                251u8,
                6u8,
            ],
            [
                165u8,
                63u8,
                104u8,
                146u8,
                29u8,
                139u8,
                166u8,
                53u8,
                110u8,
                66u8,
                48u8,
                119u8,
                167u8,
                86u8,
                255u8,
                42u8,
                40u8,
                42u8,
                230u8,
                222u8,
                93u8,
                78u8,
                204u8,
                97u8,
                125u8,
                160u8,
                155u8,
                1u8,
                234u8,
                213u8,
                214u8,
                64u8,
            ],
        ];
    }
    #[automatically_derived]
    impl alloy_sol_types::SolEventInterface for IBucketFacadeEvents {
        const NAME: &'static str = "IBucketFacadeEvents";
        const COUNT: usize = 3usize;
        fn decode_raw_log(
            topics: &[alloy_sol_types::Word],
            data: &[u8],
            validate: bool,
        ) -> alloy_sol_types::Result<Self> {
            match topics.first().copied() {
                Some(<ObjectAdded as alloy_sol_types::SolEvent>::SIGNATURE_HASH) => {
                    <ObjectAdded as alloy_sol_types::SolEvent>::decode_raw_log(
                            topics,
                            data,
                            validate,
                        )
                        .map(Self::ObjectAdded)
                }
                Some(<ObjectDeleted as alloy_sol_types::SolEvent>::SIGNATURE_HASH) => {
                    <ObjectDeleted as alloy_sol_types::SolEvent>::decode_raw_log(
                            topics,
                            data,
                            validate,
                        )
                        .map(Self::ObjectDeleted)
                }
                Some(
                    <ObjectMetadataUpdated as alloy_sol_types::SolEvent>::SIGNATURE_HASH,
                ) => {
                    <ObjectMetadataUpdated as alloy_sol_types::SolEvent>::decode_raw_log(
                            topics,
                            data,
                            validate,
                        )
                        .map(Self::ObjectMetadataUpdated)
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
    impl alloy_sol_types::private::IntoLogData for IBucketFacadeEvents {
        fn to_log_data(&self) -> alloy_sol_types::private::LogData {
            match self {
                Self::ObjectAdded(inner) => {
                    alloy_sol_types::private::IntoLogData::to_log_data(inner)
                }
                Self::ObjectDeleted(inner) => {
                    alloy_sol_types::private::IntoLogData::to_log_data(inner)
                }
                Self::ObjectMetadataUpdated(inner) => {
                    alloy_sol_types::private::IntoLogData::to_log_data(inner)
                }
            }
        }
        fn into_log_data(self) -> alloy_sol_types::private::LogData {
            match self {
                Self::ObjectAdded(inner) => {
                    alloy_sol_types::private::IntoLogData::into_log_data(inner)
                }
                Self::ObjectDeleted(inner) => {
                    alloy_sol_types::private::IntoLogData::into_log_data(inner)
                }
                Self::ObjectMetadataUpdated(inner) => {
                    alloy_sol_types::private::IntoLogData::into_log_data(inner)
                }
            }
        }
    }
}
