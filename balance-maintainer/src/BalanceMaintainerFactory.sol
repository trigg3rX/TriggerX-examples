// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BalanceMaintainer.sol";

contract BalanceMaintainerFactory {
    // Mapping from user address to their deployed BalanceMaintainer contracts
    mapping(address => address[]) public userContracts;
    
    event BalanceMaintainerDeployed(address indexed owner, address indexed balanceMaintainer);
    
    function createBalanceMaintainer() external payable returns (address) {
        BalanceMaintainer newBalanceMaintainer = new BalanceMaintainer{value: msg.value}(msg.sender);
        
        // Store the new contract address in the user's array of contracts
        userContracts[msg.sender].push(address(newBalanceMaintainer));
        
        emit BalanceMaintainerDeployed(msg.sender, address(newBalanceMaintainer));
        return address(newBalanceMaintainer);
    }
    
    // Get all contracts deployed by a specific user
    function getUserContracts(address user) external view returns (address[] memory) {
        return userContracts[user];
    }
    
    // Get the count of contracts deployed by a specific user
    function getUserContractCount(address user) external view returns (uint256) {
        return userContracts[user].length;
    }
} 