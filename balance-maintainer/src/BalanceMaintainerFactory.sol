// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BalanceMaintainer.sol";

contract BalanceMaintainerFactory {

    mapping(address => address) public userContract;
    
    event BalanceMaintainerDeployed(address indexed owner, address indexed balanceMaintainer);
    
    function createBalanceMaintainer() external payable returns (address) {
        BalanceMaintainer newBalanceMaintainer = new BalanceMaintainer{value: msg.value}(msg.sender);
        
        // Store the new contract address in the user's array of contracts
        userContract[msg.sender] = address(newBalanceMaintainer);
        
        emit BalanceMaintainerDeployed(msg.sender, address(newBalanceMaintainer));
        return address(newBalanceMaintainer);
    }
    
    // Get all contracts deployed by a specific user
    function getUserContracts(address user) external view returns (address) {
        return userContract[user];
    }

} 