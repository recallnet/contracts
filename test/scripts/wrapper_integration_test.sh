#!/bin/bash

# This script should be used to run ad-hoc integration tests for the Hoku wrappers. It assumes that
# you have the localnet running on your machine, and the accounts and RPCs are hardcoded with the
# values below. It will deploy the contracts, run the tests, and print the results to the console.

set -e # Exit on any error

# Environment setup
ETH_RPC_URL="http://localhost:8645"
PRIVATE_KEY="0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"
EVM_ADDRESS="0x90f79bf6eb2c4f870365e785982e1f101e93b906"
SOURCE=$(curl -X GET http://localhost:8001/v1/node | jq '.node_id' | tr -d '"')
DIVIDER="\n============================\n"

# Create a temporary file used when uploading objects or blobs
TEMP_FILE=$(mktemp)
echo "hello" > $TEMP_FILE

# Create a bucket with the `hoku` CLI; this seeds the network with the blob for future tests
OBJECT_KEY="hello/world"
BUCKET_ADDR=$(HOKU_PRIVATE_KEY=$PRIVATE_KEY HOKU_NETWORK=localnet hoku bucket create | jq '.address' | tr -d '"')
create_object_response=$(HOKU_PRIVATE_KEY=$PRIVATE_KEY HOKU_NETWORK=localnet hoku bu add --address $BUCKET_ADDR --key $OBJECT_KEY $TEMP_FILE)
SIZE=$(echo $create_object_response | jq '.object.size')
BLOB_HASH=$(echo $create_object_response | jq '.object.hash' | tr -d '"')

echo $DIVIDER
echo "Running BlobManager integration tests..."
BLOBS=$(forge script script/BlobManager.s.sol \
    --tc DeployScript \
    --sig 'run()' \
    --rpc-url $ETH_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    -g 100000 \
    | grep "0: contract BlobManager" | awk '{print $NF}')

echo "Using BlobManager: $BLOBS"

# Test getAccountType
echo
echo "Testing getAccountType..."
cast call --rpc-url $ETH_RPC_URL $BLOBS "getAccountType(address)" $EVM_ADDRESS

# Test addBlob
echo
echo "Testing addBlob..."
cast send --rpc-url $ETH_RPC_URL $BLOBS "addBlob((address,string,string,string,string,uint64,uint64))" \
    "(0x0000000000000000000000000000000000000000,$SOURCE,$BLOB_HASH,\"\",\"\",$SIZE,0)" \
    --private-key $PRIVATE_KEY

# Test getBlob
echo
echo "Testing getBlob..."
cast call --rpc-url $ETH_RPC_URL $BLOBS "getBlob(string)" "$BLOB_HASH"

# Test getBlobStatus
echo
echo "Testing getBlobStatus..."
cast call --rpc-url $ETH_RPC_URL $BLOBS "getBlobStatus(address,string,string)" \
    "0x0000000000000000000000000000000000000000" "$BLOB_HASH" ""

# Test getAddedBlobs
echo
echo "Testing getAddedBlobs..."
cast call --rpc-url $ETH_RPC_URL $BLOBS "getAddedBlobs(uint32)" 1

# Test getPendingBlobs
echo
echo "Testing getPendingBlobs..."
cast call --rpc-url $ETH_RPC_URL $BLOBS "getPendingBlobs(uint32)" 1

# Test getPendingBlobsCount
echo
echo "Testing getPendingBlobsCount..."
cast call --rpc-url $ETH_RPC_URL $BLOBS "getPendingBlobsCount()"

# Test getPendingBytesCount
echo
echo "Testing getPendingBytesCount..."
cast call --rpc-url $ETH_RPC_URL $BLOBS "getPendingBytesCount()"

# Test getStorageStats
echo
echo "Testing getStorageStats..."
cast call --rpc-url $ETH_RPC_URL $BLOBS "getStorageStats()"

# Test getStorageUsage
echo
echo "Testing getStorageUsage..."
cast call --rpc-url $ETH_RPC_URL $BLOBS "getStorageUsage(address)" \
    $EVM_ADDRESS

# Test getSubnetStats
echo
echo "Testing getSubnetStats..."
cast call --rpc-url $ETH_RPC_URL $BLOBS "getSubnetStats()"

# Test deleteBlob
echo
echo "Testing deleteBlob..."
cast send --rpc-url $ETH_RPC_URL $BLOBS "deleteBlob(address,string,string)" \
    "0x0000000000000000000000000000000000000000" "$BLOB_HASH" "" \
    --private-key $PRIVATE_KEY

echo
echo "BlobManager integration tests completed"

echo $DIVIDER
echo "Running BucketManager integration tests..."
BUCKETS=$(forge script script/BucketManager.s.sol \
    --tc DeployScript \
    --sig 'run()' \
    --rpc-url $ETH_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    -g 100000 \
    | grep "0: contract BucketManager" | awk '{print $NF}')

echo "Using BucketManager: $BUCKETS"
echo "Using bucket address: $BUCKET_ADDR"

# Test addObject (both variations)
echo
echo "Testing addObject()..."
OBJECT_KEY="hello/test"
PARAMS="(\"$SOURCE\",\"$OBJECT_KEY\",\"$BLOB_HASH\",\"\",$SIZE,0,[],false)"
cast send --rpc-url $ETH_RPC_URL $BUCKETS "addObject(string,(string,string,string,string,uint64,uint64,(string,string)[],bool))" \
    "$BUCKET_ADDR" \
    "$PARAMS" \
    --private-key $PRIVATE_KEY

# Test getObject
echo
echo "Testing getObject..."
OBJECT=$(cast call --rpc-url $ETH_RPC_URL $BUCKETS "getObject(string,string)" $BUCKET_ADDR $OBJECT_KEY)
DECODED_OBJECT=$(cast abi-decode "getObject(string,string)((string,string,uint64,uint64,(string,string)[]))" $OBJECT)
echo "Object: $DECODED_OBJECT"

# Test queryObjects (various overloads)
echo
echo "Testing queryObjects variations..."
# Basic query
QUERY=$(cast call --rpc-url $ETH_RPC_URL $BUCKETS "queryObjects(string)" $BUCKET_ADDR)
DECODED_QUERY=$(cast abi-decode "queryObjects(string)(((string,(string,uint64,(string,string)[]))[],string[],string))" $QUERY)
echo "Basic query: $DECODED_QUERY"

# Query with prefix
PREFIX="hello/"
QUERY_WITH_PREFIX=$(cast call --rpc-url $ETH_RPC_URL $BUCKETS "queryObjects(string,string)" $BUCKET_ADDR $PREFIX)
DECODED_QUERY_PREFIX=$(cast abi-decode "queryObjects(string,string)(((string,(string,uint64,(string,string)[]))[],string[],string))" $QUERY_WITH_PREFIX)
echo "Query with prefix: $DECODED_QUERY_PREFIX"

# Test deleteObject
echo
echo "Testing deleteObject..."
cast send --rpc-url $ETH_RPC_URL $BUCKETS "deleteObject(string,string)" $BUCKET_ADDR "hello/world" --private-key $PRIVATE_KEY
OBJECT_KEY="hello/world"

echo "BucketManager integration tests completed"

echo $DIVIDER
echo "Running CreditManager integration tests..."
CREDIT=$(forge script script/CreditManager.s.sol \
    --tc DeployScript \
    --sig 'run()' \
    --rpc-url $ETH_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    -g 100000 \
    | grep "0: contract CreditManager" | awk '{print $NF}')

echo "Using CreditManager: $CREDIT"
RECEIVER_ADDR=0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
CALLER_ALLOWLIST_ADDR=0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc

# Test getAccount
echo
echo "Testing getAccount..."
ACCOUNT="$(cast call --rpc-url $ETH_RPC_URL $CREDIT "getAccount(address)" $EVM_ADDRESS)"
DECODED_ACCOUNT="$(cast abi-decode "getAccount(address)((uint64,uint256,uint256,address,uint64,(string,(uint256,uint256,uint64,uint256,uint256,address[]))[],uint64,uint256))" "$ACCOUNT")"
echo "Account info: $DECODED_ACCOUNT"

# Test getCreditStats
echo
echo "Testing getCreditStats..."
STATS=$(cast call --rpc-url $ETH_RPC_URL $CREDIT "getCreditStats()")
DECODED_STATS=$(cast abi-decode "getCreditStats()((uint256,uint256,uint256,uint256,uint64,uint64))" $STATS)
echo "Credit stats: $DECODED_STATS"

# Test getCreditBalance
echo
echo "Testing getCreditBalance..."
BALANCE=$(cast call --rpc-url $ETH_RPC_URL $CREDIT "getCreditBalance(address)" $EVM_ADDRESS)
DECODED_BALANCE=$(cast abi-decode "getCreditBalance(address)((uint256,uint256,address,uint64,(string,(uint256,uint256,uint64,uint256,uint256,address[]))[]))" $BALANCE)
echo "Credit balance: $DECODED_BALANCE"

# Test buyCredit
echo
echo "Testing buyCredit..."
cast send --rpc-url $ETH_RPC_URL $CREDIT "buyCredit()" --value 1ether --private-key $PRIVATE_KEY

# Test buyCredit for specific address
echo
echo "Testing buyCredit for specific address..."
cast send --rpc-url $ETH_RPC_URL $CREDIT "buyCredit(address)" $EVM_ADDRESS --value 1ether --private-key $PRIVATE_KEY

# Test approveCredit variations
echo
echo "Testing approveCredit variations..."
# Basic approval
cast send --rpc-url $ETH_RPC_URL $CREDIT "approveCredit(address)" $RECEIVER_ADDR --private-key $PRIVATE_KEY

# Approval with from/to
cast send --rpc-url $ETH_RPC_URL $CREDIT "approveCredit(address,address,address[])" $EVM_ADDRESS $RECEIVER_ADDR '[]' --private-key $PRIVATE_KEY

# Approval with all optional fields
cast send --rpc-url $ETH_RPC_URL $CREDIT "approveCredit(address,address,address[],uint256,uint256,uint64)" \
    $EVM_ADDRESS $RECEIVER_ADDR '[]' 100 100 3600 --private-key $PRIVATE_KEY

# Test setCreditSponsor
echo
echo "Testing setCreditSponsor..."
cast send --rpc-url $ETH_RPC_URL $CREDIT "setCreditSponsor(address,address)" $EVM_ADDRESS $RECEIVER_ADDR --private-key $PRIVATE_KEY

# Test revokeCredit variations
echo
echo "Testing revokeCredit variations..."
# Basic revoke
cast send --rpc-url $ETH_RPC_URL $CREDIT "revokeCredit(address)" $RECEIVER_ADDR --private-key $PRIVATE_KEY

# Revoke with from/to/caller
cast send --rpc-url $ETH_RPC_URL $CREDIT "approveCredit(address,address,address[])" $EVM_ADDRESS $RECEIVER_ADDR "[$CALLER_ALLOWLIST_ADDR]" --private-key $PRIVATE_KEY
cast send --rpc-url $ETH_RPC_URL $CREDIT "revokeCredit(address,address,address)" \
    $EVM_ADDRESS $RECEIVER_ADDR $CALLER_ALLOWLIST_ADDR --private-key $PRIVATE_KEY

echo
echo "CreditManager integration tests completed"
echo $DIVIDER
echo "All tests completed successfully"
