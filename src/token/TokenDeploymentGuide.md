# Token Deployment Guide

This guide walks through the process of deploying the Recall token and testing cross-chain transfers.

## Prerequisites

1. Install Foundry
2. Install dependencies
```bash
pnpm install
forge install
```
3. Build contracts
```bash
forge build
```
When you build the contracts, make sure to note down the version of the solidity compiler used. It might be useful later when verifying the contracts.

## 1. Private key setup

First off we need to create the private key used to deploy the token. This key is important to save because if we ever want to deploy the token on any new chains, we'll need it. This is because the 'interchainTokenID' is generate from a salt + the deployer's address.

There are a few different options for how forge can handle private keys.

- [Raw](https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---raw), the key is provided either interactively or via a flag
- [Keystore](https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---keystore), forge has a built in encrypted keystore that can be used to store the key
- [Hardware Wallet](https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---hardware-wallet), forge supports trezor and ledger hardware wallets

The rest of this guide presumes that every command is run with one of the above options so that signatures can be created.

## 2. Fund wallet

Should be straight forward, given the address of the key generated above, fund the wallet on Base and Filecoin.

## 3. Deploy on desired chains

The following commands will deploy the token and connect them through the Axelar Interchain Token Service automatically. Minting will not happen yet at this point.

Please make sure to add the appropiate flag for the private key you want to use.
Also note that you can run the command without the --broadcast flag to test the transaction without executing it.

### Filecoin

```bash
forge script script/Recall.s.sol:DeployScript -vvv -g 100000 --rpc-url https://api.node.glif.io/rpc/v1 --sig "run(string)" filecoin --broadcast
```

The `-g 100000` flag is used to set the gas multiplier for the transaction. This is needed because the gas price estimation is not working properly on Filecoin.

The command above should yield an output that looks something like this:

```
== Return ==
0: contract Recall 0xC28dDF617467d992f54AFe3340599F5325e869E4

== Logs ==
  Implementation address:  0xC2fea13f7220750b87AFA263Dc567c8fc6953510
  Deployer:  0x3e7bEc04F2f812e01543D58eF5ab608674696665
  Deploying token manager
  Recall Interchain Token ID:  0xcfb6e8744f9f354b2d9022a0b8c030daa8e2f029ba446566fbb21fbfd51bb09c
  Token manager:  0x0d0Cf8D25e0CD22a50dF66543e2cb0035047c21C
```

### Base

```bash
forge script script/Recall.s.sol:DeployScript -vvv --rpc-url https://base-rpc.publicnode.com --sig "run(string)" base --broadcast
```

Since we are deploying with the same private key on Base as we did on Filecoin, and it's the first transactions on both chains, the output should be exactly the same on both chains.


## 4. Verify contracts

On Base you can verify the contracts using the forge toolchain. You just need to get a [basescan api key](https://basescan.org/myapikey) and run the following command:

```bash
forge verify-contract --chain-id 8453 --watch <implementation_address> src/token/Recall.sol:Recall -e <etherscan_api_key>
```

The Recall token address is a proxy account and can be verified directly on basescan.org by clicking in the interface after verifying the implementation address.

On Filecoin you can verify the contracts on [filfox](https://filfox.info/en), which is more tricky.


## 5. Set up new token admin

We don't want the singular private key to remain the admin, and we want the foundation multisig to mint the token once ready. Therefore we should roles on the contracts before taking any next steps.

There are three roles:
- Admin: Can upgrade the contract, set roles, and unpause the token
- Minter: Can mint new tokens
- Pauser: Can pause the token, this is a separate role which enables swift action while the admin likely will have timelocks on all its actions in the future

Create foundation multisigs for each chain:
- Base: use regular [Safe frontend](https://app.safe.global/)
- Filecoin: use [Filecoin hosted Safe](https://safe.filecoin.io/)

In the commands below, `<proxy_address>` is the proxy address of the Recall token.


### Base

```bash
forge script script/Recall.s.sol:DeployScript -vvv --rpc-url https://base-rpc.publicnode.com --sig "setDefaultRoles(address,address,address,address)" <proxy_address> <admin_address> <minter_address> <pauser_address> --broadcast
```

### Filecoin

```bash
forge script script/Recall.s.sol:DeployScript -vvv -g 100000 --rpc-url https://api.node.glif.io/rpc/v1 --sig "setDefaultRoles(address,address,address,address)" <proxy_address> <admin_address> <minter_address> <pauser_address> --broadcast
```

## 6. Mint tokens

Since we gave the foundation multisig the admin and minter role, the mint function on the `<proxy_address>` now has to be called from the corresponding Safe interface.

### Testing minting functionality

If you are just testing the token and bridge and you haven't given away admin to a separate key yet, you can use the following commands to mint tokens.

#### Base

```bash
forge script script/Bridge.s.sol:BridgeOps -vvv --rpc-url https://base-rpc.publicnode.com --sig "mintFunds(address,address,uint256)" <proxy_address> <recipient_address> <amount> --broadcast
```

#### Filecoin

```bash
forge script script/Bridge.s.sol:BridgeOps -vvv -g 100000 --rpc-url https://api.node.glif.io/rpc/v1 --sig "mintFunds(address,address,uint256)" <proxy_address> <recipient_address> <amount> --broadcast
```

## 7. Testing cross-chain transfers

The BridgeOps script also has functionality for testing cross-chain transfers. This is how you can test the bridge.

### Base to Filecoin

```bash
forge script script/Bridge.s.sol:BridgeOps -vvv --rpc-url https://base-rpc.publicnode.com --sig "xChainTransfer(address,string,address,uint256)" <proxy_address> "filecoin" <recipient_address> <amount> --broadcast
```

### Filecoin to base

```bash
forge script script/Bridge.s.sol:BridgeOps -vvv -g 100000 --rpc-url https://api.node.glif.io/rpc/v1 --sig "xChainTransfer(address,string,address,uint256)" <proxy_address> "base" <recipient_address> <amount> --broadcast
```

### Check balance

There's also functionality for checking the balance of an address on a given chain, to see if the transfer was successful.

#### Base

```bash
forge script script/Bridge.s.sol:BridgeOps -vvv --rpc-url https://base-rpc.publicnode.com --sig "checkBalance(address,address)" <proxy_address> <recipient_address>
```

#### Filecoin

```bash
forge script script/Bridge.s.sol:BridgeOps -vvv -g 100000 --rpc-url https://api.node.glif.io/rpc/v1 --sig "checkBalance(address,address)" <proxy_address> <recipient_address>
```
