# Hoku Audit Prep

# Overview

| Project Name | Hoku |
| --- | --- |
| Repositories | [https://github.com/hokunet/contracts/tree/main](https://github.com/hokunet/contracts/tree/main) [https://github.com/hokunet/ipc/tree/main/contracts](https://github.com/hokunet/ipc/tree/main/contracts) |
| Commits | 5a6710409a90944ceb3ff4d8ad9edea1b00557c3, 786b6fc6678ff30addcd033b85f55dfd107e4e1c|
| Language | Solidity |
| Scope |  All Solidity contracts in https://github.com/hokunet/contracts/tree/main  <br>**Excluding**: `BucketManger.sol`, `Credit.sol`, `CreditManager.sol`, `BlobManager.sol` <br> All Solidity contracts in https://github.com/hokunet/ipc/tree/main/contracts |

## Process

- **Static Analysis:**  Auditor ran [Slither](https://github.com/crytic/slither) on the codebase to identify common vulnerabilities
- **Manual Code Review:**  Auditor ****manually reviewed the code to identify areas not following best practices and to catch potential vulnerabilities

# Audit Prep Suggestions

This section provides several suggestions on improving the code documentation in the document [here](https://www.notion.so/15adfc9427de8012a8dafd7faae5eadc?pvs=21).  

| **Suggestion** | **Reasoning** |
| --- | --- |
| Add interaction diagrams outlining how the off-chain and on-chain components interact with each other.  These diagrams should list out what function calls each component makes to each other and what they return.  <br> I suggest using [Mermaid](https://www.mermaidchart.com/) to do this | It was not immediately clear how the functions on the contracts would be called.  It would make it easier for auditors to onboard if they were given a clearer description on how the different processes worked.  For instance it is not immediately clear when `interceptPowerDelta` is called [here](https://github.com/hokunet/contracts/blob/main/src/token/ValidatorGater.sol#L74). |
| Add a Glossary at the beginning of the document | A glossary will help auditors onboard as they will have a clear definition of each of the key terms. |

# Findings

## Low

### L1:  Missing handling of `token.transfer` return value

[https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L164](https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L164)

The `notifyValidClaim` function in `ValidatorRewarder` makes a `transfer` call.  As per the ERC20 specs, some ERC20 tokens will not revert if the `transfer` call fails but will instead return `false`.  This can lead to recipients not correctly receiving any Hoku tokens when `notifyValidClaim` is called.  This scenario seems unlikely to happen with the current Hoku implementation as it uses OpenZeppelin’s ERC20 token implementation, which will either return `true` if the transfer succeeds or reverts if the transfer fails.  The team should however be careful if they ever upgrade the Hoku token contract’s implementation.

**Recommendation:**  Use OpenZeppelin’s [SafeERC20](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol) library and perform transfers using `safeTransfer`

**Resolution:** The team has addressed this [here](https://github.com/recallnet/contracts/pull/57/files#diff-4889ed1a3017fce5f4c08e5d132444ed9bee3fc43a238744441c754ce76ebcbfR173).

### L2:  `setInflationRate` missing validations

[https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L106](https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L106)

The `setInflationRate` function does not validate the new inflation rate.  This can cause problems if the contract owner accidentally sets the inflation rate to 0 or an extremely large number.

**Recommendation:**  Allow the owner to set a minimum and maximum inflation rate in the contract and ensure that the new inflation rate `rate` is within the boundaries.

**Resolution:** The team has acknowledged this and have opted to remove the `setInflationRate` function

### L3:  `initialize` function does not validate Hoku token address

[https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L65](https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L65)

The `initialize` function does not validate the `hokuToken` address that is being set. 

**Recommendation:**  Validate that the `token` address is not the zero address

**Resolution**:  The team has addressed this [here](https://github.com/recallnet/contracts/pull/57/files#diff-4889ed1a3017fce5f4c08e5d132444ed9bee3fc43a238744441c754ce76ebcbfR71)

### L4:  **`notifyValidClaim` function allows tokens to be minted to the zero address**

[https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L115](https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L115)

The `notifyValidClaim` function does not check that the `data.validator` address is the zero address.  This could lead to tokens being accidentally burnt by sending them to the zero address.

**Recommendation:**  Revert if data.validator is the zero address or check that data.validator is a valid validator address by querying the isAllow function on the ValidatorGater contract.

**Resolution:** The team ha addressed this [here](https://github.com/recallnet/contracts/pull/57/files#diff-4889ed1a3017fce5f4c08e5d132444ed9bee3fc43a238744441c754ce76ebcbfR126)

### L5:  Missing Subnet validation

[https://github.com/hokunet/contracts/blob/main/src/token/ValidatorGater.sol#L55](https://github.com/hokunet/contracts/blob/main/src/token/ValidatorGater.sol#L55)

`setSubnet` does not validate that the addresses in the `route` array are not the zero address and that the length of the `route` array is greater than 0.  

**Recommendation:**  Ensure that the `route` array’s length is greater than 0 and that the addresses in `route` are not the zero address or leave a comment explaining what the zero address represents.

**Resolution:**  The team has addressed this [here](https://github.com/recallnet/contracts/pull/57/files#diff-b4781b8ea78276fa0f2a3cd3eb429c296c7e6569f0deb7fdd4e9356d8e77b353R61-R69)

### L6:  Drip Amount drips an incorrect amount

[https://github.com/hokunet/contracts/blob/main/src/token/Faucet.sol#L30](https://github.com/hokunet/contracts/blob/main/src/token/Faucet.sol#L30)

The `_dripAmount` should be `18 ether`  assuming it’s 18 decimal places or `18 * 10 ** tokenDecimals` .  This issue has been marked as low as the contract owner can call `setDripAmount` to correct it after the contract has been deployed.

**Recommendation:**  Assign `_dripAmount` in terms of whole token units e.g `18 ether` if the Hoku token is 18dp.

**Resolution:**  The team has addressed this [here](https://github.com/recallnet/contracts/pull/57/files#diff-2dc9f797f451bc2a3ac43046dd7d72cf66ad5a9c87bf0c4e86d81b969a2be1acR34).  They have also updated the `_dripAmount` to `5 ether` from `18` wei.

## Informational

### I1:  Reentrancy in `ValidatorRewarder` `notifyValidClaim`

[https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L157](https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L157)

The `notifyValidClaim` function in `ValidatorRewarder` calls [`token.mint`](http://token.mint) twice before it updates sets `latestClaimedCheckpoint`.  A malicious `token` address could exploit this by reentering the `notifyValidClaim` call to potentially mint an infinite amount of tokens to itself without any additional guardrails.  This scenario however is prevented because of two reasons

1. The `token` address is set to the address of the Hoku token by a trusted actor at initialization by a trusted actor and cannot be changed after
2. `checkpointToSupply` is set to the total supply of the Hoku tokens prior to calling `mint` meaning that the reentering call will not try to mint more tokens.

It is nevertheless best practice to always set storage variables prior to making any external calls.

**Recommendation:**  Set `latestClaimedCheckpoint` before calling `token.mint` or add a comment explaining why there is no reentrancy vulnerability

**Resolution:** The team has addressed this by setting `latestClaimedCheckpoint` before calling `token.mint` [here](https://github.com/recallnet/contracts/pull/57/files#diff-4889ed1a3017fce5f4c08e5d132444ed9bee3fc43a238744441c754ce76ebcbfR157)

### I2:  Missing Mapping Names

[https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L46](https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L46)

[https://github.com/hokunet/contracts/blob/main/src/token/ValidatorGater.sol#L26](https://github.com/hokunet/contracts/blob/main/src/token/ValidatorGater.sol#L26)

Map keys and values should be named to improve readability so that readers know what the keys and values represent.

```solidity
mapping(uint64 => uint256) public checkpointToSupply;

can be named

mapping(uint64 checkpointId => uint256 totalSupply) public checkpointToSupply;
```

**Recommendation:**  Add names to `mapping` keys and values

**Resolution:**  The team has addded names to the `mapping` keys and values 
[here](https://github.com/recallnet/contracts/pull/57/files#diff-4889ed1a3017fce5f4c08e5d132444ed9bee3fc43a238744441c754ce76ebcbfR44)

### I3:  Missing event emissions in state changes

[https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L72](https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L72)

https://github.com/hokunet/contracts/blob/main/src/token/ValidatorGater.sol#L55

It is generally best practice to emit events whenever there is a state change so that they can be indexed off-chain.

**Recommendation:**  Emit events whenever storage variables are set.

**Resolution:**  The team has addressed this [here](https://github.com/recallnet/contracts/pull/57/files#diff-4889ed1a3017fce5f4c08e5d132444ed9bee3fc43a238744441c754ce76ebcbfR90)

### I4:  Inconsistent function returns

Some functions return unnamed variables 

[https://github.com/hokunet/contracts/blob/main/src/token/Hoku.sol#L126](https://github.com/hokunet/contracts/blob/main/src/token/Hoku.sol#L126)

Other functions return named variables

[https://github.com/hokunet/contracts/blob/main/src/token/Hoku.sol#L104](https://github.com/hokunet/contracts/blob/main/src/token/Hoku.sol#L104)

It is best practice to be consistent throughout the codebase

**Recommendation:**  Be consistent with naming function return variables

**Resolution:**  The team has acknowledged this and have opted to keep
the current return naming

### I5:  Unnecessary `<` check

[https://github.com/hokunet/contracts/blob/main/src/token/Faucet.sol#L51](https://github.com/hokunet/contracts/blob/main/src/token/Faucet.sol#L51)

It is unnecessary to check that `msg.value <= 0` as it can just be `msg.value == 0`.  `msg.value` is a `uint256`  that can never be below 0.

**Recommendation:**  Update `msg.value <= 0` to `msg.value == 0`

**Resolution:**  The team has addressed this [here](https://github.com/recallnet/contracts/pull/57/files#diff-2dc9f797f451bc2a3ac43046dd7d72cf66ad5a9c87bf0c4e86d81b969a2be1acR55)

### I6:  Inefficient `drip` function

[https://github.com/hokunet/contracts/blob/main/src/token/Faucet.sol#L62C5-L76C8](https://github.com/hokunet/contracts/blob/main/src/token/Faucet.sol#L62C5-L76C8)

The `drip` function can be optimized by 

1. Only using a single for loop and declare loop more efficiently
2. Performing the `address(this).balance < amount` check first to terminate the function earlier.
3. Handling the response from `recipient.transfer`

```solidity
 function drip(
        address payable recipient,
        string[] calldata keys
    ) external onlyOwner {
    
		    /// Terminate function early
        if (address(this).balance < amount) {
            revert FaucetEmpty();
        }

        uint256 keysLength = keys.length;
        uint256 amount = _dripAmount;
        
        /// Optimize for loop to save gas
        /// 1.  No need to initialize i = 0 as i is already initialized
        /// to 0
        /// 2.  Preincrement i instead of postincrementing by doing ++i instead
        /// of i++.  Preincrementing is cheaper than postincrementing
        for (uint256 i; i < keysLength; ++i) {
            if (_nextRequestAt[keys[i]] > block.timestamp) {
                revert TryLater();
            }
            _nextRequestAt[keys[i]] = block.timestamp + (12 hours);
        }
				
				/// Revert if transfer not successful
        (bool success,) = recipient.transfer(amount);
				
        if (!success) revert TransferNotSuccessful(recipient);
    }
```

**Resolution:**  The team has addressed this [here](https://github.com/recallnet/contracts/pull/57/files#diff-2dc9f797f451bc2a3ac43046dd7d72cf66ad5a9c87bf0c4e86d81b969a2be1acR72-R85)

### I7:  Declare roles as constants

[https://github.com/hokunet/contracts/blob/main/src/token/Hoku.sol#L33](https://github.com/hokunet/contracts/blob/main/src/token/Hoku.sol#L33)

Declaring roles as constants can save gas.  Constant variables are baked into the contract’s bytecode at compile time meaning that the contract won’t have to access storage to access it.

```solidity
bytes32 public ADMIN_ROLE; // solhint-disable-line var-name-mixedcase
bytes32 public MINTER_ROLE; // solhint-disable-line var-name-mixedcase

can be declared as

bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

instead of declaring these in the initialize function
```

**Recommendation:**  Store values constant values as `constant`.

**Resolution:**  The team has addressed this [here](https://github.com/recallnet/contracts/pull/57/files#diff-7442c860c975851e8fe0043fad4d1208282cbd29ddf95ef9b0724ac720db99cbR33-R34)

### I8:  Unnecessary `uint64` storage variable

[https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L33](https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L33)

`latestClaimedCheckpoint` can be stored as `uint256` instead of `uint64`.  Operations using `latestClaimedCheckpoint` will actually cost more gas if it is stored as `uint64` as Solidity will need to convert it into `uint256` internally before using it in any calculations as per Solidity’s [documentation](https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#layout-of-state-variables-in-storage).

**Recommendation:**  Either store `latestClaimedCheckpoint` as `uint256` or pack `latestClaimedCheckpoint`, `inflationRate` and `checkpointPeriod` into a single struct such as the one below.

```solidity
struct ValidatorRewarderStorage {
   uint64 latestClaimedCheckpoint;
   uint64 checkpointPeriod;
   uint128 inflationRate;
}

Assuming that the values will fit into the declared uints.
```

**Resolution:**  The team has acknowledged this and have opted to keep it
as `uint64` to match Filecoin's epoch height type.  They have left a comment
explaining their decision [here](https://github.com/recallnet/contracts/pull/57/files#diff-4889ed1a3017fce5f4c08e5d132444ed9bee3fc43a238744441c754ce76ebcbfR36)

### I9:  Pack `PowerRange` struct

[https://github.com/hokunet/contracts/blob/main/src/token/ValidatorGater.sol#L13](https://github.com/hokunet/contracts/blob/main/src/token/ValidatorGater.sol#L13)

Currently the `PowerRange` struct is declared as 

```solidity
struct PowerRange {
   uint256 min;
   uint256 max;
}
```

This declaration causes the struct to use 2 slots.  Depending on what the largest value of `max` will be, the struct can be stored more efficiently by declaring `min` and `max` as `uint128` so that it only takes up one storage space.

```solidity
struct PowerRange {
	uint128 min;
	uint128 max;
}
```

**Recommendation:**  Pack the `PowerRange` struct so that it only takes up a single storage space.

**Resolution:**  The team has addressed this [here](https://github.com/recallnet/contracts/pull/57/files#diff-b4781b8ea78276fa0f2a3cd3eb429c296c7e6569f0deb7fdd4e9356d8e77b353R14-R16)

### I10:  Reverting in `whenActive` modifier

[https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L83](https://github.com/hokunet/contracts/blob/main/src/token/ValidatorRewarder.sol#L83)

Currently the `whenActive` modifier will skip the function execution instead of reverting when the contract is in an inactive state.  Consider reverting instead of skipping execution to provide a better user experience as:

1. Off-chain simulators will revert and prevent the caller from accidentally executing a transaction that is not expected to do anything
2. Unused gas is refunded to the caller.

**Recommendation:**  Revert when the contract is inactive

**Resolution:**  The team has addressed this [here](https://github.com/recallnet/contracts/pull/57/files#diff-b4781b8ea78276fa0f2a3cd3eb429c296c7e6569f0deb7fdd4e9356d8e77b353R55)
