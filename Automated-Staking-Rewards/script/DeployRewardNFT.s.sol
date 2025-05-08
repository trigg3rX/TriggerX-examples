// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {RewardNFT} from "../src/RewardNFT.sol";

contract DeployRewardNFT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        
        RewardNFT rewardNFT = new RewardNFT(
            "Staking Reward NFT",
            "SRNFT",
            "https://teal-random-koala-993.mypinata.cloud/ipfs/bafkreibfoqq6c222t55mwa334p6kqifjydei6pi7urbrwi5vhgbevixvga" // Base URI
        );

        vm.stopBroadcast();

        console2.log("RewardNFT deployed at:", address(rewardNFT));
    }
}