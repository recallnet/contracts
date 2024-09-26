# Hoku ERC20 Contracts

## Install
```shell
forge install
```

## Build
```shell
forge build
```

## Clean
```shell
forge clean
```

## Deploy

To deploy the contract you need the following:
- Select an environment prefix: `l` = Local, `t` = Testnet, "" = Mainnet
- The address of the Axelar Interchain Token Service on chain you are deploying to
- A private key with funds on the target chain
- An rpc endpoint for the target chain

### Local
Start a local network using anvil,
```shell
anvil
```
Anvil will output an address and private key, copy one of the private keys for the step below.

Deploy the contract, in this case we just use the zero-address for the Axelar Interchain Token Service.
```shell
forge script script/Hoku.s.sol:DeployScript --sig 'run(string)' local --broadcast -vv --rpc-url http://localhost:8545 --private-key <0x...>
```

### Testnet
```shell
forge script script/Hoku.s.sol:DeployScript --sig 'run(string)' testnet --broadcast -vv --rpc-url <...>  --private-key <0x...>
```

### Ethereum Mainnet
```shell
forge script script/Hoku.s.sol:DeployScript --sig 'run(string)' ethereum --broadcast -vv --rpc-url https://eth.merkle.io --private-key <0x...>
```

### Filecoin mainnet
RPC copied from https://docs.filecoin.io/networks/mainnet/rpcs
```shell
forge script script/Hoku.s.sol:DeployScript --sig 'run(string)' filecoin --broadcast -vv -g 100000 --rpc-url https://api.node.glif.io/rpc/v1 --private-key <0x...>
```
The `-g` flag is a multiplier on the estimated gas price. In this case 100000 is 1000x the estimated gas price. Unclear why filecoin requires such a large multiplier.

## Deployments

|chain | address|
| -----| ------|
|calibration |0xEa944dEf4fd96A70f0B53D98E6945f643491B960|
|base sepolia|0xd02Bc370Ac6D40B57B8D64578c85132dF59f0109|


## [Faucet](https://github.com/hokunet/faucet) Usage

To get 5e18 tokens on a given address:


```sh
curl -X POST -H 'Content-Type: application/json' 'http://<faucet host>/send' --data-raw '{"address":"0xfoobar"}'
```
