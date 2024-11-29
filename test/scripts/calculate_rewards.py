#!/usr/bin/env python3

import sys
import json
from decimal import Decimal, getcontext

# Constants to match Solidity's UD60x18
WAD = Decimal('1000000000000000000')  # 1e18
SECONDS_PER_YEAR = Decimal('31536000')
APY = Decimal('50000000000000000')    # 0.05 * 1e18
INFLATION_RATE = Decimal('928276004952')  # Pre-calculated checkpoint yield for 600 blocks (1 block = 1s)

def checkpoint_yield_from_apy(supply, total_period=None):    
    if total_period is not None:
        # For total period calculation, use compound interest
        getcontext().prec = 36
        period = Decimal(str(total_period))
        time_fraction = (period * WAD) // SECONDS_PER_YEAR
        base = WAD + APY
        exponent = time_fraction / WAD
        result = (pow(base / WAD, exponent) * WAD).quantize(Decimal('1'))
        yield_rate = result - WAD
        return (supply * yield_rate) // WAD
    else:
        # For single checkpoint, use pre-calculated inflation rate
        return (supply * INFLATION_RATE) // WAD

def calculate_shares(supply_delta, blocks_committed, checkpoint_period):
    """Calculate validator and rewarder shares directly"""
    # Calculate validator share
    validator_share = (blocks_committed * supply_delta) // checkpoint_period
    # Calculate rewarder share
    rewarder_share = supply_delta - validator_share
    return validator_share, rewarder_share

def main():
    supply = Decimal(sys.argv[1])    
    period = Decimal(sys.argv[2])
    blocks_committed = Decimal(sys.argv[3])
    
    # We use this when we don't want to calculate shares for a single checkpoint
    if blocks_committed == 0:
        # Calculate total period yield
        supply_delta = checkpoint_yield_from_apy(supply, total_period=period)
        validator_share = 0
        rewarder_share = 0
    else:
        # Calculate single checkpoint yield and shares
        supply_delta = checkpoint_yield_from_apy(supply)
        validator_share, rewarder_share = calculate_shares(supply_delta, blocks_committed, period)
    
    result = {
        "supply_delta": str(supply_delta),
        "validator_share": str(validator_share),
        "rewarder_share": str(rewarder_share)
    }
    
    print(json.dumps(result))

if __name__ == "__main__":
    main()