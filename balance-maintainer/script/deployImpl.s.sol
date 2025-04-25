// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/BalanceMaintainer.sol";

contract DeployBalanceMaintainer is Script {
    function run() external {
        // Get the private key and API keys from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory opScanKey = vm.envString("OPSCAN_API_KEY");
        string memory baseScanKey = vm.envString("BASESCAN_API_KEY");
        
        // Deploy to Optimism Sepolia
        console.log("Deploying to Optimism Sepolia...");
        vm.createSelectFork(vm.envString("OP_SEPOLIA_RPC"));
        vm.startBroadcast(deployerPrivateKey);
        BalanceMaintainer balanceMaintainer = new BalanceMaintainer{salt: bytes32("BalanceMaintainer")}();
        vm.stopBroadcast();
        console.log("BalanceMaintainer deployed on Optimism Sepolia at:", address(balanceMaintainer));

        // Verify on Optimism Sepolia
        string[] memory verifyOpCommand = new string[](10);  // Fixed array size to 10
        verifyOpCommand[0] = "forge";
        verifyOpCommand[1] = "verify-contract";
        verifyOpCommand[2] = vm.toString(address(balanceMaintainer));
        verifyOpCommand[3] = "BalanceMaintainer";
        verifyOpCommand[4] = "--chain-id";
        verifyOpCommand[5] = "11155420";
        verifyOpCommand[6] = "--verifier-url";
        verifyOpCommand[7] = "https://api-sepolia-optimistic.etherscan.io/api";
        verifyOpCommand[8] = "--etherscan-api-key";
        verifyOpCommand[9] = opScanKey;
        vm.ffi(verifyOpCommand);
        
        // Deploy to Base Sepolia
        console.log("\nDeploying to Base Sepolia...");
        vm.createSelectFork(vm.envString("BASE_SEPOLIA_RPC"));
        vm.startBroadcast(deployerPrivateKey);
        BalanceMaintainer baseimpl = new BalanceMaintainer{salt: bytes32("BalanceMaintainer")}();
        vm.stopBroadcast();
        console.log("BalanceMaintainer deployed on Base Sepolia at:", address(baseimpl));

        // Verify on Base Sepolia
        string[] memory verifyBaseCommand = new string[](10);  // Fixed array size to 10
        verifyBaseCommand[0] = "forge";
        verifyBaseCommand[1] = "verify-contract";
        verifyBaseCommand[2] = vm.toString(address(baseimpl));
        verifyBaseCommand[3] = "BalanceMaintainer";
        verifyBaseCommand[4] = "--chain-id";
        verifyBaseCommand[5] = "84532";
        verifyBaseCommand[6] = "--verifier-url";
        verifyBaseCommand[7] = "https://api-sepolia.basescan.org/api";
        verifyBaseCommand[8] = "--etherscan-api-key";
        verifyBaseCommand[9] = baseScanKey;
        vm.ffi(verifyBaseCommand);
    }
}