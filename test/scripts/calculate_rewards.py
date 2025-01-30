#!/usr/bin/env python3

import sys
import json
from decimal import Decimal, ROUND_DOWN

def calculate_rewards(total_tokens: int, checkpoint_period: int, blocks_committed: int) -> dict:
    """
    Calculate validator rewards based on fixed token generation
    
    Args:
        total_tokens: Total tokens for the checkpoint (in base units with 18 decimals)
        checkpoint_period: Number of blocks in checkpoint period
        blocks_committed: Number of blocks committed by validator
    
    Returns:
        Dictionary with validator share and remaining tokens
    """
    # Convert to Decimal for precise calculation
    tokens = Decimal(total_tokens)
    period = Decimal(checkpoint_period)
    blocks = Decimal(blocks_committed)
    
    # Calculate validator's share based on proportion of blocks committed
    validator_share = (blocks / period) * tokens
    
    # Round down to match Solidity behavior
    validator_share = validator_share.quantize(Decimal('1.'), rounding=ROUND_DOWN)
    
    return {
        "validator_share": int(validator_share),
        "total_tokens": int(tokens)
    }

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: calculate_rewards.py <total_tokens> <checkpoint_period> <blocks_committed>")
        sys.exit(1)
    
    total_tokens = int(sys.argv[1])
    checkpoint_period = int(sys.argv[2])
    blocks_committed = int(sys.argv[3])
    
    result = calculate_rewards(total_tokens, checkpoint_period, blocks_committed)
    print(json.dumps(result))