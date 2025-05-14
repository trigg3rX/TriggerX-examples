// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TriggerXTemplateFactory {
    // Mapping from user address to implementation address to proxy contract address
    mapping(address => mapping(address => address)) public userProxies;
    
    // Array of all implementation contracts
    address[] public implementations;
    // Mapping to check if an implementation is already registered
    mapping(address => bool) public isImplementationRegistered;

    event ProxyDeployed(address indexed owner, address indexed implementation, address indexed proxy);

    // Deploy a minimal proxy (EIP-1167) and initialize it with the owner
    function createProxy(address implementation) external payable returns (address proxy) {
        require(implementation != address(0), "Invalid implementation address");
        
        // If implementation is not registered, register it
        if (!isImplementationRegistered[implementation]) {
            implementations.push(implementation);
            isImplementationRegistered[implementation] = true;
        }
        
        // EIP-1167 minimal proxy bytecode
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            implementation,
            hex"5af43d82803e903d91602b57fd5bf3"
        );

        // Deploy the proxy
        assembly {
            proxy := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        require(proxy != address(0), "Proxy deployment failed");

        // Initialize the proxy by calling the initialize function
        (bool success, ) = proxy.call{value: msg.value}(
            abi.encodeWithSignature("initialize(address)", msg.sender)
        );
        require(success, "Initialization failed");

        // Store the proxy address in the nested mapping
        userProxies[msg.sender][implementation] = proxy;

        emit ProxyDeployed(msg.sender, implementation, proxy);
        return proxy;
    }

    // Get proxy address for a specific user and implementation
    function getProxyAddress(address user, address implementation) external view returns (address) {
        return userProxies[user][implementation];
    }

    // Get all registered implementations
    function getAllImplementations() external view returns (address[] memory) {
        return implementations;
    }   

    // Get the number of registered implementations
    function getImplementationCount() external view returns (uint256) {
        return implementations.length;
    }
}