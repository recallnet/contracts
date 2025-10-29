# Just Commands for Recall Role Revocation

Quick reference guide for using the `just` commands to revoke roles on the Recall contract.

## Prerequisites

1. Install `just`: https://github.com/casey/just#installation
   ```bash
   # macOS
   brew install just
   
   # Linux
   cargo install just
   ```

2. Copy `.env.example` to `.env` and configure:
   ```bash
   cp .env.example .env
   # Edit .env with your values
   ```

## Available Commands

### List all commands
```bash
just
# or
just --list
```

### Validate your .env file
```bash
just validate-env
```

### Check role status for an account
```bash
just check-roles 0xAccountAddress
```

### Revoke a single role (dry-run)
```bash
# Configure .env first with ROLE_TYPE and ACCOUNT
just dry-run
```

### Revoke a single role (broadcast)
```bash
# Set BROADCAST=true in .env, then:
just revoke-role
```

### Batch revoke multiple roles
```bash
# Configure REVOKE_ADMIN, REVOKE_MINTER, REVOKE_PAUSER in .env
just revoke-batch
```

### Revoke role from multiple accounts
```bash
# Configure ACCOUNTS in .env (comma-separated)
just revoke-multi
```

## Quick Start Examples

### Example 1: Revoke MINTER role using Ledger (Safe Dry-Run First)

1. Create/edit `.env`:
```bash
PROXY_ADDR=0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
RPC_URL=https://api.calibration.node.glif.io/rpc/v1
USE_LEDGER=true
SENDER=0xYourLedgerAddress
ROLE_TYPE=MINTER
ACCOUNT=0xAccountToRevoke
BROADCAST=false
```

2. Validate configuration:
```bash
just validate-env
```

3. Check current roles:
```bash
just check-roles 0xAccountToRevoke
```

4. Dry run (simulate):
```bash
just dry-run
```

5. If everything looks good, broadcast:
```bash
# Edit .env: set BROADCAST=true
just revoke-role
```

### Example 2: Remove all roles from compromised account

1. Edit `.env`:
```bash
PROXY_ADDR=0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
RPC_URL=https://api.calibration.node.glif.io/rpc/v1
USE_LEDGER=true
SENDER=0xYourLedgerAddress
ACCOUNT=0xCompromisedAccount
REVOKE_ADMIN=true
REVOKE_MINTER=true
REVOKE_PAUSER=true
BROADCAST=false
```

2. Dry run:
```bash
just revoke-batch
```

3. Broadcast:
```bash
# Edit .env: set BROADCAST=true
just revoke-batch
```

### Example 3: Revoke MINTER from multiple test accounts

1. Edit `.env`:
```bash
PROXY_ADDR=0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
RPC_URL=https://api.calibration.node.glif.io/rpc/v1
USE_LEDGER=true
SENDER=0xYourLedgerAddress
ROLE_TYPE=MINTER
ACCOUNTS=0x1111...,0x2222...,0x3333...
BROADCAST=true
```

2. Execute:
```bash
just revoke-multi
```

## Configuration Options

### Authentication Methods

**Ledger (Recommended):**
```bash
USE_LEDGER=true
SENDER=0xYourLedgerAddress
# Optional custom path:
# HD_PATH=m/44'/60'/0'/0/1
```

**Trezor:**
```bash
USE_TREZOR=true
SENDER=0xYourTrezorAddress
```

**Private Key (Not Recommended):**
```bash
PRIVATE_KEY=0xYourPrivateKey
```

### Role Types

- `ADMIN` - Can manage roles and authorize upgrades
- `MINTER` - Can mint new tokens
- `PAUSER` - Can pause the contract

### Safety Options

```bash
# Prevent accidental self-admin revocation (default: false)
ALLOW_SELF_ADMIN_REVOKE=false

# Dry-run mode - simulate without broadcasting (default: false)
BROADCAST=false

# Verbose output for debugging
VERBOSE=true
```

## Workflow Best Practices

1. **Always validate first:**
   ```bash
   just validate-env
   ```

2. **Check current state:**
   ```bash
   just check-roles 0xTargetAccount
   ```

3. **Dry-run before broadcasting:**
   ```bash
   just dry-run
   ```

4. **Review the output carefully**

5. **Set BROADCAST=true and execute:**
   ```bash
   just revoke-role
   ```

6. **Verify the result:**
   ```bash
   just check-roles 0xTargetAccount
   ```

## Troubleshooting

### "Error: PROXY_ADDR not set in .env"
Make sure you've created a `.env` file from `.env.example` and filled in the required values.

### "Error: Must set either USE_LEDGER=true, USE_TREZOR=true, or PRIVATE_KEY"
You need to specify an authentication method in your `.env` file.

### Ledger not detected
1. Connect and unlock your Ledger
2. Open the Ethereum app
3. Enable "Contract data" in Ethereum app settings
4. Try the command again

### "Caller Not Admin" error
The address you're using (SENDER) doesn't have ADMIN_ROLE. Check with:
```bash
just check-roles $YOUR_SENDER_ADDRESS
```

## Security Notes

- ⚠️ **Always dry-run first** with `BROADCAST=false`
- ✅ **Use hardware wallets** (Ledger/Trezor) instead of private keys
- ✅ **Double-check addresses** before broadcasting
- ✅ **Test on testnet** before mainnet operations
- ⚠️ **Don't revoke all admin roles** without a replacement admin

## Additional Resources

- Full documentation: [`script/RevokeRecallRole.README.md`](script/RevokeRecallRole.README.md)
- Script source: [`script/RevokeRecallRole.s.sol`](script/RevokeRecallRole.s.sol)
- Just documentation: https://just.systems/man/en/