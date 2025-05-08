// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimplePriceOracle {
    uint256 public latestPrice;
    uint256 public lastUpdateTimestamp;
    address public owner;
    
    event PriceUpdated(uint256 price, uint256 timestamp);
    
    // Initializer function (replaces constructor for proxy pattern)
    function initialize(address _owner) external payable {
        require(owner == address(0), "Already initialized");
        owner = _owner;
    }
    
    // Modifier to restrict access to owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
    
    // Function to update price
    function updatePrice(uint256 _newPrice) external onlyOwner {
        latestPrice = _newPrice;
        lastUpdateTimestamp = block.timestamp;
        emit PriceUpdated(_newPrice, block.timestamp);
    }
    
    // View functions
    function getLatestPrice() external view returns (uint256, uint256) {
        return (latestPrice, lastUpdateTimestamp);
    }
    
    // Function to transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }
}