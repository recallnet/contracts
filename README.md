# Recall Contracts

[![License](https://img.shields.io/github/license/recallnet/contracts.svg)](./LICENSE)
[![standard-readme compliant](https://img.shields.io/badge/standard--readme-OK-green.svg)](https://github.com/RichardLitt/standard-readme)

> Recall core Solidity contracts and libraries

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
  - [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

## Background

This project is built with [Foundry](https://book.getfoundry.sh/) and contains the core contracts
for Recall. It includes the following:

- `Recall.sol`: An ERC20 token implementation.
- `Faucet.sol`: The accompanying onchain faucet (rate limiter) contract for dripping testnet funds.
- `ValidatorGater.sol`: A contract for managing validator access.
- `interfaces/facades/`: The interfaces for facades, which handle bucket, blob, and credit
  operations.
- `types/`: Various method parameters and return types for core contracts.
- `utils/LibWasm.sol`: A library for facilitating proxy calls to WASM contracts from Solidity.
- `utils/solidity-cbor`: Libraries for encoding and decoding CBOR data, used in proxy WASM calls
  (forked from [this repo](https://github.com/smartcontractkit/solidity-cborutils)).
- `utils/Base32.sol`: Utilities for encoding and decoding base32.
- `utils/Blake2b.sol`: Utilities for Blake2b hashing (used for WASM `t2` addresses).

### Deployments

See the Recall docs for more information on the testnet and mainnet deployments:
[https://docs.recall.network/protocol/contracts](https://docs.recall.network/protocol/contracts).

To get testnet tokens, visit: [https://faucet.recall.network](https://faucet.recall.network). Also,
you can check out the `foundry.toml` file to see the RPC URLs for each network (described in more
detail below).

## Usage

### Setup

First, clone the repo, and be sure `foundry` is installed on your machine (see
[here](https://book.getfoundry.sh/getting-started/installation)):

```shell
git clone https://github.com/recallnet/contracts.git
cd contracts
```

Install the dependencies and build the contracts, which will output the ABIs to the `out/`
directory:

```shell
pnpm install
pnpm build
```

Also, you can clean the build artifacts with:

```shell
pnpm clean
```

### Deploying contracts

The scripts for deploying contracts are in `script/` directory:

- `Recall.s.sol`: Deploy the Recall ERC20 contract.
- `Faucet.s.sol`: Deploy the faucet contract.
- `ValidatorGater.s.sol`: Deploy the validator gater contract.
- `ValidatorRewarder.s.sol`: Deploy the validator rewarder contract.
- `Bridge.s.sol`: Deploy the bridge contract—relevant for the Recall ERC20 on live chains.

> [!NOTE] If you're deploying _to_ the Recall subnet or Filecoin Calibration, you'll need to
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
- `testnet_subnet`: Deploy to testnet and the subnet (Recall).
- `devnet`: Deploy to the devnet network.

The `--target-contract` (`--tc`) should be `DeployScript`, and it takes an argument for the
environment used by the `--sig` flag below:

- `local`: Local chain(for either localnet or devnet)
- `testnet`: Testnet chain
- `ethereum` or `filecoin`: Mainnet chain (note: mainnet is not available yet)

Most scripts use the `--sig` flag with `run()` (or `run(uint256)` for the faucet) to execute
deployment with the given argument above, and the `--broadcast` flag actually sends the transaction
to the network. Recall that you **must** set `-g 100000` to ensure the gas estimate is sufficiently
high.

Mainnet deployments require the address of the Axelar Interchain Token Service on chain you are
deploying to, which is handled in the ERC20's `DeployScript` logic.

#### Localnet

##### Recall ERC20

Deploy the Recall ERC20 contract to the localnet parent chain (i.e., `http://localhost:8545`). Note
the `-g` flag is not used here since the gas estimate is sufficiently low on Anvil.

```shell
forge script script/Recall.s.sol --tc DeployScript --sig 'run()' --rpc-url localnet_parent --private-key $PRIVATE_KEY --broadcast -vv
```

##### Faucet

Deploy the Faucet contract to the localnet subnet. The second argument is the initial supply of
Recall tokens, owned by the deployer's account which will be transferred to the faucet contract
(e.g., 5000 with 10\*\*18 decimal units).

```shell
PRIVATE_KEY=<0x...> forge script script/Faucet.s.sol --tc DeployScript --sig 'run(uint256)' 5000000000000000000000 --rpc-url localnet_subnet --private-key $PRIVATE_KEY --broadcast -g 100000 -vv
```

#### Testnet

##### Recall ERC20

Deploy the Recall ERC20 contract to the testnet parent chain. Note the `-g` flag _is_ used here
(this differs from the localnet setup above since we're deploying to Filecoin Calibration);

```shell
forge script script/Recall.s.sol --tc DeployScript --sig 'run()' --rpc-url testnet_parent --private-key $PRIVATE_KEY --broadcast -g 100000 -vv
```

##### Faucet

Deploy the Faucet contract to the testnet subnet. The second argument is the initial supply of
Recall tokens, owned by the deployer's account which will be transferred to the faucet contract
(e.g., 5000 with 10\*\*18 decimal units).

```shell
forge script script/Faucet.s.sol --tc DeployScript --sig 'run(uint256)' 5000000000000000000000 --rpc-url testnet_subnet --private-key $PRIVATE_KEY --broadcast -g 100000 -vv
```

#### Devnet

The devnet does not have the concept of a "parent" chain, so all RPCs would use `--rpc-url devnet`
and follow the same pattern as the deployments above.

If you're trying to simply deploy to an Anvil node (i.e., `http://localhost:8545`), you can use the
same pattern, or just explicitly set the RPC URL:

```shell
forge script script/Recall.s.sol --tc DeployScript --sig 'run()' --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast -vv
```

#### Mainnet

Mainnet is not yet available. The RPC URLs (`mainnet_parent` and `mainnet_subnet`) are placeholders,
pointing to the same environment as the testnet.

##### Recall ERC20

However, if you'd like to deploy the RECALL ERC20 contract to mainnet Ethereum or Filecoin, you can
use the following. Note these will enable behavior for the Axelar Interchain Token Service.

Deploy to Ethereum:

```shell
forge script script/Recall.s.sol:DeployScript --sig 'run()' --rpc-url https://eth.merkle.io --private-key $PRIVATE_KEY --broadcast -vv
```

And for Filecoin:

```shell
forge script script/Recall.s.sol:DeployScript --sig 'run()' --rpc-url https://api.node.glif.io/rpc/v1 --private-key $PRIVATE_KEY --broadcast -vv
```

## Development

### Scripts

Deployment scripts are described above. Additional `pnpm` scripts are available in `package.json`:

- `format`: Run `forge fmt` to format the code.
- `lint`: Run `forge fmt` and `solhint` to check for linting errors.
- `test`: Run `forge test` to run the tests.
- `clean`: Run `forge clean` to clean the build artifacts.

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

## Contributing

PRs accepted. Please ensure your changes follow our coding standards and include appropriate tests.

Small note: If editing the README, please conform to the
[standard-readme](https://github.com/RichardLitt/standard-readme) specification.

## License

MIT OR Apache-2.0, © 2025 Recall Contributors
