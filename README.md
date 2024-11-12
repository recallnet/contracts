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

## Background

This project is built with [Foundry](https://book.getfoundry.sh/) and contains the core contracts
for Hoku. It includes the following:

- `Hoku.sol`: An ERC20 token implementation.
- `Faucet.sol`: The accompanying onchain faucet (rate limiter) contract for dripping testnet funds.
- `Credit.sol`: Manage subnet credit, including credit purchases, approvals/rejections, and related
  read-only operations (uses the `LibCredit` and `LibWasm` libraries).
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

| Contract      | Chain       | Address                                      |
| ------------- | ----------- | -------------------------------------------- |
| Hoku (ERC20)  | Calibration | `0x8e3Fd2b47e564E7D636Fa80082f286eD038BE54b` |
| Faucet        | Subnet      | `0x10bc34a0C11E5e51774833603955CB7Ec3c79AC6` |
| Credit        | Subnet      | `0x8c2e3e8ba0d6084786d60A6600e832E8df84846C` |
| BucketManager | Subnet      | `0x4c74c78B3698cA00473f12eF517D21C65461305F` |
| LibCredit     | Subnet      | `0xfF73c2705B8b77a832c7ec33864B8BEF201002E1` |

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
- `Credit.s.sol`: Deploy the credit contract.
- `BucketManager.s.sol`: Deploy the Bucket Manager contract.
- `Bridge.s.sol`: Deploy the bridge contract—relevant for the Hoku ERC20 on live chains.

> [!NOTE] If you're deploying _to_ the Hoku subnet or Filecoin Calibration, you'll need to
> (significantly) bump the gas estimation multiplier by adding a `-g 100000` flag to the
> `forge script` command.

Each script expects the `PRIVATE_KEY` (hex prefixed) private key of the account to deploy the
contract:

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
PRIVATE_KEY=<0x...> forge script script/Hoku.s.sol --tc DeployScript --sig 'run(string)' local --rpc-url localnet_parent --broadcast -vv
```

##### Faucet

Deploy the Faucet contract to the localnet subnet. The second argument is the initial supply of Hoku
tokens, owned by the deployer's account which will be transferred to the faucet contract (e.g., 5000
with 10\*\*18 decimal units).

```shell
PRIVATE_KEY=<0x...> forge script script/Faucet.s.sol --tc DeployScript --sig 'run(string,uint256)' local 5000000000000000000000 --rpc-url localnet_subnet --broadcast -g 100000 -vv
```

##### Credit

Deploy the Credit contract to the localnet subnet:

```shell
PRIVATE_KEY=<0x...> forge script script/Credit.s.sol --tc DeployScript --sig 'run(string)' local --rpc-url localnet_subnet --broadcast -g 100000 -vv
```

##### Buckets

Deploy the Bucket Manager contract to the localnet subnet:

```shell
PRIVATE_KEY=<0x...> forge script script/BucketManager.s.sol --tc DeployScript --sig 'run(string)' local --rpc-url localnet_subnet --broadcast -g 100000 -vv
```

#### Testnet

##### Hoku ERC20

Deploy the Hoku ERC20 contract to the testnet parent chain. Note the `-g` flag _is_ used here (this
differs from the localnet setup above since we're deploying to Filecoin Calibration);

```shell
PRIVATE_KEY=<0x...> forge script script/Hoku.s.sol --tc DeployScript --sig 'run(string)' testnet --rpc-url testnet_parent --broadcast -g 100000 -vv
```

##### Faucet

Deploy the Faucet contract to the testnet subnet. The second argument is the initial supply of Hoku
tokens, owned by the deployer's account which will be transferred to the faucet contract (e.g., 5000
with 10\*\*18 decimal units).

```shell
PRIVATE_KEY=<0x...> forge script script/Faucet.s.sol --tc DeployScript --sig 'run(string,uint256)' testnet 5000000000000000000000 --rpc-url testnet_subnet --broadcast -g 100000 -vv
```

##### Credit

Deploy the Credit contract to the testnet subnet:

```shell
PRIVATE_KEY=<0x...> forge script script/Credit.s.sol --tc DeployScript --sig 'run(string)' testnet --rpc-url testnet_subnet --broadcast -g 100000 -vv
```

##### Buckets

Deploy the Bucket Manager contract to the testnet subnet:

```shell
PRIVATE_KEY=<0x...> forge script script/BucketManager.s.sol --tc DeployScript --sig 'run(string)' testnet --rpc-url testnet_subnet --broadcast -g 100000 -vv
```

#### Devnet

The devnet does not have the concept of a "parent" chain, so all RPCs would use `--rpc-url devnet`
and follow the same pattern as the deployments above.

If you're trying to simply deploy to an Anvil node (i.e., `http://localhost:8545`), you can use the
same pattern, or just explicitly set the RPC URL:

```shell
PRIVATE_KEY=<0x...> forge script script/Hoku.s.sol --tc DeployScript --sig 'run(string)' local --rpc-url http://localhost:8545 --broadcast -vv
```

#### Mainnet

Mainnet is not yet available. The RPC URLs (`mainnet_parent` and `mainnet_subnet`) are placeholders,
pointing to the same environment as the testnet.

##### Hoku ERC20

However, if you'd like to deploy the HOKU ERC20 contract to mainnet Ethereum or Filecoin, you can
use the following. Note these will enable behavior for the Axelar Interchain Token Service.

Deploy to Ethereum:

```shell
PRIVATE_KEY=<0x...> forge script script/Hoku.s.sol:DeployScript --sig 'run(string)' ethereum --broadcast -vv --rpc-url https://eth.merkle.io
```

And for Filecoin:

```shell
PRIVATE_KEY=<0x...> forge script script/Hoku.s.sol:DeployScript --sig 'run(string)' filecoin --broadcast -vv -g 100000 --rpc-url https://api.node.glif.io/rpc/v1
```

## Development

## Scripts

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
`foundry.toml`. For simplicity sake, we'll define an environment variable `EVM_RPC_URL` set to one
of these RPC URLs so these examples can be run as-is:

```sh
export EVM_RPC_URL=testnet_subnet
```

The subsequent sections will define other environment variables as needed.

### Credit contract

You can interact with the existing credit contract on the testnet via the address above. If you're
working on `localnet`, you'll have to deploy this yourself. Here's a quick one-liner to do so—also
setting the `CREDIT` environment variable to the deployed address:

```
CREDIT=$(PRIVATE_KEY=$PRIVATE_KEY forge script script/Credit.s.sol \
--tc DeployScript \
--sig 'run(string)' local \
--rpc-url localnet_subnet \
--broadcast -g 100000 \
| grep "0: contract Credit" | awk '{print $NF}')
```

#### Methods

The following methods are available on the credit contract, shown with their function signatures.
Note that overloads are available for some methods, primarily, where the underlying WASM contract
accepts "optional" arguments. All of the method parameters and return types can be found in
`util/Types.sol`.

- `getSubnetStats()`: Get subnet stats.
- `getCreditStats()`: Get credit stats.
- `getStorageStats()`: Get storage stats.
- `getAccount(address)`: Get credit account info for an address.
- `getCreditBalance(address)`: Get credit balance for an address.
- `getStorageUsage(address)`: Get storage usage for an address.
- `buyCredit()`: Buy credit for the `msg.sender`.
- `buyCredit(address)`: Buy credit for the given address.
- `approveCredit(address)`: Approve credit for an address (`receiver`), assuming `msg.sender` is the
  owner of the credit (inferred as `from` in underlying logic).
- `approveCredit(address,address)`: Approve credit for the credit owner (`from`) for an address
  (`receiver`). Effectively, the same as `approveCredit(address)` but explicitly sets the `from`
  address.
- `approveCredit(address,address,address)`: Approve credit for the credit owner (`from`) for an
  address (`receiver`), with a restriction on the caller address (`requiredCaller`) (e.g., enforce
  receiver can only use credit at `requiredCaller`).
- `approveCredit(address,address,address,uint256)`: Approve credit for the credit owner (`from`) for
  an address (`receiver`), with a restriction on the caller address (`requiredCaller`), also
  providing the `limit` field.
- `approveCredit(address,address,address,uint256,uint64)`: Approve credit for the credit owner
  (`from`) for an address (`receiver`), providing all of the optional fields (`requiredCaller`,
  `limit`, and `ttl`).
- `revokeCredit(address)`: Revoke credit for an address (`receiver`), assuming `msg.sender` is the
  owner of the credit (inferred as `from` in underlying logic).
- `revokeCredit(address,address)`: Revoke credit for the credit owner (`from`) for an address
  (`receiver`). Effectively, the same as `approveCredit(address)` but explicitly sets the `from`
  address.
- `revokeCredit(address,address,address)`: Revoke credit for the credit owner (`from`) for an
  address (`receiver`), with a restriction on the caller address (`requiredCaller`) (e.g., remove
  permissions for `receiver` at `requiredCaller`).

The overloads above have a bit of nuance when it comes to "optional" arguments. See the `ICredit`
interface in `interfaces/ICredit.sol` for more details. For example, zero values are interpreted as
null values when encoded in WASM calls.

#### Examples

Make sure you've already set the `PRIVATE_KEY`, `EVM_ADDRESS`, and `EVM_RPC_URL` environment
variables. Then, define a `CREDIT` environment variable, which points to the credit contract
deployment address. For example:

```sh
export CREDIT=0x8c2e3e8ba0d6084786d60A6600e832E8df84846C
```

And lastly, we'll define a `RECEIVER_ADDR` environment variable, which points to the receiver
address we'll be approving and revoking credit for. For example:

```sh
export RECEIVER_ADDR=0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
```

##### Get subnet stats

We can fetch the overall subnet stats with the following command:

```sh
cast abi-decode "getSubnetStats()((uint256,uint256,uint256,uint256,uint256,uint256,uint64,uint64,uint64,uint64))" $(cast call --rpc-url $EVM_RPC_URL $CREDIT "getSubnetStats()")
```

This will return the following values:

```
(50000000000000000000000 [5e22], 4294967296 [4.294e9], 0, 50000000000000000000000 [5e22], 0, 0, 1, 10, 0, 0)
```

Which maps to the `SubnetStats` struct:

```solidity
struct SubnetStats {
    uint256 balance; // 50000000000000000000000
    uint256 capacityFree; // 4294967296
    uint256 capacityUsed; // 0
    uint256 creditSold; // 50000000000000000000000
    uint256 creditCommitted; // 0
    uint256 creditDebited; // 0
    uint64 creditDebitRate; // 1
    uint64 numAccounts; // 10
    uint64 numBlobs; // 0
    uint64 numResolving; // 0
}
```

##### Get credit stats

We can fetch the overall credit stats for the subnet with the following command:

```sh
cast abi-decode "getCreditStats()((uint256,uint256,uint256,uint256,uint64,uint64))" $(cast call --rpc-url $EVM_RPC_URL $CREDIT "getCreditStats()")
```

This will return the following values:

```
(50000000000000000000000 [5e22], 50000000000000000000000 [5e22], 0, 0, 1, 10)
```

Which maps to the `CreditStats` struct:

```solidity
struct CreditStats {
    uint256 balance; // 50000000000000000000000
    uint256 creditSold; // 50000000000000000000000
    uint256 creditCommitted; // 0
    uint256 creditDebited; // 0
    uint64 creditDebitRate; // 1
    uint64 numAccounts; // 10
}
```

##### Get storage stats

We can fetch the overall storage stats for the subnet with the following command:

```sh
cast abi-decode "getStorageStats()((uint256,uint256,uint64,uint64))" $(cast call --rpc-url $EVM_RPC_URL $CREDIT "getStorageStats()")
```

This will return the following values:

```
(4294967296 [4.294e9], 0, 0, 0)
```

Which maps to the `StorageStats` struct:

```solidity
StorageStats {
    uint256 capacityFree; // 4294967296
    uint256 capacityUsed; // 0
    uint64 numBlobs; // 0
    uint64 numResolving; // 0
}
```

##### Get credit account info

We can get the credit account info for the address at `EVM_ADDRESS` (the variable we set above), or
you could provide any account's EVM public key that exists in the subnet.

```solidity
cast abi-decode "getAccount(address)((uint256,uint256,uint256,uint64,(address,(address,(uint256,uint256,uint64))[])[]))" $(cast call --rpc-url $EVM_RPC_URL $CREDIT "getAccount(address)" $EVM_ADDRESS)
```

This will return the following values:

```
(0, 5000000000000000000000 [5e21], 0, 17701 [1.77e4], [(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65, [(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65, (0, 0, 0))])])
```

Which maps to the `Account` struct:

```solidity
struct Account {
    uint256 capacityUsed; // 0
    uint256 creditFree; // 5000000000000000000000
    uint256 creditCommitted; // 0
    uint64 lastDebitEpoch; // 17701 [1.77e4]
    Approvals[] approvals; // [(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65, [(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65, (0, 0, 0))])]
}
```

The `approvals` array is empty if no approvals have been made. However, our example _does_ have
approvals authorized. We can expand this to be interpreted as the following:

```solidity
struct Approvals {
    address receiver; // 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
    Approval[] approval; // See Approval struct below
}

struct Approval {
    address requiredCaller; // 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
    CreditApproval approval; // See CreditApproval struct below
}

struct CreditApproval {
    uint256 limit; // 0
    uint64 expiry; // 0
    uint256 committed; // 0
}
```

Due to intricacies with optional arguments in WASM being used in Solidity, you can interpret zero
values as null values in the structs above. That is, the example address has no restrictions on the
`limit` or `expiry` with using the delegated/approved credit from the owner's account.

##### Get credit balance for an account

Fetch the credit balance for the address at `EVM_ADDRESS`:

```sh
cast abi-decode "getCreditBalance(address)((uint256,uint256,uint64))" $(cast call --rpc-url $EVM_RPC_URL $CREDIT "getCreditBalance(address)" $EVM_ADDRESS)
```

This will return the following values:

```
(5000000000000000000000 [5e21], 0, 18061 [1.806e4])
```

Which maps to the `Balance` struct:

```solidity
struct Balance {
    uint256 creditFree; // 5000000000000000000000
    uint256 creditCommitted; // 0
    uint64 lastDebitEpoch; // 18061
}
```

##### Get storage usage for an account

Fetch the storage usage for the address at `EVM_ADDRESS`:

```sh
cast abi-decode "getStorageUsage(address)((uint256))" $(cast call --rpc-url $EVM_RPC_URL $CREDIT "getStorageUsage(address)" $EVM_ADDRESS)
```

This will return the following values:

```
(0)
```

Which maps to the `Usage` struct:

```solidity
struct Usage {
    uint256 capacityUsed; // 0
}
```

##### Buy credit for an address

You can buy credit for your address with the following command, which will buy credit equivalent to
1 native subnet token (via `msg.value`) for the `msg.sender`:

```sh
cast send --rpc-url $EVM_RPC_URL $CREDIT "buyCredit()" --value 1ether --private-key $PRIVATE_KEY
```

Or, you can buy credit for a specific EVM address with the following command:

```sh
cast send --rpc-url $EVM_RPC_URL $CREDIT "buyCredit(address)" $EVM_ADDRESS --value 1ether --private-key $PRIVATE_KEY
```

##### Approve credit for an address

Approving credit has a few variations. The first variation is approving credit for the address
defined in the call, assuming the `msg.sender` is the owner of the credit. The `RECEIVER_ADDR`
address is the `receiver` we want to approve credit for (defined as
`0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65` above).

```sh
cast send --rpc-url $EVM_RPC_URL $CREDIT "approveCredit(address)" $RECEIVER_ADDR --private-key $PRIVATE_KEY
```

There also exists `approveCredit(address,address)` and `approveCredit(address,address,address)`,
which inherently assumes a null value for the `limit` and `ttl` fields, and the order of the
addresses is `from`, `receiver`, and `requiredCaller` (for the latter variation). Here's an example
using the latter variation, effectively the same as the former due to the use of the zero address:

```sh
cast send --rpc-url $EVM_RPC_URL $CREDIT "approveCredit(address,address,address)" $EVM_ADDRESS $RECEIVER_ADDR 0x0000000000000000000000000000000000000000 --private-key $PRIVATE_KEY
```

If, instead, we wanted to also restrict how the `receiver` can use the credit, we would set the
`requiredCaller` (e.g., a contract address at `0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc`):

```sh
cast send --rpc-url $EVM_RPC_URL $CREDIT "approveCredit(address,address,address)" $EVM_ADDRESS $RECEIVER_ADDR 0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc --private-key $PRIVATE_KEY
```

This would restrict the `receiver` to only be able to use the approved `from` address at the
`requiredCaller` address.

> [!NOTE] The `requiredCaller` can, in theory, be an EVM or WASM contract address. However, the
> logic assumes only an EVM address is provided. Namely, it is _generally_ possible to restrict the
> `requiredCaller` to a specific WASM contract (e.g., bucket with `t2...` prefix), but the current
> Solidity implementation does not account for this and only assumes an EVM address.

Lastly, if we want to include all of the optional fields, we can use the following command:

```sh
cast send --rpc-url $EVM_RPC_URL $CREDIT "approveCredit(address,address,address,uint256,uint64)" $EVM_ADDRESS $RECEIVER_ADDR 0x0000000000000000000000000000000000000000 100 3600 --private-key $PRIVATE_KEY
```

This includes the `limit` field set to `100` credit, and the `ttl` set to `3600` seconds (`1` hour).
If either of these should instead be null, just set them to `0`.

##### Revoke credit for an address

Revoking credit is the opposite of approving credit and also has a few variations. The simplest form
is revoking credit for the address defining in the call (`receiver`), which assumes the `msg.sender`
is the owner of the credit.

```sh
cast send --rpc-url $EVM_RPC_URL $CREDIT "revokeCredit(address)" $RECEIVER_ADDR --private-key $PRIVATE_KEY
```

The other variants are `revokeCredit(address,address)` and `revokeCredit(address,address,address)`.
Just like `approveCredit`, the order is: `from`, `receiver`, and `requiredCaller`. Here's an example
using the latter variation:

```sh
cast send --rpc-url $EVM_RPC_URL $CREDIT "revokeCredit(address,address,address)" $EVM_ADDRESS $RECEIVER_ADDR 0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc --private-key $PRIVATE_KEY
```

This would revoke the `receiver`'s ability to use the `from` address at the `requiredCaller`
address.

### Buckets contract

You can interact with the existing buckets contract on the testnet via the address above. If you're
working on `localnet`, you'll have to deploy this yourself. Here's a quick one-liner to do so—also
setting the `BUCKETS` environment variable to the deployed address:

```
BUCKETS=$(PRIVATE_KEY=$PRIVATE_KEY forge script script/BucketManager.s.sol \
--tc DeployScript \
--sig 'run(string)' local \
--rpc-url localnet_subnet \
--broadcast -g 100000 \
| grep "0: contract Bucket" | awk '{print $NF}')
```

#### Methods

The following methods are available on the credit contract, shown with their function signatures.

- `create()`: Create a bucket for the sender.
- `create(address)`: Create a bucket for the specified address.
- `create(address,(string,string)[])`: Create a bucket for the specified address with metadata.
- `list()`: List all buckets for the sender.
- `list(address)`: List all buckets for the specified address.
- `add(string,string,string,string,uint64)`: Add an object to a bucket and associated object upload
  parameters. The first value is the bucket address, the subsequent values are all of the "required"
  values in `AddParams` (`source` node ID, `key`, `blobHash`, and `size`).
- `add(string,(string,string,string,string,uint64,uint64,(string,string)[],bool))`: Add an object to
  a bucket (first value) and associated object upload parameters (second value) as the `AddParams`
  struct, described in more detail below.
- `remove(string,string)`: Remove an object from a bucket.
- `get(string,string)`: Get an object from a bucket.
- `query(string)`: Query the bucket (`t2...` string address) with no prefix (defaults to `/`
  delimiter and the default offset and limit in the underlying WASM layer).
- `query(string,string)`: Query the bucket with a prefix (e.g., `<prefix>/` string value), but no
  delimiter, offset, or limit.
- `query(string,string,string)`: Query the bucket with a custom delimiter (e.g., something besides
  the default `/` delimeter value), but default offset and limit.
- `query(string,string,string,uint64)`: Query the bucket with a prefix and delimiter, but no limit.
- `query(string,string,string,uint64,uint64)`: Query the bucket with a prefix, delimiter, offset,
  and limit.

#### Examples

Make sure you've already set the `PRIVATE_KEY`, `EVM_ADDRESS`, and `EVM_RPC_URL` environment
variables. Then, define a `BUCKETS` environment variable, which points to the bucket contract
deployment address. For example:

```sh
export BUCKETS=0x4c74c78B3698cA00473f12eF517D21C65461305F
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
cast send --rpc-url $EVM_RPC_URL $BUCKETS "create(address)" $EVM_ADDRESS --private-key $PRIVATE_KEY
```

This will execute an onchain transaction to create a bucket for the provided address. Alternatively,
you can create a bucket for the sender with the following command:

```sh
cast send --rpc-url $EVM_RPC_URL $BUCKETS "create()" --private-key $PRIVATE_KEY
```

To create a bucket with metadata, you can use the following command, where each metadata value is a
`KeyValue` (a pair of strings) within an array—something like `[("alias","foo")]`:

```sh
cast send --rpc-url $EVM_RPC_URL $BUCKETS "create(address,(string,string)[])" $EVM_ADDRESS '[("alias","foo")]' --private-key $PRIVATE_KEY
```

##### List buckets

You can list buckets for a specific address with the following command. Note you can use the
overloaded `list()` to list buckets for the sender.

```sh
cast abi-decode "list(address)((uint8,string,(string,string)[])[])" $(cast call --rpc-url $EVM_RPC_URL $BUCKETS "list(address)" $EVM_ADDRESS)
```

This will return the following output:

```
(0, "t2pdadfrian5jrvtk2sulbc7uuyt5cnxmfdmet3ri", [("foo", "bar")])
```

Which maps to an array of the `Machine` struct:

```solidity
struct Machine {
    Kind kind; // See `Kind` struct below
    string address; // t2pdadfrian5jrvtk2sulbc7uuyt5cnxmfdmet3ri
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
export BUCKET_ADDR=t2pdadfrian5jrvtk2sulbc7uuyt5cnxmfdmet3ri
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

This all gets passed as a single `AddParams` struct to the `add` method:

```solidity
struct AddParams {
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
cast send --rpc-url $EVM_RPC_URL $BUCKETS "add(string,(string,string,string,string,uint64,uint64,(string,string)[],bool))" $BUCKET_ADDR '("cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq","hello/world","rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq","",6,0,[("foo","bar")],false)' --private-key $PRIVATE_KEY
```

Alternatively, to use the overloaded `add` method that has default values for the `ttl`, `metadata`,
and `overwrite`, you can do the following:

```sh
cast send --rpc-url $EVM_RPC_URL $BUCKETS "add(string,string,string,string,string,uint64)" $BUCKET_ADDR "cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq" "hello/world" "rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq" "" 6 --private-key $PRIVATE_KEY
```

If you're wondering where to get the `source` storage bucket's node ID (the example's
`cydkrslhbj4soqppzc66u6lzwxgjwgbhdlxmyeahytzqrh65qtjq`), you can find it with a `curl` request. On
localnet, this looks like the following:

```sh
curl http://localhost:8001/v1/node | jq '.node_id'
```

Or on testnet, you'd replace the URL with public bucket API endpoint
`https://object-api.n1.hoku.sh`.

##### Delete an object

Similar to [getting an object](#get-an-object), you can delete an object with the following command,
specifying the bucket and key for the mutating transaction:

```sh
cast send --rpc-url $EVM_RPC_URL $BUCKETS "remove(string,string)" $BUCKET_ADDR "hello/world" --private-key $PRIVATE_KEY
```

##### Get an object

Getting a single object is similar to the response of `query`, except only a single object is
returned. Thus, the response simply includes a single value. The `BUCKET_ADDR` is the same one from
above.

```sh
cast abi-decode "get(string,string)((string,string,uint64,uint64,(string,string)[]))" $(cast call --rpc-url $EVM_RPC_URL $BUCKETS "get(string,string)" $BUCKET_ADDR "hello/world")
```

This will the following response:

```sh
("rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq", "utiakbxaag7udhsriu6dm64cgr7bk4zahiudaaiwuk6rfv43r3rq", 6, 103381 [1.033e5], [("foo","bar")])
```

Which maps to the `Value` struct:

```solidity
struct Value {
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
cast abi-decode "query(string)(((string,(string,string,uint64,uint64,(string,string)[]))[],string[]))" $(cast call --rpc-url $EVM_RPC_URL $BUCKETS "query(string)" $BUCKET_ADDR)
```

This will return the following `Query` output:

```
([], ["hello/"])
```

Where the first array is an empty set of objects, and the second array is the common prefixes in the
bucket:

```solidity
struct Query {
    Object[] objects; // Empty array if no objects
    string[] commonPrefixes; // ["hello/"]
}
```

In the next example, we'll set `PREFIX` to query objects with the prefix `hello/`:

```sh
export PREFIX="hello/"
```

Now, we can query for these objects with the following command:

```sh
cast abi-decode "query(string,string)(((string,(string,string,uint64,uint64,(string,string)[]))[],string[]))" $(cast call --rpc-url $EVM_RPC_URL $BUCKETS "query(string,string)" $BUCKET_ADDR $PREFIX)
```

This will return the following `Query` output:

```
([("hello/world", ("rzghyg4z3p6vbz5jkgc75lk64fci7kieul65o6hk6xznx7lctkmq", "utiakbxaag7udhsriu6dm64cgr7bk4zahiudaaiwuk6rfv43r3rq", 6, 103381 [1.033e5], [("foo", "bar")]))], [])
```

Which maps to the following structs:

```solidity
struct Query {
    Object[] objects; // See `Object` struct below
    string[] commonPrefixes; // Empty array if no common prefixes
}

struct Object {
    string key; // "hello/world"
    Value value; // See `Value` struct below
}

struct Value {
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
