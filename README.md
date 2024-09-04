# Hoku Contracts

## Install
```shell
forge install
```

## Build
```shell
forge build
```

## Deploy

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

|chain | address|
| -----| ------|
|calibration |0xEa944dEf4fd96A70f0B53D98E6945f643491B960|
|base sepolia|0xd02Bc370Ac6D40B57B8D64578c85132dF59f0109|


## [Faucet](https://github.com/hokunet/faucet) Usage

To get 5e18 tokens on a given address:


```sh
curl -X POST -H 'Content-Type: application/json' 'http://<faucet host>/send' --data-raw '{"address":"0xfoobar"}'
```
