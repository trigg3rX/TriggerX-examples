// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TriggerXTemplateFactory} from "../src/TriggerXTemplateFactory.sol";

contract DeployFactory is Script {
    // Address of the already deployed BalanceMaintainer implementation
    address constant IMPLEMENTATION = 0xAc7d9b390B070ab35298e716a11933721480472D;
    address constant FACTORY = 0x0eD11AFa278a7d5FA9E174A139469A2a8DEA2B0D;

    function run() external {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.createSelectFork(vm.envString("OP_SEPOLIA_RPC"));
        vm.startBroadcast(deployerPrivateKey);

        TriggerXTemplateFactory factory = TriggerXTemplateFactory(FACTORY);

        // Deploy a test proxy
        address proxy = factory.createProxy{value: 0.0001 ether}(IMPLEMENTATION);
        console.log("Test Proxy deployed at:", proxy);

        // Stop broadcasting
        vm.stopBroadcast();
    }
}