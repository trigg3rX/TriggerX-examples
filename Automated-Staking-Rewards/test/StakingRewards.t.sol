// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {StakingRewards} from "../src/StakingRewards.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract StakingRewardsTest is Test {
    StakingRewards public staking;
    MockERC20 public stakingToken;
    MockERC20 public rewardToken;
    
    address public alice = address(1);
    address public bob = address(2);
    address public charlie = address(3);
    
    uint256 public constant INITIAL_BALANCE = 1000 ether;
    uint256 public constant REWARD_AMOUNT = 500 ether;
    
    function setUp() public {
        // Deploy tokens
        stakingToken = new MockERC20("Staking Token", "STK", 18);
        rewardToken = new MockERC20("Reward Token", "RWD", 18);
        
        // Deploy staking contract
        staking = new StakingRewards(address(stakingToken), address(rewardToken));
        
        // Mint tokens to users
        stakingToken.mint(alice, INITIAL_BALANCE);
        stakingToken.mint(bob, INITIAL_BALANCE);
        stakingToken.mint(charlie, INITIAL_BALANCE);
        
        // Mint reward tokens to staking contract
        rewardToken.mint(address(staking), REWARD_AMOUNT);
        
        // Approve staking contract to spend tokens
        vm.startPrank(alice);
        stakingToken.approve(address(staking), INITIAL_BALANCE);
        vm.stopPrank();
        
        vm.startPrank(bob);
        stakingToken.approve(address(staking), INITIAL_BALANCE);
        vm.stopPrank();
        
        vm.startPrank(charlie);
        stakingToken.approve(address(staking), INITIAL_BALANCE);
        vm.stopPrank();
    }
    
    function test_StakeAndReachThreshold() public {
        // Alice stakes 500 tokens
        vm.startPrank(alice);
        staking.stake(500 ether);
        vm.stopPrank();
        
        // Bob stakes 500 tokens (reaches threshold)
        vm.startPrank(bob);
        staking.stake(500 ether);
        vm.stopPrank();
        
        // Verify total staked
        assertEq(staking.totalStaked(), 1000 ether);
        assertEq(staking.getStakedAmount(alice), 500 ether);
        assertEq(staking.getStakedAmount(bob), 500 ether);
    }
    
    function test_DistributeRewards() public {
        // First stake to reach threshold
        vm.startPrank(alice);
        staking.stake(500 ether);
        vm.stopPrank();
        
        vm.startPrank(bob);
        staking.stake(500 ether);
        vm.stopPrank();
        
        // Fast forward time to pass reward interval
        vm.warp(block.timestamp + 1 days);
        
        // Distribute rewards
        staking.distributeRewards();
        
        // Verify rewards distributed proportionally
        assertEq(rewardToken.balanceOf(alice), 250 ether); // 50% of rewards
        assertEq(rewardToken.balanceOf(bob), 250 ether);   // 50% of rewards
    }
    
    function test_MultipleStakersRewardDistribution() public {
        // Alice stakes 400 tokens
        vm.startPrank(alice);
        staking.stake(400 ether);
        vm.stopPrank();
        
        // Bob stakes 400 tokens
        vm.startPrank(bob);
        staking.stake(400 ether);
        vm.stopPrank();
        
        // Charlie stakes 200 tokens (reaches threshold)
        vm.startPrank(charlie);
        staking.stake(200 ether);
        vm.stopPrank();
        
        // Fast forward time
        vm.warp(block.timestamp + 1 days);
        
        // Distribute rewards
        staking.distributeRewards();
        
        // Verify rewards distributed proportionally
        assertEq(rewardToken.balanceOf(alice), 200 ether);   // 40% of rewards
        assertEq(rewardToken.balanceOf(bob), 200 ether);     // 40% of rewards
        assertEq(rewardToken.balanceOf(charlie), 100 ether); // 20% of rewards
    }
    
    function test_UnstakeAndStakeAgain() public {
        // Initial stake
        vm.startPrank(alice);
        staking.stake(500 ether);
        vm.stopPrank();
        
        vm.startPrank(bob);
        staking.stake(500 ether);
        vm.stopPrank();
        
        // Alice unstakes
        vm.startPrank(alice);
        staking.unstake(500 ether);
        vm.stopPrank();
        
        // Verify unstake
        assertEq(staking.totalStaked(), 500 ether);
        assertEq(staking.getStakedAmount(alice), 0);
        
        // Alice stakes again
        vm.startPrank(alice);
        staking.stake(300 ether);
        vm.stopPrank();
        
        // Verify new stake
        assertEq(staking.totalStaked(), 800 ether);
        assertEq(staking.getStakedAmount(alice), 300 ether);
    }
    
    function test_RewardDistributionAfterUnstake() public {
        // Initial stake
        vm.startPrank(alice);
        staking.stake(500 ether);
        vm.stopPrank();
        
        vm.startPrank(bob);
        staking.stake(500 ether);
        vm.stopPrank();
        
        // Alice unstakes
        vm.startPrank(alice);
        staking.unstake(500 ether);
        vm.stopPrank();
        
        // Fast forward time
        vm.warp(block.timestamp + 1 days);
        
        // Distribute rewards
        staking.distributeRewards();
        
        // Verify rewards (only bob should get rewards now)
        assertEq(rewardToken.balanceOf(alice), 0);
        assertEq(rewardToken.balanceOf(bob), 500 ether);
    }
}
