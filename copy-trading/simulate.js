const { ethers } = require('ethers');
const { checkCondition } = require('./condition');

// Constants
const MOCK_DEX = '0xE291a14749d10Cc12fB55B075B6275522C4eeA96';
const COPY_TRADER_ADDRESS = '0x34cC81d59A9BA8fCDC6a6FEFFE6CE96cC65B8671'; // Deployed CopyTrader address
const RPC_URL = 'https://sepolia.optimism.io'; // OP Sepolia RPC

// ABI for CopyTrader contract
const COPY_TRADER_ABI = [
    'function execute(bool isBuy, uint256 amount) external',
    'function whaleToken() view returns (address)',
    'function whaleWallet() view returns (address)',
    'function dex() view returns (address)'
];

async function simulate() {
    try {
        // Initialize provider
        const provider = new ethers.JsonRpcProvider(RPC_URL);
        
        // Initialize contract
        const copyTrader = new ethers.Contract(COPY_TRADER_ADDRESS, COPY_TRADER_ABI, provider);

        // Verify contract addresses
        const whaleToken = await copyTrader.whaleToken();
        const whaleWallet = await copyTrader.whaleWallet();
        const dex = await copyTrader.dex();

        console.log('Contract Verification:');
        console.log('Whale Token:', whaleToken);
        console.log('Whale Wallet:', whaleWallet);
        console.log('DEX:', dex);
        console.log('-------------------');

        // Function to simulate one check
        async function simulateCheck() {
            const timestamp = new Date().toISOString();
            console.log(`\n[${timestamp}] Checking conditions...`);
            
            const result = await checkCondition(provider, COPY_TRADER_ADDRESS);
            
            console.log('\nCurrent State:');
            console.log('Whale Balance:', ethers.formatEther(result.whaleBalance), 'tokens');
            console.log('Contract Balance:', ethers.formatEther(result.contractBalance), 'tokens');
            console.log('Target Balance:', ethers.formatEther(result.targetBalance), 'tokens');
            console.log('ETH Balance:', ethers.formatEther(result.ethBalance), 'ETH');

            if (result.shouldExecute) {
                console.log('\nSimulating Trade:');
                console.log('Action:', result.params.isBuy ? 'BUY' : 'SELL');
                console.log('Amount:', ethers.formatEther(result.params.amount), 'tokens');
                
                try {
                    // Simulate the transaction
                    const tx = await copyTrader.execute.populateTransaction(
                        result.params.isBuy,
                        result.params.amount
                    );
                    
                    console.log('\nSimulated Transaction Details:');
                    console.log('To:', tx.to);
                    console.log('Data:', tx.data);
                    console.log('Value:', ethers.formatEther(tx.value || '0'), 'ETH');
                    
                    // Calculate new balances after simulation
                    const newContractBalance = result.params.isBuy 
                        ? result.contractBalance + result.params.amount
                        : result.contractBalance - result.params.amount;
                    
                    console.log('\nProjected State After Trade:');
                    console.log('New Contract Balance:', ethers.formatEther(newContractBalance), 'tokens');
                    console.log('New ETH Balance:', ethers.formatEther(
                        result.params.isBuy 
                            ? result.ethBalance - (tx.value || 0n)
                            : result.ethBalance + (tx.value || 0n)
                    ), 'ETH');
                } catch (error) {
                    console.error('Simulation failed:', error.message);
                }
            } else {
                console.log('\nNo action needed');
                if (result.error) {
                    console.log('Error:', result.error);
                }
            }
            console.log('\n----------------------------------------');
        }

        // Run initial check
        await simulateCheck();

        // Set up interval for subsequent checks
        setInterval(simulateCheck, 10000); // 30 seconds

    } catch (error) {
        console.error('Simulation error:', error);
    }
}

// Run simulation
simulate().catch(console.error); 