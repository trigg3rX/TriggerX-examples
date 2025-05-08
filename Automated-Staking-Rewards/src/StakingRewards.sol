// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./RewardNFT.sol";

contract StakingRewards {
    IERC20 public stakingToken;
    RewardNFT public rewardNFT;

    // Staking state
    mapping(address => uint256) public stakedAmount;
    address[] public stakers;
    uint256 public totalStaked;
    uint256 public lastRewardDistribution;
    uint256 public thresholdMilestone;
    uint256 public staking_threshold; 
    
    // NFT reward settings
    string public nftBaseURI;
    string public nftRewardURI;
    
    uint256 public constant REWARD_INTERVAL = 1 days;
    
    address public owner;
    bool private initialized;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event NFTRewarded(address indexed user, uint256 tokenId);
    event ThresholdReached(uint256 totalStaked, uint256 threshold);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    modifier initializer() {
        require(!initialized, "Contract already initialized");
        initialized = true;
        _;
    }

    // Make initialize() payable to accept factory's msg.value
    function initialize(address _owner) external payable initializer {
        owner = _owner;
        lastRewardDistribution = block.timestamp;
    }
    
    // Function to set tokens and threshold after initialization
    function setTokensAndThreshold(
        address _stakingToken,
        uint256 _staking_threshold,
        string memory _nftBaseURI,
        string memory _nftRewardURI
    ) external onlyOwner {
        require(_stakingToken != address(0), "Invalid staking token");
        require(_staking_threshold > 0, "Threshold must be greater than 0");
        
        stakingToken = IERC20(_stakingToken);
        staking_threshold = _staking_threshold;
        nftBaseURI = _nftBaseURI;
        nftRewardURI = _nftRewardURI;
        
        // Deploy the NFT contract
        rewardNFT = new RewardNFT(
            "Staking Reward NFT",
            "SRNFT",
            _nftBaseURI
        );
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
        uint256 currentMilestone = totalStaked / staking_threshold;
        if (currentMilestone > thresholdMilestone) {
            thresholdMilestone = currentMilestone;
            emit ThresholdReached(totalStaked, staking_threshold);
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
    function distributeNFTRewards() external {
        require(totalStaked > 0, "No stakers to distribute rewards to");
        require(address(rewardNFT) != address(0), "NFT contract not set up");

        // Distribute one NFT to each staker who hasn't received one yet
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            
            // Check if the staker has already received an NFT
            if (!rewardNFT.hasReceived(staker)) {
                // Mint a new NFT for this staker
                uint256 tokenId = rewardNFT.safeMint(staker, nftRewardURI);
                emit NFTRewarded(staker, tokenId);
            }
        }

        lastRewardDistribution = block.timestamp;
    }

    function getStakedAmount(address user) external view returns (uint256) {
        return stakedAmount[user];
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    function getStakerCount() external view returns (uint256) {
        return stakers.length;
    }

    function getStaker(uint256 index) external view returns (address) {
        require(index < stakers.length, "Index out of bounds");
        return stakers[index];
    }
    
    function hasReceivedNFT(address user) external view returns (bool) {
        if (address(rewardNFT) == address(0)) return false;
        return rewardNFT.hasReceived(user);
    }
    function transferNFTContractOwnership(address newOwner) external onlyOwner {
        require(address(rewardNFT) != address(0), "NFT contract not set up");
        rewardNFT.transferOwnership(newOwner);
    }
}