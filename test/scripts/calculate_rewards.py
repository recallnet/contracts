#!/usr/bin/env python3

import sys
import json

def checkpoint_yield_from_apy(apy, checkpoint_period):    
    t = checkpoint_period/31536000 # seconds in a year
    return pow((1 + apy), t) - 1

def main():
    # Get input parameters from command line
    supply = int(sys.argv[1])    
    checkpoint_period = int(sys.argv[2])
    blocks_committed = int(sys.argv[3])
    

    # Calculate rewards
    apy = 0.05
    supply_delta = checkpoint_yield_from_apy(apy, checkpoint_period) * supply
    validator_share = (blocks_committed * supply_delta) / checkpoint_period
    
    # Return results as JSON
    result = {
        "supply_delta": str(int(supply_delta)),
        "validator_share": str(int(validator_share))
    }
    
    print(json.dumps(result))

if __name__ == "__main__":
    main()