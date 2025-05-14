const { ethers } = require('ethers');
const { checkArbitrageOpportunity } = require('./conditionScript');

// Constants
const ARBITRAGE_ADDRESS = '0x6Da3bb91635Dc57D53fe3C2dDF3cca143faD2e54';
const RPC_URL = 'https://sepolia.base.org';

// ABI for Arbitrage contract
const ARBITRAGE_ABI = [
    'function executeArbitrage(uint256 amount, bool buyFromDex1) external',
    'function dex1() view returns (address)',
    'function dex2() view returns (address)',
    'function token1() view returns (address)',
    'function token2() view returns (address)'
];

async function simulate() {
    try {
        // Initialize provider
        const provider = new ethers.JsonRpcProvider(RPC_URL);

        // Initialize contract
        const arbitrageContract = new ethers.Contract(ARBITRAGE_ADDRESS, ARBITRAGE_ABI, provider);

        // Verify contract addresses
        const dex1 = await arbitrageContract.dex1();
        const dex2 = await arbitrageContract.dex2();
        const token1 = await arbitrageContract.token1();
        const token2 = await arbitrageContract.token2();

        console.log('Contract Verification:');
        console.log('DEX1:', dex1);
        console.log('DEX2:', dex2);
        console.log('Token1:', token1);
        console.log('Token2:', token2);
        console.log('-------------------');

        // Function to simulate one check
        async function simulateCheck() {
            const timestamp = new Date().toISOString();
            console.log(`\n[${timestamp}] Checking arbitrage opportunities...`);

            const result = await checkArbitrageOpportunity(provider, ARBITRAGE_ADDRESS);

            if (result.shouldExecute) {
                console.log('\nArbitrage Opportunity Found:');
                console.log('Strategy:', result.params.buyFromDex1 ? 'Buy from DEX1, sell on DEX2' : 'Buy from DEX2, sell on DEX1');
                console.log('Amount:', ethers.formatUnits(result.params.amount, 18), 'tokens');
                console.log('DEX1 Output:', ethers.formatUnits(result.dex1Output, 18), 'tokens');
                console.log('DEX2 Output:', ethers.formatUnits(result.dex2Output, 18), 'tokens');
                console.log('Profit Amount:', ethers.formatUnits(result.profitAmount, 18), 'tokens');
                console.log('Profit in basis points:', result.profitBps.toString());

                try {
                    // Simulate the transaction
                    const tx = await arbitrageContract.executeArbitrage.populateTransaction(
                        result.params.amount,
                        result.params.buyFromDex1
                    );

                    console.log('\nSimulated Transaction Details:');
                    console.log('To:', tx.to);
                    console.log('Data:', tx.data);

                    // Calculate expected final state
                    const expectedProfit = result.profitAmount;
                    console.log('\nProjected State After Trade:');
                    console.log('Expected Profit:', ethers.formatUnits(expectedProfit, 18), 'tokens');
                } catch (error) {
                    console.error('Simulation failed:', error.message);
                }
            } else {
                console.log('\nNo arbitrage opportunity found');
                if (result.error) {
                    console.log('Error:', result.error);
                } else {
                    console.log('DEX1 Output:', ethers.formatUnits(result.dex1Output, 18), 'tokens');
                    console.log('DEX2 Output:', ethers.formatUnits(result.dex2Output, 18), 'tokens');
                }
            }
            console.log('\n----------------------------------------');
        }

        // Run initial check
        await simulateCheck();

        // Set up interval for subsequent checks
        setInterval(simulateCheck, 600000); // Check every 10 minutes

    } catch (error) {
        console.error('Simulation error:', error);
    }
}

// Run simulation
simulate().catch(console.error); 