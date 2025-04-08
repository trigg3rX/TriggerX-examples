// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";
import "./MockPriceFeed.sol";

contract DynamicPriceOracle is Ownable {
    struct PriceUpdateParams {
        string[] tradingPairs; // Which pairs to update
        uint256[] thresholds; // Minimum price change needed for update
        uint256 confirmations; // Required confirmations for this update
        uint256 maxAge; // Maximum age of price data allowed
    }

    struct PriceData {
        uint256 price;
        uint256 lastUpdateTime;
        uint256 volatility; // Rolling 24h volatility * 100 (for precision)
        uint256 tradingVolume; // 24h trading volume
    }

    // Storage
    MockPriceFeed public priceFeed;
    mapping(string => PriceData) public priceData;
    string[] public supportedPairs;
    uint256 public minUpdateInterval;
    uint256 public volatilityThreshold; // Base threshold multiplier

    // Events
    event PriceUpdated(string pair, uint256 price, uint256 threshold);
    event PairAdded(string pair);
    event PairRemoved(string pair);
    event PriceFeedUpdated(address newPriceFeed);

    constructor(
        uint256 _minUpdateInterval,
        uint256 _volatilityThreshold,
        address _priceFeed
    ) Ownable(msg.sender) {
        minUpdateInterval = _minUpdateInterval;
        volatilityThreshold = _volatilityThreshold;
        priceFeed = MockPriceFeed(_priceFeed);
    }

    function setPriceFeed(address _newPriceFeed) external onlyOwner {
        require(_newPriceFeed != address(0), "Invalid price feed address");
        priceFeed = MockPriceFeed(_newPriceFeed);
        emit PriceFeedUpdated(_newPriceFeed);
    }

    function updatePrices(PriceUpdateParams calldata params) external {
        require(
            params.tradingPairs.length == params.thresholds.length,
            "Length mismatch"
        );
        require(params.tradingPairs.length > 0, "Empty pairs array");

        for (uint i = 0; i < params.tradingPairs.length; i++) {
            string memory pair = params.tradingPairs[i];
            require(isPairSupported(pair), "Unsupported pair");

            require(
                block.timestamp >=
                    priceData[pair].lastUpdateTime + minUpdateInterval,
                "Too early to update"
            );

            // Use price feed to get latest price
            uint256 newPrice = getLatestPrice(pair);
            uint256 oldPrice = priceData[pair].price;
            uint256 deviation = calculateDeviation(oldPrice, newPrice);
            console.log(
                "Price threshold and deviation ",
                params.thresholds[i],
                deviation
            );
            if (deviation >= params.thresholds[i]) {
                console.log("yes this time");
                priceData[pair].price = newPrice;
                priceData[pair].lastUpdateTime = block.timestamp;
                console.log("before update volatility", priceData[pair].volatility);
                priceData[pair].volatility =
                    (priceData[pair].volatility * 90 + deviation * 10) /
                    100;
                console.log(
                    "after update volatility",
                    priceData[pair].volatility
                );
                emit PriceUpdated(pair, newPrice, params.thresholds[i]);
            }
        }
    }

    function addTradingPair(string calldata pair) external onlyOwner {
        require(!isPairSupported(pair), "Pair already supported");
        supportedPairs.push(pair);
        emit PairAdded(pair);
    }

    function removeTradingPair(string calldata pair) external onlyOwner {
        require(isPairSupported(pair), "Pair not supported");

        // Find and remove the pair
        for (uint i = 0; i < supportedPairs.length; i++) {
            if (keccak256(bytes(supportedPairs[i])) == keccak256(bytes(pair))) {
                supportedPairs[i] = supportedPairs[supportedPairs.length - 1];
                supportedPairs.pop();
                emit PairRemoved(pair);
                break;
            }
        }
    }

    function prepareUpdateParams()
        public
        view
        returns (PriceUpdateParams memory)
    {
        string[] memory activePairs = getActiveTraidingPairs();
        uint256[] memory thresholds = calculateUpdateThresholds(activePairs);
        uint256 confirmations = calculateRequiredConfirmations();

        return
            PriceUpdateParams({
                tradingPairs: activePairs,
                thresholds: thresholds,
                confirmations: confirmations,
                maxAge: 3600 // 1 hour
            });
    }

    function getActiveTraidingPairs() public view returns (string[] memory) {
        // For simplicity, return all supported pairs
        // In production, you might filter based on volume/activity
        return supportedPairs;
    }

    function calculateUpdateThresholds(
        string[] memory pairs
    ) public view returns (uint256[] memory) {
        uint256[] memory thresholds = new uint256[](pairs.length);

        for (uint i = 0; i < pairs.length; i++) {
            // Base threshold adjusted by pair's volatility
            thresholds[i] =
                (volatilityThreshold * priceData[pairs[i]].volatility) /
                100;
            if (thresholds[i] < 10) thresholds[i] = 10; // Minimum 0.1% threshold
        }

        return thresholds;
    }

    function calculateRequiredConfirmations() public view returns (uint256) {
        // Simple logic: more confirmations during high volatility
        uint256 maxVolatility = 0;
        for (uint i = 0; i < supportedPairs.length; i++) {
            if (priceData[supportedPairs[i]].volatility > maxVolatility) {
                maxVolatility = priceData[supportedPairs[i]].volatility;
            }
        }

        // 1-5 confirmations based on volatility
        return 1 + (maxVolatility * 4) / 10000;
    }

    function isPairSupported(string memory pair) public view returns (bool) {
        for (uint i = 0; i < supportedPairs.length; i++) {
            if (keccak256(bytes(supportedPairs[i])) == keccak256(bytes(pair))) {
                return true;
            }
        }
        return false;
    }

    function calculateDeviation(
        uint256 oldPrice,
        uint256 newPrice
    ) internal pure returns (uint256) {
        console.log("newPrice", newPrice, "oldPrice", oldPrice);
        if (oldPrice == 0) return 100;
        return
            ((newPrice > oldPrice ? newPrice - oldPrice : oldPrice - newPrice) *
                10000) / oldPrice;
    }

    function getLatestPrice(
        string memory pair
    ) internal view returns (uint256) {
        return priceFeed.getPrice(pair);
    }
}
