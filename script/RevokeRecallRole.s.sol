// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.26;

import {Recall} from "../src/token/Recall.sol";
import {Script, console} from "forge-std/Script.sol";

/**
 * @title RevokeRecallRole Script
 * @notice Forge script to revoke roles from accounts on a deployed Recall contract
 * @dev This script provides multiple ways to revoke roles:
 *      1. Single role revocation from one account
 *      2. Batch revocation of multiple roles from one account
 *      3. Revocation of one role from multiple accounts
 *
 * USAGE EXAMPLES:
 *
 * 1. Using environment variables with private key:
 *    PROXY_ADDR=0x... ROLE_TYPE=MINTER ACCOUNT=0x... \
 *    forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
 *      --rpc-url $RPC_URL \
 *      --broadcast \
 *      --private-key $PRIVATE_KEY
 *
 * 2. Using Ledger hardware wallet:
 *    PROXY_ADDR=0x... ROLE_TYPE=MINTER ACCOUNT=0x... \
 *    forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
 *      --rpc-url $RPC_URL \
 *      --broadcast \
 *      --ledger \
 *      --sender 0xYOUR_LEDGER_ADDRESS
 *
 *    Note: You can also specify the HD derivation path:
 *    --ledger --hd-paths "m/44'/60'/0'/0/0"
 *
 * 3. Using Trezor hardware wallet:
 *    PROXY_ADDR=0x... ROLE_TYPE=MINTER ACCOUNT=0x... \
 *    forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
 *      --rpc-url $RPC_URL \
 *      --broadcast \
 *      --trezor \
 *      --sender 0xYOUR_TREZOR_ADDRESS
 *
 * 4. Using function parameters with Ledger:
 *    forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
 *      --rpc-url $RPC_URL \
 *      --broadcast \
 *      --ledger \
 *      --sender 0xYOUR_LEDGER_ADDRESS \
 *      -s "run(address,string,address)" \
 *      0xPROXY_ADDRESS "MINTER" 0xACCOUNT_ADDRESS
 *
 * 5. Batch revoke multiple roles from one account (with Ledger):
 *    forge script script/RevokeRecallRole.s.sol:BatchRevokeScript \
 *      --rpc-url $RPC_URL \
 *      --broadcast \
 *      --ledger \
 *      --sender 0xYOUR_LEDGER_ADDRESS
 *
 * 6. Revoke one role from multiple accounts (with Ledger):
 *    forge script script/RevokeRecallRole.s.sol:MultiAccountRevokeScript \
 *      --rpc-url $RPC_URL \
 *      --broadcast \
 *      --ledger \
 *      --sender 0xYOUR_LEDGER_ADDRESS
 *
 * 7. Dry run (simulate without broadcasting) with Ledger:
 *    PROXY_ADDR=0x... ROLE_TYPE=MINTER ACCOUNT=0x... \
 *    forge script script/RevokeRecallRole.s.sol:RevokeRoleScript \
 *      --rpc-url $RPC_URL \
 *      --ledger \
 *      --sender 0xYOUR_LEDGER_ADDRESS
 *    (Note: omit --broadcast flag for simulation only)
 *
 * ENVIRONMENT VARIABLES:
 * - PROXY_ADDR: Address of the deployed Recall proxy contract (required)
 * - ROLE_TYPE: Role to revoke - "ADMIN", "MINTER", or "PAUSER" (required for single revoke)
 * - ACCOUNT: Address to revoke the role from (required for single revoke)
 * - ALLOW_SELF_ADMIN_REVOKE: Set to "true" to allow revoking ADMIN_ROLE from yourself (default: false)
 * - PRIVATE_KEY: Private key of account with ADMIN_ROLE (only if not using hardware wallet)
 *
 * HARDWARE WALLET SUPPORT:
 * This script fully supports hardware wallets (Ledger, Trezor) via Foundry's built-in flags:
 * - --ledger: Use Ledger hardware wallet
 * - --trezor: Use Trezor hardware wallet
 * - --sender: Specify the address from your hardware wallet (required with --ledger/--trezor)
 * - --hd-paths: Specify custom HD derivation path (optional, default: "m/44'/60'/0'/0/0")
 *
 * When using a hardware wallet:
 * 1. Connect your device and unlock it
 * 2. Open the Ethereum app on your device
 * 3. Run the script with --ledger or --trezor flag
 * 4. Confirm the transaction on your device when prompted
 *
 * SAFETY FEATURES:
 * - Verifies caller has ADMIN_ROLE before attempting revocation
 * - Checks if target account has the role before revoking
 * - Prevents accidental self-revocation of ADMIN_ROLE (unless explicitly allowed)
 * - Displays role status before and after revocation
 */
contract RevokeRoleScript is Script {
    // Custom errors
    error InvalidRoleType(string roleType);
    error CallerNotAdmin(address caller);
    error AccountDoesNotHaveRole(address account, bytes32 role);
    error CannotRevokeSelfAdmin();
    error InvalidProxyAddress();
    error InvalidAccountAddress();

    /**
     * @notice Main entry point using environment variables
     * @dev Reads PROXY_ADDR, ROLE_TYPE, and ACCOUNT from environment
     */
    function run() public {
        address proxyAddr = vm.envAddress("PROXY_ADDR");
        string memory roleType = vm.envString("ROLE_TYPE");
        address account = vm.envAddress("ACCOUNT");

        run(proxyAddr, roleType, account);
    }

    /**
     * @notice Main entry point with direct parameters
     * @param proxyAddr Address of the deployed Recall proxy contract
     * @param roleType Role to revoke: "ADMIN", "MINTER", or "PAUSER"
     * @param account Address to revoke the role from
     */
    function run(address proxyAddr, string memory roleType, address account) public {
        // Validate inputs
        if (proxyAddr == address(0)) revert InvalidProxyAddress();
        if (account == address(0)) revert InvalidAccountAddress();

        Recall recall = Recall(proxyAddr);
        bytes32 role = getRoleHash(recall, roleType);

        console.log("=== Recall Role Revocation ===");
        console.log("Proxy Address:", proxyAddr);
        console.log("Role Type:", roleType);
        console.log("Account:", account);
        console.log("Caller:", msg.sender);
        console.log("");

        // Check caller has ADMIN_ROLE
        if (!recall.hasRole(recall.ADMIN_ROLE(), msg.sender)) {
            revert CallerNotAdmin(msg.sender);
        }
        console.log("[OK] Caller has ADMIN_ROLE");

        // Check if account has the role
        if (!recall.hasRole(role, account)) {
            revert AccountDoesNotHaveRole(account, role);
        }
        console.log("[OK] Account has the role");

        // Safety check: prevent self-revocation of ADMIN_ROLE unless explicitly allowed
        if (role == recall.ADMIN_ROLE() && account == msg.sender) {
            bool allowSelfRevoke = vm.envOr("ALLOW_SELF_ADMIN_REVOKE", false);
            if (!allowSelfRevoke) {
                revert CannotRevokeSelfAdmin();
            }
            console.log("[WARNING] Revoking ADMIN_ROLE from yourself!");
        }

        // Display current role status
        console.log("");
        console.log("Current Role Status:");
        displayRoleStatus(recall, account);

        // Perform revocation
        vm.startBroadcast();
        recall.revokeRole(role, account);
        vm.stopBroadcast();

        console.log("");
        console.log("[OK] Role revoked successfully");
        console.log("");
        console.log("Updated Role Status:");
        displayRoleStatus(recall, account);
    }

    /**
     * @notice Get the bytes32 hash for a role type string
     * @param recall The Recall contract instance
     * @param roleType Role type string: "ADMIN", "MINTER", or "PAUSER"
     * @return The bytes32 role hash
     */
    function getRoleHash(Recall recall, string memory roleType) internal view returns (bytes32) {
        bytes32 roleHash = keccak256(bytes(roleType));

        if (roleHash == keccak256("ADMIN")) {
            return recall.ADMIN_ROLE();
        } else if (roleHash == keccak256("MINTER")) {
            return recall.MINTER_ROLE();
        } else if (roleHash == keccak256("PAUSER")) {
            return recall.PAUSER_ROLE();
        } else {
            revert InvalidRoleType(roleType);
        }
    }

    /**
     * @notice Display the role status for an account
     * @param recall The Recall contract instance
     * @param account The account to check
     */
    function displayRoleStatus(Recall recall, address account) internal view {
        bool hasAdmin = recall.hasRole(recall.ADMIN_ROLE(), account);
        bool hasMinter = recall.hasRole(recall.MINTER_ROLE(), account);
        bool hasPauser = recall.hasRole(recall.PAUSER_ROLE(), account);

        console.log("  ADMIN_ROLE:", hasAdmin ? "YES" : "NO");
        console.log("  MINTER_ROLE:", hasMinter ? "YES" : "NO");
        console.log("  PAUSER_ROLE:", hasPauser ? "YES" : "NO");
    }
}

/**
 * @title BatchRevokeScript
 * @notice Script to revoke multiple roles from a single account
 * @dev Environment variables:
 *      - PROXY_ADDR: Recall proxy address
 *      - ACCOUNT: Account to revoke roles from
 *      - REVOKE_ADMIN: "true" to revoke ADMIN_ROLE (optional)
 *      - REVOKE_MINTER: "true" to revoke MINTER_ROLE (optional)
 *      - REVOKE_PAUSER: "true" to revoke PAUSER_ROLE (optional)
 */
contract BatchRevokeScript is Script {
    function run() public {
        address proxyAddr = vm.envAddress("PROXY_ADDR");
        address account = vm.envAddress("ACCOUNT");

        bool revokeAdmin = vm.envOr("REVOKE_ADMIN", false);
        bool revokeMinter = vm.envOr("REVOKE_MINTER", false);
        bool revokePauser = vm.envOr("REVOKE_PAUSER", false);

        Recall recall = Recall(proxyAddr);

        console.log("=== Batch Role Revocation ===");
        console.log("Proxy Address:", proxyAddr);
        console.log("Account:", account);
        console.log("Caller:", msg.sender);
        console.log("");
        console.log("Roles to revoke:");
        console.log("  ADMIN_ROLE:", revokeAdmin ? "YES" : "NO");
        console.log("  MINTER_ROLE:", revokeMinter ? "YES" : "NO");
        console.log("  PAUSER_ROLE:", revokePauser ? "YES" : "NO");
        console.log("");

        // Display current status
        console.log("Current Role Status:");
        displayRoleStatus(recall, account);

        vm.startBroadcast();

        if (revokeAdmin && recall.hasRole(recall.ADMIN_ROLE(), account)) {
            if (account == msg.sender) {
                bool allowSelfRevoke = vm.envOr("ALLOW_SELF_ADMIN_REVOKE", false);
                require(allowSelfRevoke, "Cannot revoke ADMIN_ROLE from yourself");
            }
            recall.revokeRole(recall.ADMIN_ROLE(), account);
            console.log("[OK] Revoked ADMIN_ROLE");
        }

        if (revokeMinter && recall.hasRole(recall.MINTER_ROLE(), account)) {
            recall.revokeRole(recall.MINTER_ROLE(), account);
            console.log("[OK] Revoked MINTER_ROLE");
        }

        if (revokePauser && recall.hasRole(recall.PAUSER_ROLE(), account)) {
            recall.revokeRole(recall.PAUSER_ROLE(), account);
            console.log("[OK] Revoked PAUSER_ROLE");
        }

        vm.stopBroadcast();

        console.log("");
        console.log("Updated Role Status:");
        displayRoleStatus(recall, account);
    }

    function displayRoleStatus(Recall recall, address account) internal view {
        bool hasAdmin = recall.hasRole(recall.ADMIN_ROLE(), account);
        bool hasMinter = recall.hasRole(recall.MINTER_ROLE(), account);
        bool hasPauser = recall.hasRole(recall.PAUSER_ROLE(), account);

        console.log("  ADMIN_ROLE:", hasAdmin ? "YES" : "NO");
        console.log("  MINTER_ROLE:", hasMinter ? "YES" : "NO");
        console.log("  PAUSER_ROLE:", hasPauser ? "YES" : "NO");
    }
}

/**
 * @title MultiAccountRevokeScript
 * @notice Script to revoke a single role from multiple accounts
 * @dev Environment variables:
 *      - PROXY_ADDR: Recall proxy address
 *      - ROLE_TYPE: Role to revoke ("ADMIN", "MINTER", or "PAUSER")
 *      - ACCOUNTS: Comma-separated list of addresses (e.g., "0x123...,0x456...,0x789...")
 */
contract MultiAccountRevokeScript is Script {
    function run() public {
        address proxyAddr = vm.envAddress("PROXY_ADDR");
        string memory roleType = vm.envString("ROLE_TYPE");
        string memory accountsStr = vm.envString("ACCOUNTS");

        Recall recall = Recall(proxyAddr);
        bytes32 role = getRoleHash(recall, roleType);

        console.log("=== Multi-Account Role Revocation ===");
        console.log("Proxy Address:", proxyAddr);
        console.log("Role Type:", roleType);
        console.log("Caller:", msg.sender);
        console.log("");

        // Parse comma-separated addresses
        address[] memory accounts = parseAddresses(accountsStr);
        console.log("Number of accounts:", accounts.length);
        console.log("");

        vm.startBroadcast();

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            console.log("Processing account", i + 1, ":", account);

            if (recall.hasRole(role, account)) {
                // Safety check for self-admin revocation
                if (role == recall.ADMIN_ROLE() && account == msg.sender) {
                    bool allowSelfRevoke = vm.envOr("ALLOW_SELF_ADMIN_REVOKE", false);
                    if (!allowSelfRevoke) {
                        console.log("  [WARNING] Skipping: Cannot revoke ADMIN_ROLE from yourself");
                        continue;
                    }
                }

                recall.revokeRole(role, account);
                console.log("  [OK] Role revoked");
            } else {
                console.log("  [WARNING] Skipping: Account does not have the role");
            }
        }

        vm.stopBroadcast();
        console.log("");
        console.log("[OK] Multi-account revocation completed");
    }

    function getRoleHash(Recall recall, string memory roleType) internal view returns (bytes32) {
        bytes32 roleHash = keccak256(bytes(roleType));

        if (roleHash == keccak256("ADMIN")) {
            return recall.ADMIN_ROLE();
        } else if (roleHash == keccak256("MINTER")) {
            return recall.MINTER_ROLE();
        } else if (roleHash == keccak256("PAUSER")) {
            return recall.PAUSER_ROLE();
        } else {
            revert("Invalid role type");
        }
    }

    function parseAddresses(string memory addressesStr) internal pure returns (address[] memory) {
        // Simple parser for comma-separated addresses
        // Count commas to determine array size
        bytes memory strBytes = bytes(addressesStr);
        uint256 count = 1;
        for (uint256 i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == ",") {
                count++;
            }
        }

        address[] memory addresses = new address[](count);
        uint256 index = 0;
        uint256 start = 0;

        for (uint256 i = 0; i <= strBytes.length; i++) {
            if (i == strBytes.length || strBytes[i] == ",") {
                // Extract substring
                bytes memory addrBytes = new bytes(i - start);
                for (uint256 j = 0; j < i - start; j++) {
                    addrBytes[j] = strBytes[start + j];
                }

                // Trim whitespace and convert to address
                string memory addrStr = string(addrBytes);
                addresses[index] = vm.parseAddress(trim(addrStr));
                index++;
                start = i + 1;
            }
        }

        return addresses;
    }

    function trim(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        uint256 start = 0;
        uint256 end = strBytes.length;

        // Trim leading whitespace
        while (start < end && (strBytes[start] == " " || strBytes[start] == "\t")) {
            start++;
        }

        // Trim trailing whitespace
        while (end > start && (strBytes[end - 1] == " " || strBytes[end - 1] == "\t")) {
            end--;
        }

        bytes memory trimmed = new bytes(end - start);
        for (uint256 i = 0; i < end - start; i++) {
            trimmed[i] = strBytes[start + i];
        }

        return string(trimmed);
    }
}