// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingRewards {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    // Staking state
    mapping(address => uint256) public stakedAmount;
    address[] public stakers;
    uint256 public totalStaked;
    uint256 public lastRewardDistribution;
    uint256 public thresholdMilestone; // New milestone system

    uint256 public constant REWARD_INTERVAL = 1 days;
    uint256 public constant STAKING_THRESHOLD = 1000 ether; // 1000 staking tokens

    // Events
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 totalRewards, uint256 timestamp);
    event ThresholdReached(uint256 totalStaked, uint256 threshold);

    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        lastRewardDistribution = block.timestamp;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        stakingToken.transferFrom(msg.sender, address(this), amount);

        if (stakedAmount[msg.sender] == 0) {
            stakers.push(msg.sender);
        }
        stakedAmount[msg.sender] += amount;
        totalStaked += amount;

        emit Staked(msg.sender, amount);

        // Check if we've crossed the next threshold milestone
        uint256 currentMilestone = totalStaked / STAKING_THRESHOLD;
        if (currentMilestone > thresholdMilestone) {
            thresholdMilestone = currentMilestone;
            emit ThresholdReached(totalStaked, STAKING_THRESHOLD);
        }
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(
            stakedAmount[msg.sender] >= amount,
            "Insufficient staked amount"
        );

        // Update staking state
        stakedAmount[msg.sender] -= amount;
        totalStaked -= amount;

        // Remove from stakers array if fully unstaked
        if (stakedAmount[msg.sender] == 0) {
            // Find and remove the staker from the array
            for (uint256 i = 0; i < stakers.length; i++) {
                if (stakers[i] == msg.sender) {
                    stakers[i] = stakers[stakers.length - 1];
                    stakers.pop();
                    break;
                }
            }
        }

        // Transfer tokens back to user
        stakingToken.transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    // This function will be called by TriggerX when ThresholdReached event is emitted
    function distributeRewards() external {
        require(totalStaked > 0, "No stakers to distribute rewards to");

        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        require(rewardBalance > 0, "No rewards to distribute");

        // Distribute rewards proportionally to all stakers
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 stakerReward = (rewardBalance * stakedAmount[staker]) /
                totalStaked;
            if (stakerReward > 0) {
                rewardToken.transfer(staker, stakerReward);
            }
        }

        lastRewardDistribution = block.timestamp;
        emit RewardsDistributed(rewardBalance, block.timestamp);
    }

    function getStakedAmount(address user) external view returns (uint256) {
        return stakedAmount[user];
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    function getRewardBalance() external view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function getStakerCount() external view returns (uint256) {
        return stakers.length;
    }

    function getStaker(uint256 index) external view returns (address) {
        require(index < stakers.length, "Index out of bounds");
        return stakers[index];
    }
}
