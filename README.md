# Hoku Contracts

[![License](https://img.shields.io/github/license/hokunet/contracts.svg)](./LICENSE)
[![standard-readme compliant](https://img.shields.io/badge/standard--readme-OK-green.svg)](https://github.com/RichardLitt/standard-readme)

> Hoku core Solidity contracts and libraries

## Table of Contents

- [Background](#background)
  - [Deployments](#deployments)
- [Usage](#usage)
  - [Setup](#setup)
  - [Deploying contracts](#deploying-contracts)
    - [Localnet](#localnet)
    - [Testnet](#testnet)
    - [Devnet](#devnet)
    - [Mainnet](#mainnet)
- [Development](#development)
  - [Scripts](#scripts)
  - [Examples usage](#examples-usage)
  - [Credit contract](#credit-contract)
    - [Methods](#methods)
    - [Examples](#examples)
  - [Buckets contract](#buckets-contract)
    - [Methods](#methods-1)
    - [Examples](#examples-1)
    - [Query objects](#query-objects)
  - [Blobs contract](#blobs-contract)
    - [Methods](#methods-2)
  - [Testing](#testing)

## Background

This project is built with [Foundry](https://book.getfoundry.sh/) and contains the core contracts
for Hoku. It includes the following:

- `Hoku.sol`: An ERC20 token implementation.
- `Faucet.sol`: The accompanying onchain faucet (rate limiter) contract for dripping testnet funds.
- `CreditManager.sol`: Manage subnet credit, including credit purchases, approvals/rejections, and
  related read-only operations (uses the `LibCredit` and `LibWasm` libraries).
- `BucketManager.sol`: Manage buckets, including creating buckets, listing buckets, querying
  objects, and other object-related operations (uses the `LibBucket` and `LibWasm` libraries).
- `ValidatorGater.sol`: A contract for managing validator access.
- `interfaces/ICredit.sol`: The interface for the credit contract.
- `types/`: Various method parameters and return types for core contracts.
- `utils/LibCredit.sol`: A library for interacting with credits, wrapped by the `Credit` contract.
- `utils/LibBucket.sol`: A library for interacting with buckets, wrapped by the `BucketManager`
  contract.
- `utils/LibWasm.sol`: A library for facilitating proxy calls to WASM contracts from Solidity.
- `utils/solidity-cbor`: Libraries for encoding and decoding CBOR data, used in proxy WASM calls
  (forked from [this repo](https://github.com/smartcontractkit/solidity-cborutils)).
- `utils/Base32.sol`: Utilities for encoding and decoding base32.
- `utils/Blake2b.sol`: Utilities for Blake2b hashing (used for WASM `t2` addresses).

### Deployments

The following contracts are deployed in the testnet environment (Filecoin Calibration or the Hoku
subnet):

| Contract       | Chain       | Address                                      |
| -------------- | ----------- | -------------------------------------------- |
| Hoku (ERC20)   | Calibration | `0x20d8a696091153c4d4816ba1fdefe113f71e0905` |
| Faucet         | Subnet      | `0x7Aff9112A46D98A455f4d4F93c0e3D2438716A44` |
| BlobManager    | Subnet      | `0xTODO`                                     |
| BucketManager  | Subnet      | `0xTODO`                                     |
| CreditManager  | Subnet      | `0xTODO`                                     |
| ValidatorGater | Subnet      | `0x880126f3134EdFBa4f1a65827D5870f021bb7124` |

To get testnet tokens, visit: [https://faucet.hoku.sh](https://faucet.hoku.sh). Also, you can check
out the `foundry.toml` file to see the RPC URLs for each network (described in more detail below).

## Usage

### Setup

First, clone the repo, and be sure `foundry` is installed on your machine (see
[here](https://book.getfoundry.sh/getting-started/installation)):

```shell
git clone https://github.com/hokunet/contracts.git
cd contracts
```

Install the dependencies and build the contracts, which will output the ABIs to the `out/`
directory:

```shell
pnpm install
forge install
forge build
```

Also, you can clean the build artifacts with:

```shell
pnpm clean
```

### Deploying contracts

The scripts for deploying contracts are in `script/` directory:

- `Hoku.s.sol`: Deploy the Hoku ERC20 contract.
- `Faucet.s.sol`: Deploy the faucet contract.
- `ValidatorGater.s.sol`: Deploy the validator gater contract.
- `CreditManager.s.sol`: Deploy the credit contract.
- `BlobManager.s.sol`: Deploy the blobs contract.
- `BucketManager.s.sol`: Deploy the Bucket Manager contract.
- `Bridge.s.sol`: Deploy the bridge contract—relevant for the Hoku ERC20 on live chains.

> [!NOTE] If you're deploying _to_ the Hoku subnet or Filecoin Calibration, you'll need to
> (significantly) bump the gas estimation multiplier by adding a `-g 100000` flag to the
> `forge script` command.

Each script uses the `--private-key` flag, and the script examples below demonstrate its usage with
a `PRIVATE_KEY` (hex prefixed) environment variable for the account that deploy the contract:

```sh
export PRIVATE_KEY=<0x...>
```

You can run a script with `forge script`, passing the script path/name and any arguments. The
`--rpc-url` flag can make use of the RPC endpoints defined in `foundry.toml`:

- `localnet_parent`: Deploy to localnet and the parent (Anvil) node.
- `localnet_subnet`: Deploy to localnet and the subnet node.
- `testnet_parent`: Deploy to testnet and the parent network (Filecoin Calibration).
- `testnet_subnet`: Deploy to testnet and the subnet (Hoku).
- `devnet`: Deploy to the devnet network.

The `--target-contract` (`--tc`) should be `DeployScript`, and it takes an argument for the
environment used by the `--sig` flag below:

- `local`: Local chain(for either localnet or devnet)
- `testnet`: Testnet chain
- `ethereum` or `filecoin`: Mainnet chain (note: mainnet is not available yet)

Most scripts use the `--sig` flag with `run(string)` (or `run(string,uint256)` for the faucet) to
execute deployment with the given argument above, and the `--broadcast` flag actually sends the
transaction to the network. Recall that you **must** set `-g 100000` to ensure the gas estimate is
sufficiently high.

Lastly, if you're deploying the Hoku ERC20, the environment will dictate different token symbols:

- Local: prefixes `HOKU` with `l`
- Testnet: prefixes `HOKU` with `t`
- Mainnet: uses `HOKU`

Mainnet deployments require the address of the Axelar Interchain Token Service on chain you are
deploying to, which is handled in the ERC20's `DeployScript` logic.

#### Localnet

##### Hoku ERC20

Deploy the Hoku ERC20 contract to the localnet parent chain (i.e., `http://localhost:8545`). Note
the `-g` flag is not used here since the gas estimate is sufficiently low on Anvil.

```shell
forge script script/Hoku.s.sol --tc DeployScript --sig 'run(string)' local --rpc-url localnet_parent --private-key $PRIVATE_KEY --broadcast -vv
```

##### Faucet

Deploy the Faucet contract to the localnet subnet. The second argument is the initial supply of Hoku
tokens, owned by the deployer's account which will be transferred to the faucet contract (e.g., 5000
with 10\*\*18 decimal units).

```shell
PRIVATE_KEY=<0x...> forge script script/Faucet.s.sol --tc DeployScript --sig 'run(uint256)' 5000000000000000000000 --rpc-url localnet_subnet --private-key $PRIVATE_KEY --broadcast -g 100000 -vv
```

##### Credit

Deploy the Credit contract to the localnet subnet:

```shell
forge script script/CreditManager.s.sol --tc DeployScript --sig 'run()' --rpc-url localnet_subnet --private-key $PRIVATE_KEY --broadcast -g 100000 -vv
```

##### Buckets

Deploy the Bucket Manager contract to the localnet subnet:

```shell
forge script script/BucketManager.s.sol --tc DeployScript --sig 'run()' --rpc-url localnet_subnet --private-key $PRIVATE_KEY --broadcast -g 100000 -vv
```

##### Blobs

Deploy the Blob Manager contract to the localnet subnet:

```shell
forge script script/BlobManager.s.sol --tc DeployScript --sig 'run()' --rpc-url localnet_subnet --private-key $PRIVATE_KEY --broadcast -g 100000 -vv
```

#### Testnet

##### Hoku ERC20

Deploy the Hoku ERC20 contract to the testnet parent chain. Note the `-g` flag _is_ used here (this
differs from the localnet setup above since we're deploying to Filecoin Calibration);

```shell
forge script script/Hoku.s.sol --tc DeployScript --sig 'run(string)' testnet --rpc-url testnet_parent --private-key $PRIVATE_KEY --broadcast -g 100000 -vv
```

##### Faucet

Deploy the Faucet contract to the testnet subnet. The second argument is the initial supply of Hoku
tokens, owned by the deployer's account which will be transferred to the faucet contract (e.g., 5000
with 10\*\*18 decimal units).

```shell
forge script script/Faucet.s.sol --tc DeployScript --sig 'run(uint256)' 5000000000000000000000 --rpc-url testnet_subnet --private-key $PRIVATE_KEY --broadcast -g 100000 -vv
```

##### Credit

Deploy the Credit Manager contract to the testnet subnet:

```shell
forge script script/CreditManager.s.sol --tc DeployScript --sig 'run()' --rpc-url testnet_subnet --private-key $PRIVATE_KEY --broadcast -g 100000 -vv
```

##### Buckets

Deploy the Bucket Manager contract to the testnet subnet:

```shell
forge script script/BucketManager.s.sol --tc DeployScript --sig 'run()' --rpc-url testnet_subnet --private-key $PRIVATE_KEY --broadcast -g 100000 -vv
```

##### Blobs

Deploy the Blob Manager contract to the testnet subnet:

```shell
forge script script/BlobManager.s.sol --tc DeployScript --sig 'run()' --rpc-url testnet_subnet --private-key $PRIVATE_KEY --broadcast -g 100000 -vv
```

#### Devnet

The devnet does not have the concept of a "parent" chain, so all RPCs would use `--rpc-url devnet`
and follow the same pattern as the deployments above.

If you're trying to simply deploy to an Anvil node (i.e., `http://localhost:8545`), you can use the
same pattern, or just explicitly set the RPC URL:

```shell
forge script script/Hoku.s.sol --tc DeployScript --sig 'run(string)' local --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast -vv
```

#### Mainnet

Mainnet is not yet available. The RPC URLs (`mainnet_parent` and `mainnet_subnet`) are placeholders,
pointing to the same environment as the testnet.

##### Hoku ERC20

However, if you'd like to deploy the HOKU ERC20 contract to mainnet Ethereum or Filecoin, you can
use the following. Note these will enable behavior for the Axelar Interchain Token Service.

Deploy to Ethereum:

```shell
forge script script/Hoku.s.sol:DeployScript --sig 'run(string)' ethereum --rpc-url https://eth.merkle.io --private-key $PRIVATE_KEY --broadcast -vv
```

And for Filecoin:

```shell
forge script script/Hoku.s.sol:DeployScript --sig 'run(string)' filecoin --rpc-url https://api.node.glif.io/rpc/v1 --private-key $PRIVATE_KEY --broadcast -vv
```

## Development

### Scripts

Deployment scripts are described above. Additional `pnpm` scripts are available in `package.json`:

- `format`: Run `forge fmt` to format the code.
- `lint`: Run `forge fmt` and `solhint` to check for linting errors.
- `test`: Run `forge test` to run the tests.
- `clean`: Run `forge clean` to clean the build artifacts.

### Examples usage

Below are examples for interacting with various contracts. We'll set a few environment variables to
demonstrate usage patterns, all of which will assume you've first defined the following. We'll first
set the `PRIVATE_KEY` to the hex-encoded private key (same as with the deployment scripts above),
and an arbitrary `EVM_ADDRESS` that is the public key of this private key.

```sh
export PRIVATE_KEY=0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
export EVM_ADDRESS=0x90f79bf6eb2c4f870365e785982e1f101e93b906
```

The `--rpc-url` flag can use the same RPC URLs as the deployments scripts, as defined in
`foundry.toml`. For simplicity sake, we'll define an environment variable `ETH_RPC_URL` set to one
of these RPC URLs so these examples can be run as-is:

```sh
export ETH_RPC_URL=testnet_subnet
```

The subsequent sections will define other environment variables as needed.

### Credit contract

You can interact with the existing credit contract on the testnet via the address above. If you're
working on `localnet`, you'll have to deploy this yourself. Here's a quick one-liner to do so—also
setting the `CREDIT` environment variable to the deployed address:

```
CREDIT=$(forge script script/CreditManager.s.sol \
--tc DeployScript \
--sig 'run()' \
--rpc-url localnet_subnet \
--private-key $PRIVATE_KEY \
--broadcast \
-g 100000 \
| grep "0: contract CreditManager" | awk '{print $NF}')
```

#### Methods

The following methods are available on the credit contract, shown with their function signatures.
Note that overloads are available for some methods, primarily, where the underlying WASM contract
accepts "optional" arguments. All of the method parameters and return types can be found in
`util/CreditTypes.sol`.

- `getAccount(address)`: Get credit account info for an address.
- `getCreditStats()`: Get credit stats.
- `getCreditBalance(address)`: Get credit balance for an address.
- `buyCredit()`: Buy credit for the `msg.sender`.
- `buyCredit(address)`: Buy credit for the given address.
- `approveCredit(address)`: Approve credit for an address (`to`), assuming `msg.sender` is the owner
  of the credit (inferred as `from` in underlying logic).
- `approveCredit(address,address)`: Approve credit for the credit owner (`from`) for an address
  (`to`). Effectively, the same as `approveCredit(address)` but explicitly sets the `from` address.
- `approveCredit(address,address,address[])`: Approve credit for the credit owner (`from`) for an
  address (`to`), with a restriction on the caller address (`caller`) (e.g., enforce `to` can only
  use credit at `caller`).
- `approveCredit(address,address,address[],uint256,uint256,uint64)`: Approve credit for the credit
  owner (`from`) for an address (`to`), providing all of the optional fields (`caller`,
  `creditLimit`, `gasFeeLimit`, and `ttl`).
- `setCreditSponsor(address,address)`: Set the credit sponsor for an address (`from`) to an address
  (`sponsor`, use zero address if unused).
- `revokeCredit(address)`: Revoke credit for an address (`to`), assuming `msg.sender` is the owner
  of the credit (inferred as `from` in underlying logic).
- `revokeCredit(address,address)`: Revoke credit for the credit owner (`from`) for an address
  (`to`). Effectively, the same as `approveCredit(address)` but explicitly sets the `from` address.
- `revokeCredit(address,address,address)`: Revoke credit for the credit owner (`from`) for an
  address (`to`), with a restriction on the caller address (`caller`) (e.g., remove permissions for
  `to` at `caller`).

The overloads above have a bit of nuance when it comes to "optional" arguments. See the `ICredit`
interface in `interfaces/ICredit.sol` for more details. For example, zero values are interpreted as
null values when encoded in WASM calls.

#### Examples

Make sure you've already set the `PRIVATE_KEY`, `EVM_ADDRESS`, and `ETH_RPC_URL` environment
variables. Then, define a `CREDIT` environment variable, which points to the credit contract
deployment address. For example:

```sh
export CREDIT=0xAfC2973fbc4213DA7007A6b9459003A89c9C5b0E
```

And lastly, we'll define a `RECEIVER_ADDR` environment variable, which points to the `to` address
we'll be approving and revoking credit for. For example:

```sh
export RECEIVER_ADDR=0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
```

##### Get account info

We can get the credit account info for the address at `EVM_ADDRESS` (the variable we set above), or
you could provide any account's EVM public key that exists in the subnet.

```sh
cast abi-decode "getAccount(address)((uint64,uint256,uint256,address,uint64,(string,(uint256,uint256,uint64,uint256,uint256))[],uint64,uint256))" $(cast call --rpc-url $ETH_RPC_URL $CREDIT "getAccount(address)" $EVM_ADDRESS)
```

This will return the following values:

```
(6, 4999999999999999454276000000000000000000 [4.999e39], 504150000000000000000000 [5.041e23], 0x0000000000000000000000000000000000000000, 7200, [("f0127", (12345000000000000000000 [1.234e22], 987654321 [9.876e8], 11722 [1.172e4], 0, 0))], 86400 [8.64e4], 4999999984799342175554 [4.999e21])
```

Which maps to the `Account` struct:

```solidity
struct Account {
    uint256 capacityUsed; // 6
    uint256 creditFree; // 4999999999999999454276000000000000000000
    uint256 creditCommitted; // 504150000000000000000000
    address creditSponsor; // 0x0000000000000000000000000000000000000000 (null)
    uint64 lastDebitEpoch; // 7200
    Approval[] approvals; // See Approval struct below
    uint64 maxTtl; // 86400
    uint256 gasAllowance; // 4999999984799342175554
}
```

The `approvals` array is empty if no approvals have been made. However, our example _does_ have
approvals authorized. We can expand this to be interpreted as the following:

```solidity
struct Approval {
    string to; // f0127
    CreditApproval approval; // See CreditApproval struct below
}

struct CreditApproval {
    uint256 creditLimit; // 12345000000000000000000
    uint256 gasFeeLimit; // 987654321
    uint64 expiry; // 11722
    uint256 creditUsed; // 0
    uint256 gasFeeUsed; // 0
}
```

Due to intricacies with optional arguments in WASM being used in Solidity, you can interpret zero
values as null values in the structs above. That is, the example address has no restrictions on the
`limit` or `expiry` with using the delegated/approved credit from the owner's account.

##### Get credit stats

We can fetch the overall credit stats for the subnet with the following command:

```sh
cast abi-decode "getCreditStats()((uint256,uint256,uint256,uint256,uint64,uint64))" $(cast call --rpc-url $ETH_RPC_URL $CREDIT "getCreditStats()")
```

This will return the following values:

```
(50000999975762821509530 [5e22], 50001000000000000000000 [5e22], 21600 [2.16e4], 24237178535296 [2.423e13], 1000000000000000000000000000000000000 [1e36], 10)
```

Which maps to the `CreditStats` struct:

```solidity
struct CreditStats {
    uint256 balance; // 50000999975762821509530
    uint256 creditSold; // 50001000000000000000000
    uint256 creditCommitted; // 21600
    uint256 creditDebited; // 24237178535296
    uint256 tokenCreditRate; // 1000000000000000000000000000000000000
    uint64 numAccounts; // 10
}
```

##### Get credit balance for an account

Fetch the credit balance for the address at `EVM_ADDRESS`:

```sh
cast abi-decode "getCreditBalance(address)((uint256,uint256,address,uint64,(string,(uint256,uint256,uint64,uint256,uint256))[],uint256))" $(cast call --rpc-url $ETH_RPC_URL $CREDIT "getCreditBalance(address)" $EVM_ADDRESS)
```

This will return the following values:

```
(5001999999999998208637000000000000000000 [5.001e39], 518400000000000000000000 [5.184e23], 0x0000000000000000000000000000000000000000, 6932, [("f0127", (0, 0, 0, 0, 0))], 1)
```

Which maps to the `Balance` struct:

```solidity
struct Balance {
    uint256 creditFree; // 5001999999999998208637000000000000000000
    uint256 creditCommitted; // 518400000000000000000000
    address creditSponsor; // 0x0000000000000000000000000000000000000000 (null)
    uint64 lastDebitEpoch; // 6932
    Approval[] approvals; // See Approval struct below
}

struct Approval {
    string to; // f0127
    CreditApproval approval; // See CreditApproval struct below
}

struct CreditApproval {
    uint256 creditLimit; // 0
    uint256 gasFeeLimit; // 0
    uint64 expiry; // 0
    uint256 creditUsed; // 0
    uint256 gasFeeUsed; // 0
}
```

##### Buy credit for an address

You can buy credit for your address with the following command, which will buy credit equivalent to
1 native subnet token (via `msg.value`) for the `msg.sender`:

```sh
cast send --rpc-url $ETH_RPC_URL $CREDIT "buyCredit()" --value 1ether --private-key $PRIVATE_KEY
```

Or, you can buy credit for a specific EVM address with the following command:

```sh
cast send --rpc-url $ETH_RPC_URL $CREDIT "buyCredit(address)" $EVM_ADDRESS --value 1ether --private-key $PRIVATE_KEY
```

##### Approve credit for an address

Approving credit has a few variations. The first variation is approving credit for the address
defined in the call, assuming the `msg.sender` is the owner of the credit. The `RECEIVER_ADDR`
address is the `to` we want to approve credit for (defined as
`0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` above).

```sh
cast send --rpc-url $ETH_RPC_URL $CREDIT "approveCredit(address)" $RECEIVER_ADDR --private-key $PRIVATE_KEY
```

There also exists `approveCredit(address,address)` and `approveCredit(address,address,address[])`,
which inherently assumes a null value for the `limit` and `ttl` fields, and the order of the
addresses is `from`, `to`, and `caller` (for the latter variation). Here's an example using the
latter variation, effectively the same as the former due to the use of the zero address:

```sh
cast send --rpc-url $ETH_RPC_URL $CREDIT "approveCredit(address,address,address[])" $EVM_ADDRESS $RECEIVER_ADDR '[]' --private-key $PRIVATE_KEY
```

If, instead, we wanted to also restrict how the `to` can use the credit, we would set the `caller`
(e.g., a contract address at `0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc`):

```sh
cast send --rpc-url $ETH_RPC_URL $CREDIT "approveCredit(address,address,address[])" $EVM_ADDRESS $RECEIVER_ADDR '[0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc]' --private-key $PRIVATE_KEY
```

This would restrict the `to` to only be able to use the approved `from` address at the `caller`
address.

> [!NOTE] The `caller` can, in theory, be an EVM or WASM contract address. However, the logic
> assumes only an EVM address is provided. Namely, it is _generally_ possible to restrict the
> `caller` to a specific WASM contract (e.g., bucket with `t0...` prefix), but the current Solidity
> implementation does not account for this and only assumes an EVM address.

Lastly, if we want to include all of the optional fields, we can use the following command:

```sh
cast send --rpc-url $ETH_RPC_URL $CREDIT "approveCredit(address,address,address[],uint256,uint256,uint64)" $EVM_ADDRESS $RECEIVER_ADDR '[]' 100 100 3600 --private-key $PRIVATE_KEY
```

This includes the `creditLimit` field set to `100` credit, the `gasFeeLimit` set to `100` gas fee,
and the `ttl` set to `3600` seconds (`1` hour). If either of these should instead be null, just set
them to `0`.

##### Set credit sponsor for an address

```sh
cast send --rpc-url $ETH_RPC_URL $CREDIT "setCreditSponsor(address,address)" $EVM_ADDRESS $RECEIVER_ADDR --private-key $PRIVATE_KEY
```

This will set the credit sponsor for the `from` address to the `sponsor` address.

##### Revoke credit for an address

Revoking credit is the opposite of approving credit and also has a few variations. The simplest form
is revoking credit for the address defining in the call (`to`), which assumes the `msg.sender` is
the owner of the credit.

```sh
cast send --rpc-url $ETH_RPC_URL $CREDIT "revokeCredit(address)" $RECEIVER_ADDR --private-key $PRIVATE_KEY
```

The other variants are `revokeCredit(address,address)` and `revokeCredit(address,address,address)`.
Just like `approveCredit`, the order is: `from`, `to`, and `caller`. Here's an example using the
latter variation:

```sh
cast send --rpc-url $ETH_RPC_URL $CREDIT "revokeCredit(address,address,address)" $EVM_ADDRESS $RECEIVER_ADDR 0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc --private-key $PRIVATE_KEY
```

This would revoke the `to`'s ability to use the `from` address at the `caller` address.

### Buckets contract

You can interact with the existing buckets contract on the testnet via the address above. If you're
working on `localnet`, you'll have to deploy this yourself. Here's a quick one-liner to do so—also
setting the `BUCKETS` environment variable to the deployed address:

```
BUCKETS=$(forge script script/BucketManager.s.sol \
--tc DeployScript \
--sig 'run()' \
--rpc-url localnet_subnet \
--private-key $PRIVATE_KEY \
--broadcast \
-g 100000 \
| grep "0: contract BucketManager" | awk '{print $NF}')
```

#### Methods

The following methods are available on the credit contract, shown with their function signatures.

- `createBucket()`: Create a bucket for the sender.
- `createBucket(address)`: Create a bucket for the specified address.
- `createBucket(address,(string,string)[])`: Create a bucket for the specified address with
  metadata.
- `listBuckets()`: List all buckets for the sender.
- `listBuckets(address)`: List all buckets for the specified address.
- `addObject(address,string,string,string,uint64)`: Add an object to a bucket and associated object
  upload parameters. The first value is the bucket address, the subsequent values are all of the
  "required" values in `AddObjectParams` (`source` node ID, `key`, `blobHash`, and `size`).
- `addObject(address,(string,string,string,string,uint64,uint64,(string,string)[],bool))`: Add an
  object to a bucket (first value) and associated object upload parameters (second value) as the
  `AddObjectParams` struct, described in more detail below.
- `deleteObject(address,string)`: Remove an object from a bucket.
- `getObject(address,string)`: Get an object from a bucket.
- `queryObjects(address)`: Query the bucket (hex address) with no prefix (defaults to `/` delimiter
  and the default offset and limit in the underlying WASM layer).
- `queryObjects(address,string)`: Query the bucket with a prefix (e.g., `<prefix>/` string value),
  but no delimiter, offset, or limit.
- `queryObjects(address,string,string)`: Query the bucket with a custom delimiter (e.g., something
  besides the default `/` delimeter value), but default offset and limit.
- `queryObjects(address,string,string,uint64)`: Query the bucket with a prefix and delimiter, but no
  limit.
- `queryObjects(address,string,string,uint64,uint64)`: Query the bucket with a prefix, delimiter,
  offset, and limit.

#### Examples

Make sure you've already set the `PRIVATE_KEY`, `EVM_ADDRESS`, and `ETH_RPC_URL` environment
variables. Then, define a `BUCKETS` environment variable, which points to the bucket contract
deployment address. For example:

```sh
export BUCKETS=0x314512a8692245cf507ac6E9d0eB805EA820d9a8
```

The account you use to create buckets should have the following:

- A HOKU token balance in the subnet (e.g., from the faucet at:
  [https://faucet.hoku.sh](https://faucet.hoku.sh)). You can verify this with the
  [Hoku CLI](https://github.com/hokunet/rust-hoku): `hoku account info`
- A credit balance in the subnet. You can verify this with `hoku credit balance`. If you don't have
  credits, you can buy them with the Credits contract above, or run the `hoku credit buy <amount>`
  command.

Creating a bucket will cost native HOKU tokens, and writing to it will cost credit.

##### Create a bucket

To create a bucket, you can use the following command:

```sh
cast send --rpc-url $ETH_RPC_URL $BUCKETS "createBucket(address)" $EVM_ADDRESS --private-key $PRIVATE_KEY
```

This will execute an onchain transaction to create a bucket for the provided address. Alternatively,
you can create a bucket for the sender with the following command:

```sh
cast send --rpc-url $ETH_RPC_URL $BUCKETS "createBucket()" --private-key $PRIVATE_KEY
```

To create a bucket with metadata, you can use the following command, where each metadata value is a
`KeyValue` (a pair of strings) within an array—something like `[("alias","foo")]`:

```sh
cast send --rpc-url $ETH_RPC_URL $BUCKETS "createBucket(address,(string,string)[])" $EVM_ADDRESS '[("alias","foo")]' --private-key $PRIVATE_KEY
```

##### List buckets

You can list buckets for a specific address with the following command. Note you can use the
overloaded `listBuckets()` to list buckets for the sender.

```sh
cast abi-decode "listBuckets(address)((uint8,address,(string,string)[])[])" $(cast call --rpc-url $ETH_RPC_URL $BUCKETS "listBuckets(address)" $EVM_ADDRESS)
```

This will return the following output:

```
(0, 0xff000000000000000000000000000000000000ed, [("foo", "bar")])
```

Which maps to an array of the `Machine` struct:

```solidity
struct Machine {
    Kind kind; // See `Kind` struct below
    address addr; // 0xff000000000000000000000000000000000000ed
    KeyValue[] metadata; // See `KeyValue` struct below
}

struct Kind {
    Bucket, // 0 == `Bucket`
    Timehub, // 1 == `Timehub`
}

struct KeyValue {
    string key; // "foo"
    string value; // "bar"
}
```

##### Add an object

Given a bucket address, you can read or mutate the objects in the bucket. First, we'll simply add an
object, setting `BUCKET_ADDR` to an existing bucket from the command above:

```sh
export BUCKET_ADDR=0xff0000000000000000000000000000000000008f
```

Adding an object is a bit involved. You need to stage data offchain to a `source` bucket storage
node ID address, which will return the hashed value (`blobHash`) of the staged data and its
corresponding `size` in bytes. You then pass all of these as parameters when you add an object to
the bucket.

In the example below, we've already staged this data offchain and are using the following:

- `source`: The node ID address (e.g., `cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq`).
- `blobHash`: The hash of the staged data (e.g.,
  `rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq` is the base32 encoded blake3 hashed value
  of our file contents, which contains the string `hello`).
- `recoveryHash`: Blake3 hash of the metadata to use for object recovery (note: this is currently
  hardcoded, so you can pass an empty string value here).
- `size`: The size of the data in bytes (e.g., `6`, which is the number of bytes in the `hello`
  string).

We also include custom parameters for the bucket key, metadata, TTL, and overwrite flag:

- `key`: The key to assign to the object in the bucket (`hello/world`).
- `metadata`: The metadata to assign to the object in the bucket (`[("foo","bar")]`).
- `overwrite`: The overwrite flag to assign to the object in the bucket (`false`).

This all gets passed as a single `AddObjectParams` struct to the `add` method:

```solidity
struct AddObjectParams {
    string source; // cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq
    string key; // hello/world
    string blobHash; // rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq
    string recoveryHash; // (note: this is currently hardcoded to an empty string)
    uint64 size; // 6
    uint64 ttl; // 0 (which is interpreted as null)
    KeyValue[] metadata; // [("foo","bar")]
    bool overwrite; // false
}
```

We then pass this as a single parameter to the `add` method:

```sh
cast send --rpc-url $ETH_RPC_URL $BUCKETS "addObject(string,(string,string,string,string,uint64,uint64,(string,string)[],bool))" $BUCKET_ADDR '("cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq","hello/world","rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq","",6,0,[("foo","bar")],false)' --private-key $PRIVATE_KEY
```

Alternatively, to use the overloaded `add` method that has default values for the `ttl`, `metadata`,
and `overwrite`, you can do the following:

```sh
cast send --rpc-url $ETH_RPC_URL $BUCKETS "addObject(string,string,string,string,string,uint64)" $BUCKET_ADDR "cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq" "hello/world" "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq" "" 6 --private-key $PRIVATE_KEY
```

If you're wondering where to get the `source` storage bucket's node ID (the example's
`cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq`), you can find it with a `curl` request. On
localnet, this looks like the following:

```sh
curl http://localhost:8001/v1/node | jq '.node_id'
```

Or on testnet, you'd replace the URL with public bucket API endpoint
`https://object-api-ignition-0.hoku.sh`.

##### Delete an object

Similar to [getting an object](#get-an-object), you can delete an object with the following command,
specifying the bucket and key for the mutating transaction:

```sh
cast send --rpc-url $ETH_RPC_URL $BUCKETS "deleteObject(address,string)" $BUCKET_ADDR "hello/world" --private-key $PRIVATE_KEY
```

##### Get an object

Getting a single object is similar to the response of `query`, except only a single object is
returned. Thus, the response simply includes a single value. The `BUCKET_ADDR` is the same one from
above.

```sh
cast abi-decode "getObject(address,string)((string,string,uint64,uint64,(string,string)[]))" $(cast call --rpc-url $ETH_RPC_URL $BUCKETS "getObject(address,string)" $BUCKET_ADDR "hello/world")
```

This will return the following response:

```sh
("rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq", "utiakbxaag7udhsriu6dm64cgr7bk4zahiudaaiwuk6rfv43r3rq", 6, 103381 [1.033e5], [("foo","bar")])
```

Which maps to the `Value` struct:

```solidity
struct ObjectValue {
    string blobHash; // "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq"
    string recoveryHash; // "utiakbxaag7udhsriu6dm64cgr7bk4zahiudaaiwuk6rfv43r3rq"
    uint64 size; // 6
    uint64 expiry; // 103381
    KeyValue[] metadata; // See `KeyValue` struct below
}

struct KeyValue {
    string key; // "foo"
    string value; // "bar"
}
```

#### Query objects

We'll continue using the same `BUCKET_ADDR` from the previous examples.

```sh
cast abi-decode "queryObjects(address)(((string,(string,uint64,(string,string)[]))[],string[],string))" $(cast call --rpc-url $ETH_RPC_URL $BUCKETS "queryObjects(address)" $BUCKET_ADDR)
```

This will return the following `Query` output:

```
([], ["hello/"], "")
```

Where the first array is an empty set of objects, and the second array is the common prefixes in the
bucket:

```solidity
struct Query {
    Object[] objects; // Empty array if no objects
    string[] commonPrefixes; // ["hello/"]
    string nextKey; // ""
}
```

In the next example, we'll set `PREFIX` to query objects with the prefix `hello/`:

```sh
export PREFIX="hello/"
```

Now, we can query for these objects with the following command:

```sh
cast abi-decode "queryObjects(address,string)(((string,(string,uint64,(string,string)[]))[],string[],string))" $(cast call --rpc-url $ETH_RPC_URL $BUCKETS "queryObjects(address,string)" $BUCKET_ADDR $PREFIX)
```

This will return the following `Query` output:

```
([("hello/world", ("rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq", 6, [("foo", "bar")]))], [], "")
```

Which maps to the following structs:

```solidity
struct Query {
    Object[] objects; // See `Object` struct below
    string[] commonPrefixes; // Empty array if no common prefixes
    string nextKey; // Null value (empty string `""`)
}

struct Object {
    string key; // "hello/world"
    ObjectState state; // See `ObjectState` struct below
}

struct ObjectState {
    string blobHash; // "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq"
    uint64 size; // 6
    KeyValue[] metadata; // See `KeyValue` struct below
}

struct KeyValue {
    string key; // "foo"
    string value; // "bar"
}
```

### Blobs contract

You can interact with the existing blobs contract on the testnet via the address above. If you're
working on `localnet`, you'll have to deploy this yourself. Here's a quick one-liner to do so—also
setting the `BLOBS` environment variable to the deployed address:

```
BLOBS=$(forge script script/BlobManager.s.sol \
--tc DeployScript \
--sig 'run()' \
--rpc-url localnet_subnet \
--private-key $PRIVATE_KEY \
--broadcast \
-g 100000 \
| grep "0: contract BlobManager" | awk '{print $NF}')
```

#### Methods

The following methods are available on the credit contract, shown with their function signatures.
Note that overloads are available for some methods, primarily, where the underlying WASM contract
accepts "optional" arguments. All of the method parameters and return types can be found in
`util/CreditTypes.sol`.

- `addBlob(AddBlobParams memory params)`: Store a blob directly on the network. This is described in
  more detail below, and it involves a two-step approach with first staging data with the blob
  storage node, and then passing related values onchain.
- `deleteBlob(address,string,string)`: Delete a blob from the network, passing the sponsor's
  address, the blob hash, and the subscription ID (either `""` if none was originally provided, or
  the string that was chosen during `addBlob`).
- `getAccountType(address)`: Get the account's max blob TTL.
- `getBlob(string)`: Get information about a specific blob at its blake3 hash.
- `getBlobStatus(address,string,string)`: Get a blob's status, providing its credit sponsor (i.e.,
  the account's `address`, or `address(0)` if null), its blake3 blob hash (the first `string`
  parameter), and its blob hash key (an empty string `""` to indicate the default, or the key used
  upon creating the blob).
- `getPendingBlobs()`: Get the values of pending blobs across the network.
- `getPendingBlobsCount(uint32)`: Get the number of pending blobs across the network, up to a limit.
- `getPendingBytesCount()`: Get the total number of pending bytes across the network.
- `getStorageStats()`: Get storage stats.
- `getStorageUsage(address)`: Get storage usage for an address.
- `getSubnetStats()`: Get subnet stats.

##### Add a blob

Adding a blob is a bit involved. You need to stage data offchain to a `source` blob storage node ID
address, which will return the hashed value (`blobHash`) of the staged data and its corresponding
`size` in bytes. You then pass all of these as parameters when you add an object to the bucket.

In the example below, we've already staged this data offchain and are using the following:

- `sponsor`: Optional sponsor address. E.g., if you have credits, you don't need to pass this, but
  if someone has approve for you to use credits, you can specify the credit sponsor here.
- `source`: The storage node ID address (e.g.,
  `cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq`).
- `blobHash`: The blake3 hash of the staged data (e.g.,
  `rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq` is the base32 encoded blake3 hashed value
  of our file contents, which contains the string `hello`).
- `metadataHash`: Blake3 hash of the metadata to use for blob recovery (hardcoded, so you can pass
  an empty string value here).
- `subscriptionId`: Identifier used to differentiate blob additions for the same subscriber. You can
  pass an empty string, indicating the default value (`Default`). Or, passing a string value, which
  under the hood, will use this key value (`Key(Vec<u8>)`) for the hashmap key.
- `size`: The size of the data in bytes (e.g., `6`, which is the number of bytes in the `hello`
  string).
- `ttl`: Blob time-to-live epochs. If specified as `0`, the auto-debitor maintains about one hour of
  credits as an ongoing commitment.

This all gets passed as a single `AddBlobParams` struct to the `addBlob` method:

```solidity
struct AddBlobParams {
    address sponsor; // `address(0)` for default/null, or the credit sponsor's address
    string source; // cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq
    string blobHash; // rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq
    string metadataHash; // (note: this is currently hardcoded to an empty string)
    string subscriptionId; // use `""` for the default, or pass a string value
    uint64 size; // 6
    uint64 ttl; // 0 (which is interpreted as null)
}
```

We then pass this as a single parameter to the `add` method:

```sh
cast send --rpc-url $ETH_RPC_URL $BLOBS "addBlob((address,string,string,string,string,uint64,uint64))" '(0x0000000000000000000000000000000000000000,"cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq","rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq","","",6,0)' --private-key $PRIVATE_KEY
```

To include a custom subscription ID, you would replace the empty string (which indicates `Default`)
in the call above, like so: `(...,"rzgh...","","my_custom_id",6,0)`.

If you're wondering where to get the `source` storage bucket's node ID (the example's
`cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq`), you can find it with a `curl` request. On
localnet, this looks like the following:

```sh
curl http://localhost:8001/v1/node | jq '.node_id'
```

Or on testnet, you'd replace the URL with public bucket API endpoint
`https://object-api-ignition-0.hoku.sh`.

###### Delete a blob

You can a delete a blob you've created with the following, passing the sponsor's address (zero
address if null), the blob's blake3 hash, and the subscription ID (either the default empty string
`""` or the string you passed during `addBlob`).

```sh
cast send --rpc-url $ETH_RPC_URL $BLOBS "deleteBlob(address,string,string)" 0x0000000000000000000000000000000000000000 "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq" "" --private-key $PRIVATE_KEY
```

This will emit a `DeleteBlob` event and delete the blob from the network.

##### Get account type

```sh
cast abi-decode "getAccountType(address)(uint64)" $(cast call --rpc-url $ETH_RPC_URL $BLOBS "getAccountType(address)" $EVM_ADDRESS)
```

This will return the account's max blob TTL:

```
86400
```

##### Get a blob

```sh
cast abi-decode "getBlob(string)((uint64,string,(string,(string,(uint64,uint64,string,address,bool))[])[],uint8))" $(cast call --rpc-url $ETH_RPC_URL $BLOBS "getBlob(string)" "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq")
```

This will return the following response:

```sh
(6, "utiakbxaag7udhsriu6dm64cgr7bk4zahiudaaiwuk6rfv43r3rq", [("f0124", [("foo", (4825, 91225 [9.122e4], "cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq", 0x0000000000000000000000000000000000000000, false))])], 2)
```

Which maps to the `Blob` struct:

```solidity
struct Blob {
    uint64 size; // 6
    string metadataHash; // "utiakbxaag7udhsriu6dm64cgr7bk4zahiudaaiwuk6rfv43r3rq"
    Subscriber[] subscribers; // See `Subscriber` struct below
    BlobStatus status; // 2 (Resolved)
}

struct Subscriber {
    string subscriber; // f0124
    SubscriptionGroup[] subscriptionGroup; // See `SubscriptionGroup` struct below
}

struct SubscriptionGroup {
    string subscriptionId; // "foo"
    Subscription subscription; // See `Subscription` struct below
}

struct Subscription {
    uint64 added; // 4825
    uint64 expiry; // 91225
    string source; // "cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq"
    address delegate; // 0x0000000000000000000000000000000000000000
    bool failed; // false
}
```

##### Get blob status

- Pass an address as the first field to represent the origin address that requested the blob.
- Provide the `blobHash` blake3 value.
- Also give the `subscriptionId`, which uses the default empty value if you provide an empty string
  `""`, or it can take the string that matches the blob's `subscriptionId` upon creation.

```sh
cast abi-decode "getBlobStatus(address,string,string)(uint8)" $(cast call --rpc-url $ETH_RPC_URL $BLOBS "getBlobStatus(address,string,string)" $EVM_ADDRESS "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq" "")
```

This will return the following response (either a `0` for `Added`, `1` for `Pending`, `2` for
`Resolved`, or `3` for `Failed`):

```sh
2
```

Which maps to the `BlobStatus` enum:

```solidity
enum BlobStatus {
    Added, // 0
    Pending, // 1
    Resolved, // 2 -- the value above
    Failed // 3
}
```

##### Get added blobs

```sh
cast abi-decode "getAddedBlobs(uint32)((string,(address,string,string)[])[])" $(cast call --rpc-url $ETH_RPC_URL $BLOBS "getAddedBlobs(uint32)" 1)
```

This returns the values of added blobs, up to the `size` passed as the parameter:

```sh
[("rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq", [(0x90F79bf6EB2c4f870365E785982E1f101E93b906, "Default", "cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq")])]
```

Which maps to an array of the `BlobTuple` struct:

```solidity
struct BlobTuple {
    string blobHash; // "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq"
    BlobSourceInfo[] sourceInfo; // See `Subscriber` struct below
}

struct BlobSourceInfo {
    address subscriber; // 0x90F79bf6EB2c4f870365E785982E1f101E93b906
    string subscriptionId; // "Default"
    string source; // "cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq"
}
```

##### Get pending blobs

```sh
cast abi-decode "getPendingBlobs(uint32)((string,(address,string,string)[])[])" $(cast call --rpc-url $ETH_RPC_URL $BLOBS "getPendingBlobs(uint32)" 1)
```

This returns the values of pending blobs, up to the `size` passed as the parameter:

```sh
[("rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq", [(0x90F79bf6EB2c4f870365E785982E1f101E93b906, "Default", "cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq")])]
```

Which maps to an array of the `BlobTuple` struct:

```solidity
struct BlobTuple {
    string blobHash; // "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq"
    BlobSourceInfo[] sourceInfo; // See `Subscriber` struct below
}

struct BlobSourceInfo {
    address subscriber; // 0x90F79bf6EB2c4f870365E785982E1f101E93b906
    string subscriptionId; // "Default"
    string source; // "cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq"
}
```

##### Get pending blobs count

```sh
cast abi-decode "getPendingBlobsCount()(uint64)" $(cast call --rpc-url $ETH_RPC_URL $BLOBS "getPendingBlobsCount()")
```

This returns the number of pending blobs:

```sh
123
```

##### Get pending bytes count

```sh
cast abi-decode "getPendingBytesCount()(uint64)" $(cast call --rpc-url $ETH_RPC_URL $BLOBS "getPendingBytesCount()")
```

This returns the total number of bytes that are pending network resolution:

```sh
987654321
```

##### Get subnet stats

We can fetch the overall subnet stats with the following command:

```sh
cast abi-decode "getSubnetStats()((uint256,uint64,uint64,uint256,uint256,uint256,uint256,uint64,uint64,uint64,uint64,uint64,uint64))" $(cast call --rpc-url $ETH_RPC_URL $BLOBS "getSubnetStats()")
```

This will return the following values:

```
(50000999980767329202072 [5e22], 10995116277754 [1.099e13], 6, 50001000000000000000000000000000000000000 [5e40], 1002060000000000000000000 [1.002e24], 62064000000000000000000 [6.206e22], 1000000000000000000000000000000000000 [1e36], 10, 1, 0, 0, 0, 0)
```

Which maps to the `SubnetStats` struct:

```solidity
struct SubnetStats {
    uint256 balance; // 50000000000000000000000
    uint64 capacityFree; // 10995116277754
    uint64 capacityUsed; // 6
    uint256 creditSold; // 50001000000000000000000
    uint256 creditCommitted; // 21156
    uint256 creditDebited; // 25349384457000
    uint256 tokenCreditRate; // 1000000000000000000000000000000000000
    uint64 numAccounts; // 10
    uint64 numBlobs; // 1
    uint64 numResolving; // 0
    uint64 bytesResolving; // 0
    uint64 numAdded; // 0
    uint64 bytesAdded; // 0
}
```

##### Get storage stats

We can fetch the overall storage stats for the subnet with the following command:

```sh
cast abi-decode "getStorageStats()((uint64,uint64,uint64,uint64,uint64,uint64,uint64,uint64))" $(cast call --rpc-url $ETH_RPC_URL $BLOBS "getStorageStats()")
```

This will return the following values:

```
(10995116277754 [1.099e13], 6, 1, 0, 10, 0, 0, 0)
```

Which maps to the `StorageStats` struct:

```solidity
struct StorageStats {
    uint64 capacityFree; // 10995116277754
    uint64 capacityUsed; // 6
    uint64 numBlobs; // 1
    uint64 numResolving; // 0
    uint64 numAccounts; // 10
    uint64 bytesResolving; // 0
    uint64 numAdded; // 0
    uint64 bytesAdded; // 0
}
```

##### Get storage usage for an account

Fetch the storage usage for the address at `EVM_ADDRESS`:

```sh
cast abi-decode "getStorageUsage(address)(uint256)" $(cast call --rpc-url $ETH_RPC_URL $BLOBS "getStorageUsage(address)" $EVM_ADDRESS)
```

This will return the following values:

```
123
```

### Testing

You can run all of the unit tests with the following command:

```sh
forge test
```

Or run a specific test in the `test` directory:

```sh
forge test --match-path test/LibWasm.t.sol
```

For the wrapper contracts, an naive "integration" test is provided in
`test/scripts/wrapper_integration_test.sh`. This assumes you have the localnet running, and it
deploys the contracts and runs through all of the methods described above via `cast`. You can run it
with the following command:

```sh
test/scripts/wrapper_integration_test.sh
```

If everything is working, you should see `All tests completed successfully` logged at the end. But,
if there's an error (i.e., incompatability with the wrappers relative to the subnet's expectation),
the script will exit early.
