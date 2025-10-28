# Recall Role Revocation Script

This directory contains Forge scripts for revoking roles on deployed Recall token contracts.

## Overview

The `RevokeRecallRole.s.sol` script provides three different contracts for role management:

1. **RevokeRoleScript** - Revoke a single role from one account
2. **BatchRevokeScript** - Revoke multiple roles from one account
3. **MultiAccountRevokeScript** - Revoke one role from multiple accounts

## Prerequisites

- Foundry installed and configured
- Access to an account with `ADMIN_ROLE` on the Recall contract
- The deployed Recall proxy contract address

## Available Roles

The Recall contract has three roles:
- `ADMIN` - Can authorize upgrades, unpause, and manage other roles
- `MINTER` - Can mint new tokens
- `PAUSER` - Can pause the contract

## Usage

### 1. Single Role Revocation

Revoke one role from one account.

#### With Private Key

```bash
PROXY_ADDR=0x1234... \
ROLE_TYPE=MINTER \
ACCOUNT=0x5678... \
forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
  --rpc-url https://your-rpc-url \
  --broadcast \
  --private-key $PRIVATE_KEY
```

#### With Ledger Hardware Wallet

```bash
PROXY_ADDR=0x1234... \
ROLE_TYPE=MINTER \
ACCOUNT=0x5678... \
forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
  --rpc-url https://your-rpc-url \
  --broadcast \
  --ledger \
  --sender 0xYourLedgerAddress
```

**Ledger Setup:**
1. Connect your Ledger device via USB
2. Unlock the device with your PIN
3. Open the Ethereum app on your Ledger
4. Run the command above
5. Review and confirm the transaction on your Ledger device

#### With Trezor Hardware Wallet

```bash
PROXY_ADDR=0x1234... \
ROLE_TYPE=MINTER \
ACCOUNT=0x5678... \
forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
  --rpc-url https://your-rpc-url \
  --broadcast \
  --trezor \
  --sender 0xYourTrezorAddress
```

#### Using Function Parameters (Alternative)

Instead of environment variables, you can pass parameters directly:

```bash
forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
  --rpc-url https://your-rpc-url \
  --broadcast \
  --ledger \
  --sender 0xYourLedgerAddress \
  -s "run(address,string,address)" \
  0xProxyAddress "MINTER" 0xAccountToRevoke
```

### 2. Batch Role Revocation

Revoke multiple roles from a single account in one transaction.

```bash
PROXY_ADDR=0x1234... \
ACCOUNT=0x5678... \
REVOKE_ADMIN=false \
REVOKE_MINTER=true \
REVOKE_PAUSER=true \
forge script script/RevokeRecallRole.s.sol:BatchRevokeScript \
  --rpc-url https://your-rpc-url \
  --broadcast \
  --ledger \
  --sender 0xYourLedgerAddress
```

### 3. Multi-Account Role Revocation

Revoke one role from multiple accounts.

```bash
PROXY_ADDR=0x1234... \
ROLE_TYPE=MINTER \
ACCOUNTS="0x5678...,0x9abc...,0xdef0..." \
forge script script/RevokeRecallRole.s.sol:MultiAccountRevokeScript \
  --rpc-url https://your-rpc-url \
  --broadcast \
  --ledger \
  --sender 0xYourLedgerAddress
```

## Hardware Wallet Configuration

### Custom HD Derivation Path

If you need to use a non-standard derivation path:

```bash
forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
  --rpc-url https://your-rpc-url \
  --broadcast \
  --ledger \
  --hd-paths "m/44'/60'/0'/0/1" \
  --sender 0xYourLedgerAddress
```

### Multiple Ledger Accounts

To use a specific account from your Ledger:

```bash
# List available accounts
cast wallet list --ledger

# Use specific account
forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
  --rpc-url https://your-rpc-url \
  --broadcast \
  --ledger \
  --hd-paths "m/44'/60'/0'/0/2" \
  --sender 0xYourSpecificAddress
```

## Dry Run (Simulation)

Test the script without broadcasting transactions by omitting the `--broadcast` flag:

```bash
PROXY_ADDR=0x1234... \
ROLE_TYPE=MINTER \
ACCOUNT=0x5678... \
forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
  --rpc-url https://your-rpc-url \
  --ledger \
  --sender 0xYourLedgerAddress
```

This will simulate the transaction and show you what would happen without actually executing it.

## Safety Features

### 1. Admin Role Self-Revocation Protection

By default, the script prevents you from revoking your own `ADMIN_ROLE` to avoid locking yourself out. To override this:

```bash
ALLOW_SELF_ADMIN_REVOKE=true \
PROXY_ADDR=0x1234... \
ROLE_TYPE=ADMIN \
ACCOUNT=0xYourOwnAddress \
forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
  --rpc-url https://your-rpc-url \
  --broadcast \
  --ledger \
  --sender 0xYourLedgerAddress
```

### 2. Pre-flight Checks

The script performs several checks before executing:
- Verifies the caller has `ADMIN_ROLE`
- Confirms the target account has the role to be revoked
- Displays current role status before and after revocation
- Prevents self-admin revocation (unless explicitly allowed)

### 3. Verbose Logging

All scripts provide detailed console output showing:
- Contract addresses
- Role types and accounts
- Current role status
- Transaction results
- Updated role status

## Environment Variables Reference

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `PROXY_ADDR` | Yes | Recall proxy contract address | `0x1234...` |
| `ROLE_TYPE` | Yes* | Role to revoke: ADMIN, MINTER, or PAUSER | `MINTER` |
| `ACCOUNT` | Yes* | Address to revoke role from | `0x5678...` |
| `ACCOUNTS` | Yes** | Comma-separated addresses | `0x123...,0x456...` |
| `REVOKE_ADMIN` | No | Revoke ADMIN_ROLE (batch only) | `true` or `false` |
| `REVOKE_MINTER` | No | Revoke MINTER_ROLE (batch only) | `true` or `false` |
| `REVOKE_PAUSER` | No | Revoke PAUSER_ROLE (batch only) | `true` or `false` |
| `ALLOW_SELF_ADMIN_REVOKE` | No | Allow self-admin revocation | `true` or `false` |
| `PRIVATE_KEY` | No*** | Private key (if not using hardware wallet) | `0xabc...` |

\* Required for `RevokeRoleScript`  
\** Required for `MultiAccountRevokeScript`  
\*** Not needed when using `--ledger` or `--trezor`

## Troubleshooting

### Ledger Not Detected

```bash
# Check if Ledger is connected
cast wallet list --ledger

# If not detected, try:
# 1. Reconnect the device
# 2. Unlock with PIN
# 3. Open Ethereum app
# 4. Enable "Contract data" in Ethereum app settings
```

### Transaction Rejected on Device

Make sure:
1. The Ethereum app is open (not Bitcoin or another app)
2. "Contract data" is enabled in the Ethereum app settings
3. You're using the correct derivation path
4. The device firmware is up to date

### "Caller Not Admin" Error

The address you're using doesn't have `ADMIN_ROLE`. Verify:
```bash
cast call $PROXY_ADDR "hasRole(bytes32,address)(bool)" \
  $(cast keccak "ADMIN_ROLE") \
  $YOUR_ADDRESS \
  --rpc-url $RPC_URL
```

### "Account Does Not Have Role" Error

The target account doesn't have the role you're trying to revoke. Check current roles:
```bash
cast call $PROXY_ADDR "hasRole(bytes32,address)(bool)" \
  $(cast keccak "MINTER_ROLE") \
  $TARGET_ADDRESS \
  --rpc-url $RPC_URL
```

## Examples

### Example 1: Remove Minter from Old Admin

```bash
# Using Ledger
PROXY_ADDR=0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb \
ROLE_TYPE=MINTER \
ACCOUNT=0x1234567890123456789012345678901234567890 \
forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --broadcast \
  --ledger \
  --sender 0xYourLedgerAddress
```

### Example 2: Remove All Roles from Compromised Account

```bash
# Using Ledger
PROXY_ADDR=0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb \
ACCOUNT=0x1234567890123456789012345678901234567890 \
REVOKE_ADMIN=true \
REVOKE_MINTER=true \
REVOKE_PAUSER=true \
forge script script/RevokeRecallRole.s.sol:BatchRevokeScript \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --broadcast \
  --ledger \
  --sender 0xYourLedgerAddress
```

### Example 3: Revoke Minter from Multiple Test Accounts

```bash
# Using Ledger
PROXY_ADDR=0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb \
ROLE_TYPE=MINTER \
ACCOUNTS="0x1111...,0x2222...,0x3333..." \
forge script script/RevokeRecallRole.s.sol:MultiAccountRevokeScript \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --broadcast \
  --ledger \
  --sender 0xYourLedgerAddress
```

## Security Best Practices

1. **Always dry run first** - Test without `--broadcast` to verify behavior
2. **Use hardware wallets** - Ledger/Trezor provide better security than private keys
3. **Verify addresses** - Double-check all addresses before broadcasting
4. **Keep admin access** - Don't revoke all admin roles without a replacement
5. **Document changes** - Keep records of role changes for audit purposes
6. **Test on testnet** - Try on testnet before mainnet operations

## Support

For issues or questions:
- Check the [Foundry documentation](https://book.getfoundry.sh/)
- Review the [Ledger Ethereum app guide](https://support.ledger.com/hc/en-us/articles/360009576554)
- Examine the script source code for detailed comments