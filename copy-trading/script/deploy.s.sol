// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {CopyTrader} from "../src/CopyTrader.sol";

contract DeployCopyTrader is Script {
    function run() external returns (CopyTrader) {
        // Load the private key from .env file
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Constants
        address whaleToken = 0x383D4a61D0B069D02cA2Db5A82003b9561d56e19;
        address whaleWallet = 0x9717387C43bee3635aD28d69702835DAC1356CC1;
        address mockDex = 0x14C373e407Bd30d3B2f393c6dbF8fb4F21A94B72;
        address keeper = 0x68605feB94a8FeBe5e1fBEF0A9D3fE6e80cEC126;

        // Create and select the fork
        vm.createSelectFork(vm.envString("OP_SEPOLIA_RPC"));

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the CopyTrader contract
        CopyTrader copyTrader = new CopyTrader(
            whaleToken,
            whaleWallet,
            mockDex,
            keeper
        );

        vm.stopBroadcast();

        return copyTrader;
    }
}
