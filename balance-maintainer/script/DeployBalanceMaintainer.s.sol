// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/BalanceMaintainer.sol";

contract DeployBalanceMaintainer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        console.log("address of Deployer :", vm.addr(deployerPrivateKey));
        console.log("Deployer balance:", (vm.addr(deployerPrivateKey).balance));
        // Deploy the contract with 1 ETH
        BalanceMaintainer balanceMaintainer = new BalanceMaintainer{
            value: 0.001 ether
        }();

        // Stop broadcasting
        vm.stopBroadcast();

        console.log(
            "BalanceMaintainer deployed at:",
            address(balanceMaintainer)
        );
        console.log(
            "BalanceMaintainer balance:",
            address(balanceMaintainer).balance
        );
    }
}
