// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/DynamicPriceOracle.sol";
import "../src/MockPriceFeed.sol";

contract DeployDynamicPriceOracle is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MockPriceFeed first
        MockPriceFeed priceFeed = new MockPriceFeed();
        
        // Set initial prices
        priceFeed.setPrice("ETH/USD", 2000e18);
        priceFeed.setPrice("BTC/USD", 30000e18);
        priceFeed.setPrice("LINK/USD", 15e18);

        // Deploy oracle with price feed
        DynamicPriceOracle oracle = new DynamicPriceOracle(
            300,    // 5 minute minimum update interval
            100,    // 1% base threshold
            address(priceFeed)
        );
        
        // Add initial trading pairs
        oracle.addTradingPair("ETH/USD");
        oracle.addTradingPair("BTC/USD");
        oracle.addTradingPair("LINK/USD");

        vm.stopBroadcast();
    }
}
