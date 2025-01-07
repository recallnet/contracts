#!/bin/bash

# This script should be used to run ad-hoc integration tests for the Hoku wrappers. It assumes that
# you have the localnet running on your machine, and the accounts and RPCs are hardcoded with the
# values below. It will deploy the contracts, run the tests, and print the results to the console.

set -e # Exit on any error

# Environment setup
ETH_RPC_URL="http://localhost:8645"
PRIVATE_KEY="0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"
EVM_ADDRESS=$(cast wallet address $PRIVATE_KEY)
SOURCE=$(curl -X GET http://localhost:8001/v1/node | jq '.node_id' | tr -d '"')
DIVIDER=$'\n============================\n'

echo "Running tests with environment:"
echo "- RPC URL: $ETH_RPC_URL"
echo "- Private key: $PRIVATE_KEY"
echo "- EVM address: $EVM_ADDRESS"
echo "- Iroh source: $SOURCE"
echo -e "$DIVIDER"

# Create a temporary file used when uploading objects or blobs
TEMP_FILE=$(mktemp)
echo "hello" > $TEMP_FILE

# Create a bucket with the `hoku` CLI; this seeds the network with the blob for future tests
OBJECT_KEY="hello/world"
BUCKET_ADDR=$(HOKU_PRIVATE_KEY=$PRIVATE_KEY HOKU_NETWORK=localnet hoku bucket create | jq '.address' | tr -d '"')
create_object_response=$(HOKU_PRIVATE_KEY=$PRIVATE_KEY HOKU_NETWORK=localnet hoku bu add --address $BUCKET_ADDR --key $OBJECT_KEY $TEMP_FILE)
SIZE=$(echo $create_object_response | jq '.object.size')
BLOB_HASH=$(echo $create_object_response | jq '.object.hash' | tr -d '"')

echo -e "$DIVIDER"
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

# Test addBlob
echo
echo "Testing addBlob..."
output=$(cast send --rpc-url $ETH_RPC_URL $BLOBS "addBlob((address,string,string,string,string,uint64,uint64))" \
    "(0x0000000000000000000000000000000000000000,$SOURCE,$BLOB_HASH,\"\",\"\",$SIZE,0)" \
    --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "addBlob failed"
    exit 1
fi
echo "Output: $output"

# Test getBlob
echo
echo "Testing getBlob..."
output=$(cast call --rpc-url $ETH_RPC_URL $BLOBS "getBlob(string)" "$BLOB_HASH")
if [ "$output" = "0x" ]; then
    echo "getBlob failed"
    exit 1
fi
DECODED_BLOB=$(cast abi-decode "getBlob(string)((uint64,string,(string,(string,(uint64,uint64,string,address,bool))[])[],uint8))" $output)
echo "Output: $DECODED_BLOB"

# Test getBlobStatus
echo
echo "Testing getBlobStatus..."
output=$(cast call --rpc-url $ETH_RPC_URL $BLOBS "getBlobStatus(address,string,string)" \
    "0x0000000000000000000000000000000000000000" "$BLOB_HASH" "")
if [ "$output" = "0x" ]; then
    echo "getBlobStatus failed"
    exit 1
fi
DECODED_BLOB_STATUS=$(cast abi-decode "getBlobStatus(address,string,string)(uint8)" $output)
echo "Output: $DECODED_BLOB_STATUS"

# Test getAddedBlobs
echo
echo "Testing getAddedBlobs..."
output=$(cast call --rpc-url $ETH_RPC_URL $BLOBS "getAddedBlobs(uint32)" 1)
if [ "$output" = "0x" ]; then
    echo "getAddedBlobs failed"
    exit 1
fi
DECODED_ADDED_BLOBS=$(cast abi-decode "getAddedBlobs(uint32)((string,(address,string,string)[])[])" $output)
echo "Output: $DECODED_ADDED_BLOBS"

# Test getPendingBlobs
echo
echo "Testing getPendingBlobs..."
output=$(cast call --rpc-url $ETH_RPC_URL $BLOBS "getPendingBlobs(uint32)" 1)
if [ "$output" = "0x" ]; then
    echo "getPendingBlobs failed"
    exit 1
fi
DECODED_PENDING_BLOBS=$(cast abi-decode "getPendingBlobs(uint32)((string,(address,string,string)[])[])" $output)
echo "Output: $DECODED_PENDING_BLOBS"

# Test getPendingBlobsCount
echo
echo "Testing getPendingBlobsCount..."
output=$(cast call --rpc-url $ETH_RPC_URL $BLOBS "getPendingBlobsCount()")
if [ "$output" = "0x" ]; then
    echo "getPendingBlobsCount failed"
    exit 1
fi
DECODED_PENDING_BLOBS_COUNT=$(cast abi-decode "getPendingBlobsCount()(uint64)" $output)
echo "Output: $DECODED_PENDING_BLOBS_COUNT"

# Test getPendingBytesCount
echo
echo "Testing getPendingBytesCount..."
output=$(cast call --rpc-url $ETH_RPC_URL $BLOBS "getPendingBytesCount()")
if [ "$output" = "0x" ]; then
    echo "getPendingBytesCount failed"
    exit 1
fi
DECODED_PENDING_BYTES_COUNT=$(cast abi-decode "getPendingBytesCount()(uint64)" $output)
echo "Output: $DECODED_PENDING_BYTES_COUNT"

# Test getStorageStats
echo
echo "Testing getStorageStats..."
output=$(cast call --rpc-url $ETH_RPC_URL $BLOBS "getStorageStats()")
if [ "$output" = "0x" ]; then
    echo "getStorageStats failed"
    exit 1
fi
DECODED_STORAGE_STATS=$(cast abi-decode "getStorageStats()((uint64,uint64,uint64,uint64,uint64,uint64,uint64,uint64))" $output)
echo "Output: $DECODED_STORAGE_STATS"

# Test getStorageUsage
echo
echo "Testing getStorageUsage..."
output=$(cast call --rpc-url $ETH_RPC_URL $BLOBS "getStorageUsage(address)" \
    $EVM_ADDRESS)
if [ "$output" = "0x" ]; then
    echo "getStorageUsage failed"
    exit 1
fi
DECODED_STORAGE_USAGE=$(cast abi-decode "getStorageUsage(address)(uint256)" $output)
echo "Output: $DECODED_STORAGE_USAGE"

# Test getSubnetStats
echo
echo "Testing getSubnetStats..."
output=$(cast call --rpc-url $ETH_RPC_URL $BLOBS "getSubnetStats()")
if [ "$output" = "0x" ]; then
    echo "getSubnetStats failed"
    exit 1
fi
DECODED_SUBNET_STATS=$(cast abi-decode "getSubnetStats()((uint256,uint64,uint64,uint256,uint256,uint256,uint256,uint64,uint64,uint64,uint64,uint64,uint64))" $output)
echo "Output: $DECODED_SUBNET_STATS"

# Test deleteBlob
echo
echo "Testing deleteBlob..."
output=$(cast send --rpc-url $ETH_RPC_URL $BLOBS "deleteBlob(address,string,string)" \
    "0x0000000000000000000000000000000000000000" "$BLOB_HASH" "" \
    --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "deleteBlob failed"
    exit 1
fi
echo "Output: $output"

echo
echo "BlobManager integration tests completed"

echo -e "$DIVIDER"
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

# Test createBucket
echo
echo "Testing createBucket()..."
output=$(cast send --rpc-url $ETH_RPC_URL $BUCKETS "createBucket(address,(string,string)[])" \
    "$EVM_ADDRESS" \
    "[(\"alias\",\"foo\")]" \
    --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "createBucket failed"
    exit 1
fi
echo "Output: $output"

# Test listBuckets
echo
echo "Testing listBuckets()..."
output=$(cast call --rpc-url $ETH_RPC_URL $BUCKETS "listBuckets(address)" \
    "$EVM_ADDRESS")
if [ "$output" = "0x" ]; then
    echo "listBuckets failed"
    exit 1
fi
DECODED_BUCKETS=$(cast abi-decode "listBuckets(address)((uint8,address,(string,string)[])[])" $output)
echo "Output: $DECODED_BUCKETS"

# Test addObject (both variations)
echo
echo "Testing addObject()..."
OBJECT_KEY="hello/test"
PARAMS="(\"$SOURCE\",\"$OBJECT_KEY\",\"$BLOB_HASH\",\"\",$SIZE,0,[],false)"
output=$(cast send --rpc-url $ETH_RPC_URL $BUCKETS "addObject(address,(string,string,string,string,uint64,uint64,(string,string)[],bool))" \
    "$BUCKET_ADDR" \
    "$PARAMS" \
    --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "addObject failed"
    exit 1
fi
echo "Output: $output"

# Test getObject
echo
echo "Testing getObject..."
output=$(cast call --rpc-url $ETH_RPC_URL $BUCKETS "getObject(address,string)" $BUCKET_ADDR $OBJECT_KEY)
if [ "$output" = "0x" ]; then
    echo "getObject failed"
    exit 1
fi
DECODED_OBJECT=$(cast abi-decode "getObject(address,string)((string,string,uint64,uint64,(string,string)[]))" $output)
echo "Object: $DECODED_OBJECT"

# Test queryObjects (various overloads)
echo
echo "Testing queryObjects variations..."
# Basic query
output=$(cast call --rpc-url $ETH_RPC_URL $BUCKETS "queryObjects(address)" $BUCKET_ADDR)
if [ "$output" = "0x" ]; then
    echo "queryObjects failed"
    exit 1
fi
DECODED_QUERY=$(cast abi-decode "queryObjects(address)(((string,(string,uint64,(string,string)[]))[],string[],string))" $output)
echo "Basic query: $DECODED_QUERY"

# Query with prefix
PREFIX="hello/"
output=$(cast call --rpc-url $ETH_RPC_URL $BUCKETS "queryObjects(address,string)" $BUCKET_ADDR $PREFIX)
if [ "$output" = "0x" ]; then
    echo "queryObjects with prefix failed"
    exit 1
fi
DECODED_QUERY_PREFIX=$(cast abi-decode "queryObjects(address,string)(((string,(string,uint64,(string,string)[]))[],string[],string))" $output)
echo "Query with prefix: $DECODED_QUERY_PREFIX"

# Test deleteObject
echo
echo "Testing deleteObject..."
output=$(cast send --rpc-url $ETH_RPC_URL $BUCKETS "deleteObject(address,string)" $BUCKET_ADDR "hello/world" --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "deleteObject failed"
    exit 1
fi
echo "Output: $output"
OBJECT_KEY="hello/world"

echo "BucketManager integration tests completed"

echo -e "$DIVIDER"
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
output=$(cast call --rpc-url $ETH_RPC_URL $CREDIT "getAccount(address)" $EVM_ADDRESS)
if [ "$output" = "0x" ]; then
    echo "getAccount failed"
    exit 1
fi
DECODED_ACCOUNT=$(cast abi-decode "getAccount(address)((uint64,uint256,uint256,address,uint64,(string,(uint256,uint256,uint64,uint256,uint256))[],uint64,uint256))" "$output")
echo "Account info: $DECODED_ACCOUNT"

# Test getCreditStats
echo
echo "Testing getCreditStats..."
output=$(cast call --rpc-url $ETH_RPC_URL $CREDIT "getCreditStats()")
if [ "$output" = "0x" ]; then
    echo "getCreditStats failed"
    exit 1
fi
DECODED_STATS=$(cast abi-decode "getCreditStats()((uint256,uint256,uint256,uint256,uint64,uint64))" $output)
echo "Credit stats: $DECODED_STATS"

# Test getCreditBalance
echo
echo "Testing getCreditBalance..."
output=$(cast call --rpc-url $ETH_RPC_URL $CREDIT "getCreditBalance(address)" $EVM_ADDRESS)
if [ "$output" = "0x" ]; then
    echo "getCreditBalance failed"
    exit 1
fi
DECODED_BALANCE=$(cast abi-decode "getCreditBalance(address)((uint256,uint256,address,uint64,(string,(uint256,uint256,uint64,uint256,uint256))[],uint256))" $output)
echo "Credit balance: $DECODED_BALANCE"

# Test buyCredit
echo
echo "Testing buyCredit..."
output=$(cast send --rpc-url $ETH_RPC_URL $CREDIT "buyCredit()" --value 1ether --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "buyCredit failed"
    exit 1
fi
echo "Output: $output"

# Test buyCredit for specific address
echo
echo "Testing buyCredit for specific address..."
output=$(cast send --rpc-url $ETH_RPC_URL $CREDIT "buyCredit(address)" $EVM_ADDRESS --value 1ether --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "buyCredit for specific address failed"
    exit 1
fi
echo "Output: $output"

# Test approveCredit variations
echo
echo "Testing approveCredit variations..."
# Basic approval
output=$(cast send --rpc-url $ETH_RPC_URL $CREDIT "approveCredit(address)" $RECEIVER_ADDR --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "basic approveCredit failed"
    exit 1
fi
echo "Output: $output"

# Approval with from/to
output=$(cast send --rpc-url $ETH_RPC_URL $CREDIT "approveCredit(address,address,address[])" $EVM_ADDRESS $RECEIVER_ADDR '[]' --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "approveCredit with from/to failed"
    exit 1
fi
echo "Output: $output"

# Approval with all optional fields
output=$(cast send --rpc-url $ETH_RPC_URL $CREDIT "approveCredit(address,address,address[],uint256,uint256,uint64)" \
    $EVM_ADDRESS $RECEIVER_ADDR '[]' 100 100 3600 --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "approveCredit with optional fields failed"
    exit 1
fi
echo "Output: $output"

# Test setAccountSponsor
echo
echo "Testing setAccountSponsor..."
output=$(cast send --rpc-url $ETH_RPC_URL $CREDIT "setAccountSponsor(address,address)" $EVM_ADDRESS $RECEIVER_ADDR --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "setAccountSponsor failed"
    exit 1
fi
echo "Output: $output"

# Test revokeCredit variations
echo
echo "Testing revokeCredit variations..."
# Basic revoke
output=$(cast send --rpc-url $ETH_RPC_URL $CREDIT "revokeCredit(address)" $RECEIVER_ADDR --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "basic revokeCredit failed"
    exit 1
fi
echo "Output: $output"

# Revoke with from/to/caller
output=$(cast send --rpc-url $ETH_RPC_URL $CREDIT "approveCredit(address,address,address[])" $EVM_ADDRESS $RECEIVER_ADDR "[$CALLER_ALLOWLIST_ADDR]" --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "approveCredit before revoke failed"
    exit 1
fi
echo "Output: $output"

output=$(cast send --rpc-url $ETH_RPC_URL $CREDIT "revokeCredit(address,address,address)" \
    $EVM_ADDRESS $RECEIVER_ADDR $CALLER_ALLOWLIST_ADDR --private-key $PRIVATE_KEY)
if [ "$output" = "0x" ]; then
    echo "revokeCredit with from/to/caller failed"
    exit 1
fi
echo "Output: $output"

echo
echo "CreditManager integration tests completed"
echo -e "$DIVIDER"
echo "All tests completed successfully"
