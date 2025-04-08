// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/DynamicPriceOracle.sol";
import "../src/MockPriceFeed.sol";

contract DynamicPriceOracleTest is Test {
    DynamicPriceOracle public oracle;
    MockPriceFeed public priceFeed;
    address public owner;

    // Test prices
    uint256 constant ETH_PRICE = 2000e18;
    uint256 constant BTC_PRICE = 30000e18;
    uint256 constant LINK_PRICE = 15e18;

    function setUp() public {
        owner = address(this);

        // Deploy MockPriceFeed first
        priceFeed = new MockPriceFeed();

        // Set initial prices
        priceFeed.setPrice("ETH/USD", ETH_PRICE);
        priceFeed.setPrice("BTC/USD", BTC_PRICE);
        priceFeed.setPrice("LINK/USD", LINK_PRICE);

        // Deploy oracle with price feed
        oracle = new DynamicPriceOracle(
            300, // 5 min interval
            100, // 1% base threshold
            address(priceFeed)
        );

        // Add initial trading pairs
        oracle.addTradingPair("ETH/USD");
        oracle.addTradingPair("BTC/USD");
        oracle.addTradingPair("LINK/USD");
    }

    function test_PriceFeedIntegration() public {
        // Test getting prices from feed
        string[] memory pairs = new string[](1);
        pairs[0] = "ETH/USD";

        uint256[] memory thresholds = new uint256[](1);
        thresholds[0] = 100; // 1% threshold

        DynamicPriceOracle.PriceUpdateParams memory params = DynamicPriceOracle
            .PriceUpdateParams({
                tradingPairs: pairs,
                thresholds: thresholds,
                confirmations: 1,
                maxAge: 3600
            });

        skip(300);
        // First update should work and use initial price
        oracle.updatePrices(params);
        (uint256 price, , , ) = oracle.priceData("ETH/USD");
        console.log("before update to 21", price);

        // Update price in feed
        uint256 newEthPrice = 2100e18; // 5% increase
        priceFeed.setPrice("ETH/USD", newEthPrice);
        console.log("price in feed", priceFeed.getPrice("ETH/USD"));

        // Warp time forward
        vm.warp(block.timestamp + 300);

        // Update should work with new price
        oracle.updatePrices(params);

        // Get the stored price data
        (price, , , ) = oracle.priceData("ETH/USD");
        assertEq(price, newEthPrice, "Price should be updated to new value");
    }

    function test_SetPriceFeed() public {
        MockPriceFeed newPriceFeed = new MockPriceFeed();
        oracle.setPriceFeed(address(newPriceFeed));
        assertEq(address(oracle.priceFeed()), address(newPriceFeed));
    }

    function test_RevertWhen_SetInvalidPriceFeed() public {
        vm.expectRevert("Invalid price feed address");
        oracle.setPriceFeed(address(0));
    }

    function test_AddTradingPair() public {
        oracle.addTradingPair("AAVE/USD");
        assertTrue(oracle.isPairSupported("AAVE/USD"));
    }

    function test_RemoveTradingPair() public {
        oracle.removeTradingPair("ETH/USD");
        assertFalse(oracle.isPairSupported("ETH/USD"));
    }

    function test_PrepareUpdateParams() public {
        DynamicPriceOracle.PriceUpdateParams memory params = oracle
            .prepareUpdateParams();
        assertEq(params.tradingPairs.length, 3);
        assertEq(params.thresholds.length, 3);
        assertGt(params.confirmations, 0);

        vm.warp(block.timestamp + 300);

        // Update should work with new price
        oracle.updatePrices(params);
    }

    function test_UpdatePrices() public {
        string[] memory pairs = new string[](1);
        pairs[0] = "ETH/USD";

        uint256[] memory thresholds = new uint256[](1);
        thresholds[0] = 100; // 1% threshold

        DynamicPriceOracle.PriceUpdateParams memory params = DynamicPriceOracle
            .PriceUpdateParams({
                tradingPairs: pairs,
                thresholds: thresholds,
                confirmations: 1,
                maxAge: 3600
            });

        skip(300);
        // First update should work
        oracle.updatePrices(params);

        // Try to update again immediately - should fail
        vm.expectRevert("Too early to update");
        oracle.updatePrices(params);

        params = oracle.prepareUpdateParams();
        console.log("after update", params.thresholds[0]);

        skip(300);
        // this time price will be updated for oher pairs
        oracle.updatePrices(params);

        // ==== this time we will add new pair and check that price will update or not====
        uint256 AAVE_PRICE = 16e18;
        oracle.addTradingPair("AAVE/USD");

        priceFeed.setPrice("AAVE/USD", AAVE_PRICE);

        params = oracle.prepareUpdateParams();
        console.log("after update", params.thresholds[0]);

        skip(300);

        oracle.updatePrices(params);

        (uint256 price, , , ) = oracle.priceData("AAVE/USD");
        assertEq(price, AAVE_PRICE, "Price should be updated to new value");
    }

    // Fixed the revert test naming convention
    function test_RevertWhen_UpdatePricesWithInvalidPair() public {
        string[] memory pairs = new string[](1);
        pairs[0] = "INVALID/PAIR";

        uint256[] memory thresholds = new uint256[](1);
        thresholds[0] = 100;

        DynamicPriceOracle.PriceUpdateParams memory params = DynamicPriceOracle
            .PriceUpdateParams({
                tradingPairs: pairs,
                thresholds: thresholds,
                confirmations: 1,
                maxAge: 3600
            });

        skip(300);

        vm.expectRevert("Unsupported pair");
        oracle.updatePrices(params);
    }
}
