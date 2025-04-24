// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BalanceMaintainerFactory} from "../src/newBalanceMaintainerFactory.sol";

contract DeployFactory is Script {
    // Address of the already deployed BalanceMaintainer implementation
    address constant IMPLEMENTATION = 0x597411AE9b34E656b8900B16ed766E90c3eBC31c;

    function run() external {
        // Load private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.createSelectFork(vm.envString("OP_SEPOLIA_RPC"));
        vm.startBroadcast(deployerPrivateKey);

        // Deploy BalanceMaintainerFactory
        BalanceMaintainerFactory factory = new BalanceMaintainerFactory(IMPLEMENTATION);
        console.log("BalanceMaintainerFactory deployed at:", address(factory));

        // Deploy a test proxy
        address proxy = factory.createBalanceMaintainer{value: 1 ether}();
        console.log("Test Proxy deployed at:", proxy);

        // Stop broadcasting
        vm.stopBroadcast();
    }
}