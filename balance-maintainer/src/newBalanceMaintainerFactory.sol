// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BalanceMaintainerFactory {
    // Address of the verified BalanceMaintainer implementation contract
    address public immutable implementation;

    // Mapping from user address to their latest BalanceMaintainer proxy contract
    mapping(address => address) public userContracts;

    event BalanceMaintainerDeployed(address indexed owner, address indexed balanceMaintainer);

    constructor(address _implementation) {
        require(_implementation != address(0), "Invalid implementation address");
        implementation = _implementation;
    }

    // Deploy a minimal proxy (EIP-1167) and initialize it with the owner
    function createBalanceMaintainer() external payable returns (address proxy) {
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

        // Initialize the proxy by calling the constructor (set owner)
        (bool success, ) = proxy.call{value: msg.value}(
            abi.encodeWithSignature("constructor(address)", msg.sender)
        );
        require(success, "Initialization failed");

        // Update the mapping with the latest proxy address
        userContracts[msg.sender] = proxy;

        emit BalanceMaintainerDeployed(msg.sender, proxy);
        return proxy;
    }

    // Get the latest BalanceMaintainer proxy contract for a user
    function getUserContract(address user) external view returns (address) {
        return userContracts[user];
    }
}