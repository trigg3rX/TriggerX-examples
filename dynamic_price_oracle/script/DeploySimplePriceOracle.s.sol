// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {SimplePriceOracle} from "../src/SimplePriceOracle.sol";

contract DeploySimplePriceOracle is Script {
    function run() external returns (SimplePriceOracle) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy and initialize
        SimplePriceOracle oracle = new SimplePriceOracle();
        oracle.initialize(deployer);
        
        vm.stopBroadcast();

        return oracle;
    }
}