# Hoku Contracts

[![License](https://img.shields.io/github/license/hokunet/contracts.svg)](./LICENSE)
[![standard-readme compliant](https://img.shields.io/badge/standard--readme-OK-green.svg)](https://github.com/RichardLitt/standard-readme)

> Hoku core Solidity contracts and libraries

## Background

This project is built with [Foundry](https://book.getfoundry.sh/) and contains the core contracts
for Hoku. It includes the following:

- `Hoku.sol`: An ERC20 token implementation.
- `Faucet.sol`: The accompanying onchain faucet (rate limiter) contract for dripping testnet funds.
- `Credit.sol`: Manage subnet credit, including credit purchases, approvals/rejections, and related
  read-only operations (uses the `LibCredit` and `LibWasm` libraries).
- `interfaces/ICredit.sol`: The interface for the credit contract.
- `types/`: Various method parameters and return types for core contracts.
- `utils/LibCredit.sol`: A library for interacting with credits, wrapped by the `Credit` contract.
- `utils/LibWasm.sol`: A library for facilitating proxy calls to WASM contracts from Solidity.
- `utils/solidity-cbor`: Libraries for encoding and decoding CBOR data, used in proxy WASM calls
  (forked from [this repo](https://github.com/smartcontractkit/solidity-cborutils)).

### Deployments

The following contracts are deployed in the testnet environment (Filecoin Calibration or the Hoku
subnet):

| Contract     | Chain       | Address                                      |
| ------------ | ----------- | -------------------------------------------- |
| Hoku (ERC20) | Calibration | `0x8e3Fd2b47e564E7D636Fa80082f286eD038BE54b` |
| Faucet       | Subnet      | `0xA089Efd61db801B27077257b9EB4E95C3b8aD90F` |
| Credit       | Subnet      | `0x31D31BF66Ed7526c8B44fAa057d68049C18197a7` |

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
forge install
forge build
```

### Deploying contracts

The scripts for deploying contracts are in `script/` directory:

- `Credit.s.sol`: Deploy the credit contract.
- `Hoku.s.sol`: Deploy the Hoku ERC20 contract.
- `Faucet.s.sol`: Deploy the faucet contract.

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
environment:

- `0`: Local (for either localnet or devnet)
- `1`: Testnet
- `2`: Mainnet (note: mainnet is not available yet)

Lastly, all scripts use the `--sig` flag with `run(uint8)` (or `run(uint8,uint256)` for the faucet)
to execute deployment with the given argument above, and the `--broadcast` flag actually sends the
transaction to the network. Recall that you **must** set `-g 100000` to ensure the gas estimate is
sufficiently high.

#### Localnet

Deploy the Hoku ERC20 contract to the localnet parent chain. Note the `-g` flag is not used here
since the gas estimate is sufficiently low on Anvil.

```shell
PRIVATE_KEY=<0x...> forge script script/Hoku.s.sol --tc DeployScript 0 --sig 'run(uint8)' --rpc-url localnet_parent --broadcast -vv
```

Deploy the Faucet contract to the localnet subnet. The second argument is the initial supply of Hoku
tokens, owned by the deployer's account which will be transferred to the faucet contract (e.g., 5000
with 10\*\*18 decimal units).

```shell
PRIVATE_KEY=<0x...> forge script script/Faucet.s.sol --tc DeployScript 0 5000000000000000000000 --sig 'run(uint8,uint256)' --rpc-url localnet_subnet --broadcast -g 100000 -vv
```

Deploy the Credit contract to the localnet subnet:

```shell
PRIVATE_KEY=<0x...> forge script script/Credit.s.sol --tc DeployScript 0 --sig 'run(uint8)' --rpc-url localnet_subnet --broadcast -g 100000 -vv
```

#### Testnet

Deploy the Hoku ERC20 contract to the testnet parent chain. Note the `-g` flag _is_ used here (this
differs from the localnet setup above since we're deploying to Filecoin Calibration);

```shell
PRIVATE_KEY=<0x...> forge script script/Hoku.s.sol --tc DeployScript 1 --sig 'run(uint8)' --rpc-url testnet_parent --broadcast -g 100000 -vv
```

Deploy the Faucet contract to the testnet subnet.The second argument is the initial supply of Hoku
tokens, owned by the deployer's account which will be transferred to the faucet contract (e.g., 5000
with 10\*\*18 decimal units).

```shell
PRIVATE_KEY=<0x...> forge script script/Faucet.s.sol --tc DeployScript 1 5000000000000000000000 --sig 'run(uint8,uint256)'--rpc-url testnet_subnet --broadcast -g 100000 -vv
```

Deploy the Credit contract to the testnet subnet:

```shell
PRIVATE_KEY=<0x...> forge script script/Credit.s.sol --tc DeployScript 1 --sig 'run(uint8)' --rpc-url testnet_subnet --broadcast -g 100000 -vv
```

#### Devnet

The devnet does not have the concept of a "parent" chain, so all RPCs would use `--rpc-url devnet`.

#### Mainnet

Mainnet is not yet available. The RPC URLs (`mainnet_parent` and `mainnet_subnet`) are placeholders,
pointing to the same environment as the testnet.

## Development

### Credit contract

You can interact with the existing credit contract on the testnet via the address above. If you're
working on `localnet`, you'll have to deploy this yourself. Here's a quick one-liner to do so—also
setting the `CREDIT` environment variable to the deployed address:

```
CREDIT=$(PRIVATE_KEY=$PRIVATE_KEY forge script script/Credit.s.sol \
--tc DeployScript 0 \
--sig 'run(uint8)' \
--rpc-url localnet_subnet \
--broadcast -g 100000 | grep "0: contract Credit" | awk '{print $NF}')
```

#### Methods

The following methods are available on the credit contract, shown with their function signatures.
Note that overloads are available for some methods, primarily, where the underlying WASM contract
accepts "optional" arguments. All of the method parameters and return types can be found in
`util/Types.sol`.

- `getSubnetStats()`: Get subnet stats.
- `getCreditStats()`: Get credit stats.
- `getStorageStats()`: Get credit stats.
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

We'll set a few environment variables to demonstrate the examples below. We'll first set the
`PRIVATE_KEY` to the hex-encoded private key (same as with the deployment scripts above), and an
arbitrary `EVM_ADDRESS` that is the public key of this private key.

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

We'll define a `CREDIT` environment variable, which points to the credit contract deployment
address. For example:

```sh
export CREDIT=0x138E3aFeb7dC8944d464326cb2ff2b429cdA808b
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
cast send --rpc-url $EVM_RPC_URL $CREDIT "buyCredit()" $EVM_ADDRESS --value 1ether --private-key $PRIVATE_KEY
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
> `requiredCaller` to a specific WASM contract (e.g., object store with `t2...` prefix), but the
> current Solidity implementation does not account for this and only assumes an EVM address.

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
