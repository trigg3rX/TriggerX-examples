// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockPriceFeed {
    mapping(string => uint256) public prices;
    
    function setPrice(string calldata pair, uint256 price) external {
        prices[pair] = price;
    }
    
    function getPrice(string calldata pair) external view returns (uint256) {
        return prices[pair];
    }
}