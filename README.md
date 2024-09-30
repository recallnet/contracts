# Hoku ERC20 Contracts

## Install

```shell
forge install
```

## Build

```shell
forge build
```

## Deploy

If you're deploying _to_ the Hoku subnet, you'll need to (significantly) bump the gas estimation
multiplier by adding a `-g 100000` flag to the `forge script` command.

### Local

```shell
PRIVATE_KEY=<0x...> forge script script/Hoku.s.sol --tc DeployScript 0 --sig 'run(uint8)' --rpc-url <...>  --broadcast -vv
vv
```

### Testnet

```shell
PRIVATE_KEY=<0x...> forge script script/Hoku.s.sol --tc DeployScript 1 --sig 'run(uint8)' --rpc-url <...>  --broadcast -vv
vv
```

### Mainnet

```shell
PRIVATE_KEY=<0x...> forge script script/Hoku.s.sol --tc DeployScript 2 --sig 'run(uint8)' --rpc-url <...>  --broadcast -vv
vv
```

## Deployments

TODO: these are outdated and should describe what the contract is

| Chain        | Address                                    |
| ------------ | ------------------------------------------ |
| calibration  | 0xEa944dEf4fd96A70f0B53D98E6945f643491B960 |
| base sepolia | 0xd02Bc370Ac6D40B57B8D64578c85132dF59f0109 |

## [Faucet](https://github.com/hokunet/faucet) Usage

To get 5e18 tokens on a given address:

```sh
curl -X POST -H 'Content-Type: application/json' 'http://<faucet host>/send' --data-raw '{"address":"0xfoobar"}'
```

## Credits

### Deployments

| Chain                       | Address                                    |
| --------------------------- | ------------------------------------------ |
| Tesnet (`credit-approvals`) | 0x138E3aFeb7dC8944d464326cb2ff2b429cdA808b |

### Get subnet stats:

```solidity
cast abi-decode "getSubnetStats()((uint256,uint256,uint256,uint256,uint256,uint256,uint64,uint64,uint64,uint64))" $(cast call --rpc-url $EVM_RPC_URL $CONTRACT "getSubnetStats()")
```

(5000000000000000000000 [5e21], 4294967296 [4.294e9], 1024136608 [1.024e9], 5000000000000000000000
[5e21], 110680465292266920644 [1.106e20], 10297568725696 [1.029e13], 1, 1, 791, 0)

### Get credit stats:

```solidity
cast abi-decode "getCreditStats()((uint256,uint256,uint256,uint256,uint64,uint64))" $(cast call --rpc-url $EVM_RPC_URL $CONTRACT "getCreditStats()")
```

(5000000000000000000000 [5e21], 5000000000000000000000 [5e21], 110680465107922990004 [1.106e20],
10481913315136 [1.048e13], 1, 1)

### Get credit account info for an address:

```solidity
cast abi-decode "getAccount(address)((uint256,uint256,uint256,uint64,uint64))" $(cast call --rpc-url $EVM_RPC_URL $CONTRACT "getAccount(address)" $EVM_ADDRESS)
```

(1024136608 [1.024e9], 4889319524410163694860 [4.889e21], 110680465107922990004 [1.106e20], 20461
[2.046e4], 0)

Note: `approvals` (the last value returned) is not yet implemented and returns `0`.

### Get credit balance for an account:

```solidity
cast abi-decode "getCreditBalance(address)((uint256,uint256,uint64))" $(cast call --rpc-url $EVM_RPC_URL $CONTRACT "getCreditBalance(address)" $EVM_ADDRESS)
```

(4889319524410162877660 [4.889e21], 110680464923579217764 [1.106e20], 20641 [2.064e4])

### Buy credits for an address:

```solidity
cast send --rpc-url $EVM_RPC_URL $CONTRACT "buyCredit(address)" $EVM_ADDRESS --value 10ether --private-key $PRIVATE_KEY
```
