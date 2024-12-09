// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

import {BucketManager} from "../src/wrappers/BucketManager.sol";
import {LibBucket} from "../src/wrappers/LibBucket.sol";
import {LibWasm} from "../src/wrappers/LibWasm.sol";

contract DeployScript is Script {
    function run() public returns (address bucketManager) {
        address libWasmAddress;

        vm.startBroadcast();

        // Deploy LibWasm (note: other libraries in `BucketManager` are deployed automatically)
        // TODO: eventually, we'll want to deploy `LibWasm` in a standalone script and link it since it's used in all of
        // the wrappers. But, this'll be easier once the network is stable and contracts are redeployed infrequently.
        bytes memory libWasmBytecode = type(LibWasm).creationCode;
        libWasmAddress = deployLibrary(libWasmBytecode);
        require(libWasmAddress != address(0), "Failed to deploy LibWasm");

        // Deploy BucketManager
        bytes memory bucketManagerBytecode = type(BucketManager).creationCode;
        bucketManagerBytecode = abi.encodePacked(bucketManagerBytecode, libWasmAddress);
        bucketManager = deployLibrary(bucketManagerBytecode);
        require(bucketManager != address(0), "Failed to deploy BucketManager");

        vm.stopBroadcast();

        return bucketManager;
    }

    function deployLibrary(bytes memory bytecode) internal returns (address libraryAddress) {
        assembly {
            libraryAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        require(libraryAddress != address(0), "Deployment failed: address(0)");
    }
}
