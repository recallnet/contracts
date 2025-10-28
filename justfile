# Justfile for Recall contract operations
# Requires: just (https://github.com/casey/just)
# Usage: just revoke-role

set dotenv-load := true

# Default recipe - show available commands
default:
    @just --list

# Revoke a single role from an account (reads from .env)
revoke-role:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Check required environment variables
    if [ -z "${PROXY_ADDR:-}" ]; then
        echo "Error: PROXY_ADDR not set in .env"
        exit 1
    fi
    if [ -z "${ROLE_TYPE:-}" ]; then
        echo "Error: ROLE_TYPE not set in .env"
        exit 1
    fi
    if [ -z "${ACCOUNT:-}" ]; then
        echo "Error: ACCOUNT not set in .env"
        exit 1
    fi
    if [ -z "${RPC_URL:-}" ]; then
        echo "Error: RPC_URL not set in .env"
        exit 1
    fi
    
    # Build the forge command
    CMD="forge script script/RevokeRecallRole.s.sol:RevokeRoleScript --rpc-url $RPC_URL"
    
    # Add broadcast flag if BROADCAST is set to true
    if [ "${BROADCAST:-false}" = "true" ]; then
        CMD="$CMD --broadcast"
    fi
    
    # Add authentication method
    if [ "${USE_LEDGER:-false}" = "true" ]; then
        if [ -z "${SENDER:-}" ]; then
            echo "Error: SENDER address required when USE_LEDGER=true"
            exit 1
        fi
        CMD="$CMD --ledger --sender $SENDER"
        
        # Add custom HD path if specified
        if [ -n "${HD_PATH:-}" ]; then
            CMD="$CMD --hd-paths $HD_PATH"
        fi
    elif [ "${USE_TREZOR:-false}" = "true" ]; then
        if [ -z "${SENDER:-}" ]; then
            echo "Error: SENDER address required when USE_TREZOR=true"
            exit 1
        fi
        CMD="$CMD --trezor --sender $SENDER"
    elif [ -n "${PRIVATE_KEY:-}" ]; then
        CMD="$CMD --private-key $PRIVATE_KEY"
    else
        echo "Error: Must set either USE_LEDGER=true, USE_TREZOR=true, or PRIVATE_KEY"
        exit 1
    fi
    
    # Add verbosity if requested
    if [ "${VERBOSE:-false}" = "true" ]; then
        CMD="$CMD -vvvv"
    fi
    
    echo "Executing: $CMD"
    echo ""
    eval $CMD

# Batch revoke multiple roles from one account (reads from .env)
revoke-batch:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Check required environment variables
    if [ -z "${PROXY_ADDR:-}" ]; then
        echo "Error: PROXY_ADDR not set in .env"
        exit 1
    fi
    if [ -z "${ACCOUNT:-}" ]; then
        echo "Error: ACCOUNT not set in .env"
        exit 1
    fi
    if [ -z "${RPC_URL:-}" ]; then
        echo "Error: RPC_URL not set in .env"
        exit 1
    fi
    
    # Build the forge command
    CMD="forge script script/RevokeRecallRole.s.sol:BatchRevokeScript --rpc-url $RPC_URL"
    
    # Add broadcast flag if BROADCAST is set to true
    if [ "${BROADCAST:-false}" = "true" ]; then
        CMD="$CMD --broadcast"
    fi
    
    # Add authentication method
    if [ "${USE_LEDGER:-false}" = "true" ]; then
        if [ -z "${SENDER:-}" ]; then
            echo "Error: SENDER address required when USE_LEDGER=true"
            exit 1
        fi
        CMD="$CMD --ledger --sender $SENDER"
        if [ -n "${HD_PATH:-}" ]; then
            CMD="$CMD --hd-paths $HD_PATH"
        fi
    elif [ "${USE_TREZOR:-false}" = "true" ]; then
        if [ -z "${SENDER:-}" ]; then
            echo "Error: SENDER address required when USE_TREZOR=true"
            exit 1
        fi
        CMD="$CMD --trezor --sender $SENDER"
    elif [ -n "${PRIVATE_KEY:-}" ]; then
        CMD="$CMD --private-key $PRIVATE_KEY"
    else
        echo "Error: Must set either USE_LEDGER=true, USE_TREZOR=true, or PRIVATE_KEY"
        exit 1
    fi
    
    if [ "${VERBOSE:-false}" = "true" ]; then
        CMD="$CMD -vvvv"
    fi
    
    echo "Executing: $CMD"
    echo ""
    eval $CMD

# Revoke one role from multiple accounts (reads from .env)
revoke-multi:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Check required environment variables
    if [ -z "${PROXY_ADDR:-}" ]; then
        echo "Error: PROXY_ADDR not set in .env"
        exit 1
    fi
    if [ -z "${ROLE_TYPE:-}" ]; then
        echo "Error: ROLE_TYPE not set in .env"
        exit 1
    fi
    if [ -z "${ACCOUNTS:-}" ]; then
        echo "Error: ACCOUNTS not set in .env"
        exit 1
    fi
    if [ -z "${RPC_URL:-}" ]; then
        echo "Error: RPC_URL not set in .env"
        exit 1
    fi
    
    # Build the forge command
    CMD="forge script script/RevokeRecallRole.s.sol:MultiAccountRevokeScript --rpc-url $RPC_URL"
    
    # Add broadcast flag if BROADCAST is set to true
    if [ "${BROADCAST:-false}" = "true" ]; then
        CMD="$CMD --broadcast"
    fi
    
    # Add authentication method
    if [ "${USE_LEDGER:-false}" = "true" ]; then
        if [ -z "${SENDER:-}" ]; then
            echo "Error: SENDER address required when USE_LEDGER=true"
            exit 1
        fi
        CMD="$CMD --ledger --sender $SENDER"
        if [ -n "${HD_PATH:-}" ]; then
            CMD="$CMD --hd-paths $HD_PATH"
        fi
    elif [ "${USE_TREZOR:-false}" = "true" ]; then
        if [ -z "${SENDER:-}" ]; then
            echo "Error: SENDER address required when USE_TREZOR=true"
            exit 1
        fi
        CMD="$CMD --trezor --sender $SENDER"
    elif [ -n "${PRIVATE_KEY:-}" ]; then
        CMD="$CMD --private-key $PRIVATE_KEY"
    else
        echo "Error: Must set either USE_LEDGER=true, USE_TREZOR=true, or PRIVATE_KEY"
        exit 1
    fi
    
    if [ "${VERBOSE:-false}" = "true" ]; then
        CMD="$CMD -vvvv"
    fi
    
    echo "Executing: $CMD"
    echo ""
    eval $CMD

# Dry run - simulate without broadcasting
dry-run:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Running in DRY RUN mode (no transactions will be broadcast)"
    echo ""
    
    # Temporarily override BROADCAST
    export BROADCAST=false
    just revoke-role

# Show current role status for an account
check-roles ACCOUNT:
    #!/usr/bin/env bash
    set -euo pipefail
    
    if [ -z "${PROXY_ADDR:-}" ]; then
        echo "Error: PROXY_ADDR not set in .env"
        exit 1
    fi
    if [ -z "${RPC_URL:-}" ]; then
        echo "Error: RPC_URL not set in .env"
        exit 1
    fi
    
    echo "Checking roles for account: {{ACCOUNT}}"
    echo "Proxy address: $PROXY_ADDR"
    echo ""
    
    ADMIN_ROLE=$(cast keccak "ADMIN_ROLE")
    MINTER_ROLE=$(cast keccak "MINTER_ROLE")
    PAUSER_ROLE=$(cast keccak "PAUSER_ROLE")
    
    echo -n "ADMIN_ROLE: "
    cast call $PROXY_ADDR "hasRole(bytes32,address)(bool)" $ADMIN_ROLE {{ACCOUNT}} --rpc-url $RPC_URL
    
    echo -n "MINTER_ROLE: "
    cast call $PROXY_ADDR "hasRole(bytes32,address)(bool)" $MINTER_ROLE {{ACCOUNT}} --rpc-url $RPC_URL
    
    echo -n "PAUSER_ROLE: "
    cast call $PROXY_ADDR "hasRole(bytes32,address)(bool)" $PAUSER_ROLE {{ACCOUNT}} --rpc-url $RPC_URL

# Validate .env file has required variables
validate-env:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Validating .env file..."
    echo ""
    
    ERRORS=0
    
    # Check required variables
    if [ -z "${PROXY_ADDR:-}" ]; then
        echo "❌ PROXY_ADDR is not set"
        ERRORS=$((ERRORS + 1))
    else
        echo "✓ PROXY_ADDR: $PROXY_ADDR"
    fi
    
    if [ -z "${RPC_URL:-}" ]; then
        echo "❌ RPC_URL is not set"
        ERRORS=$((ERRORS + 1))
    else
        echo "✓ RPC_URL: $RPC_URL"
    fi
    
    # Check authentication method
    if [ "${USE_LEDGER:-false}" = "true" ]; then
        echo "✓ Authentication: Ledger"
        if [ -z "${SENDER:-}" ]; then
            echo "❌ SENDER is required when USE_LEDGER=true"
            ERRORS=$((ERRORS + 1))
        else
            echo "✓ SENDER: $SENDER"
        fi
    elif [ "${USE_TREZOR:-false}" = "true" ]; then
        echo "✓ Authentication: Trezor"
        if [ -z "${SENDER:-}" ]; then
            echo "❌ SENDER is required when USE_TREZOR=true"
            ERRORS=$((ERRORS + 1))
        else
            echo "✓ SENDER: $SENDER"
        fi
    elif [ -n "${PRIVATE_KEY:-}" ]; then
        echo "✓ Authentication: Private Key"
    else
        echo "❌ No authentication method set (USE_LEDGER, USE_TREZOR, or PRIVATE_KEY)"
        ERRORS=$((ERRORS + 1))
    fi
    
    echo ""
    if [ $ERRORS -eq 0 ]; then
        echo "✓ .env file is valid"
    else
        echo "❌ Found $ERRORS error(s) in .env file"
        exit 1
    fi