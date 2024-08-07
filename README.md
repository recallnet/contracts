# Hoku ERC20 Contracts

## Deploy

```shell
PRIVATE_KEY=<...> forge script script/Hoku.s.sol:HokuScript --rpc-url <rpc_url>  --broadcast -vvvv
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
