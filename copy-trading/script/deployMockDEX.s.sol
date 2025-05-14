// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {MockDEX} from "../src/MockDEX.sol";

contract DeployMockDEX is Script {
    function run() external returns (MockDEX) {
        // Load the private key from .env file
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get the WhaleToken address from .env (optional, you can hardcode if needed)
        address whaleTokenAddress = 0x383D4a61D0B069D02cA2Db5A82003b9561d56e19;

        // Create and select the fork
        vm.createSelectFork(vm.envString("OP_SEPOLIA_RPC"));

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the MockDEX contract
        MockDEX mockDex = new MockDEX(whaleTokenAddress);

        vm.stopBroadcast();

        return mockDex;
    }
}
