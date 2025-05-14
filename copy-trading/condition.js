const { ethers } = require('ethers');

// Constants
const WHALE_ADDRESS = '0x9717387C43bee3635aD28d69702835DAC1356CC1';
const WHALE_TOKEN = '0x383D4a61D0B069D02cA2Db5A82003b9561d56e19';
const K_RATIO = 0.01; // 1%
const MIN_DIFFERENCE_THRESHOLD = 0.5; // Only trade if difference is at least 0.5 tokens (to avoid dust trades)

// ABI for ERC20 token - we only need balanceOf function
const ERC20_ABI = [
    'function balanceOf(address account) view returns (uint256)'
];

async function checkCondition(provider, copyTraderAddress) {
    try {
        // Initialize contracts
        const tokenContract = new ethers.Contract(WHALE_TOKEN, ERC20_ABI, provider);

        // Fetch balances
        const whaleBalance = await tokenContract.balanceOf(WHALE_ADDRESS);
        const contractBalance = await tokenContract.balanceOf(copyTraderAddress);
        const contractEthBalance = await provider.getBalance(copyTraderAddress);

        // Calculate target balance (1% of whale balance)
        const targetBalance = (whaleBalance * BigInt(Math.floor(K_RATIO * 1e18))) / BigInt(1e18);
        
        // Calculate difference
        const difference = targetBalance - contractBalance;
        
        console.log('\nDebug Info:');
        console.log('Target Balance:', ethers.formatEther(targetBalance));
        console.log('Current Balance:', ethers.formatEther(contractBalance));
        console.log('Difference:', ethers.formatEther(difference));

        // Minimum difference to trigger a trade (to avoid dust transactions)
        const minDifference = ethers.parseEther(MIN_DIFFERENCE_THRESHOLD.toString());
        
        // If we need to buy and have ETH
        if (difference > minDifference && contractEthBalance > 0n) {
            // Buy the difference to reach exactly the 0.01 ratio
            return {
                shouldExecute: true,
                params: {
                    isBuy: true,
                    amount: difference
                },
                whaleBalance: whaleBalance,
                contractBalance: contractBalance,
                targetBalance: targetBalance,
                ethBalance: contractEthBalance
            };
        }
        
        // For selling, check if we're above target
        if (difference < -minDifference) {
            // Sell the excess to reach exactly the 0.01 ratio
            return {
                shouldExecute: true,
                params: {
                    isBuy: false,
                    amount: -difference
                },
                whaleBalance: whaleBalance,
                contractBalance: contractBalance,
                targetBalance: targetBalance,
                ethBalance: contractEthBalance
            };
        }

        return {
            shouldExecute: false,
            whaleBalance: whaleBalance,
            contractBalance: contractBalance,
            targetBalance: targetBalance,
            ethBalance: contractEthBalance
        };

    } catch (error) {
        console.error('Error in checkCondition:', error);
        return {
            shouldExecute: false,
            error: error.message
        };
    }
}

module.exports = {
    checkCondition
}; 