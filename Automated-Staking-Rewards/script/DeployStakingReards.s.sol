// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StakingRewards} from "../src/StakingRewards.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract DeployStakingReards is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock tokens
        MockERC20 stakingToken = new MockERC20("Staking Token", "STK", 18);
        MockERC20 rewardToken = new MockERC20("Reward Token", "RWD", 18);
        
        // Deploy staking contract
        StakingRewards staking = new StakingRewards(
            address(stakingToken),
            address(rewardToken),
            10 ether // Set a threshold for staking
        );
        
        // Mint some tokens to the deployer for testing
        stakingToken.mint(vm.addr(deployerPrivateKey), 1000 ether);
        rewardToken.mint(vm.addr(deployerPrivateKey), 1000 ether);
        
        vm.stopBroadcast();

        // Log the deployed addresses
        console.log("Staking Token deployed at:", address(stakingToken));
        console.log("Reward Token deployed at:", address(rewardToken));
        console.log("StakingRewards deployed at:", address(staking));
    }
} 
