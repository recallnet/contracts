// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

import {BlobManager} from "../src/wrappers/BlobManager.sol";
import {LibWasm} from "../src/wrappers/LibWasm.sol";

contract DeployScript is Script {
    function run() public returns (address blobManager) {
        address libWasmAddress;

        vm.startBroadcast();

        // Deploy LibWasm (note: other libraries in `BlobManager` are deployed automatically)
        // TODO: eventually, we'll want to deploy `LibWasm` in a standalone script and link it since it's used in all of
        // the wrappers. But, this'll be easier once the network is stable and contracts are redeployed infrequently.
        bytes memory libWasmBytecode = type(LibWasm).creationCode;
        libWasmAddress = deployLibrary(libWasmBytecode);
        require(libWasmAddress != address(0), "Failed to deploy LibWasm");

        // Deploy BlobManager
        bytes memory blobManagerBytecode = type(BlobManager).creationCode;
        blobManagerBytecode = abi.encodePacked(blobManagerBytecode, libWasmAddress);
        blobManager = deployLibrary(blobManagerBytecode);
        require(blobManager != address(0), "Failed to deploy BlobManager");

        vm.stopBroadcast();

        return blobManager;
    }

    function deployLibrary(bytes memory bytecode) internal returns (address libraryAddress) {
        assembly {
            libraryAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        require(libraryAddress != address(0), "Deployment failed: address(0)");
    }
}
