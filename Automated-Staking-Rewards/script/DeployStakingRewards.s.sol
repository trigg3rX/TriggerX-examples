// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {StakingRewards} from "../src/StakingRewards.sol";

contract DeployStakingRewards is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        
        StakingRewards stakingRewards = new StakingRewards();
        stakingRewards.initialize(deployer);

        vm.stopBroadcast();

        console2.log("StakingRewards deployed at:", address(stakingRewards));
    }
}