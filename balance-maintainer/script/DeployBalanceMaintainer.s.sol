// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/BalanceMaintainer.sol";

contract DeployBalanceMaintainer is Script {
    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the contract with 1 ETH
        BalanceMaintainer balanceMaintainer = new BalanceMaintainer{value: 1 ether}();

        // Stop broadcasting
        vm.stopBroadcast();

        console.log("BalanceMaintainer deployed at:", address(balanceMaintainer));
        console.log("BalanceMaintainer balance:", address(balanceMaintainer).balance);
    }
}
