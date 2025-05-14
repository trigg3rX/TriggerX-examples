const { ethers } = require('ethers');
const { checkCondition } = require('./condition');

// Mock provider and contract for testing
class MockProvider {
    constructor() {
        this.whaleBalance = ethers.parseEther('10000'); // 10,000 tokens
        this.contractBalance = ethers.parseEther('0');  // Start with 0
        this.contractEthBalance = ethers.parseEther('1'); // 1 ETH
    }

    async getBalance(address) {
        // Return the mock ETH balance for any address
        return this.contractEthBalance;
    }

    // Add support for contract calls
    async call(transaction) {
        // Create interface for ERC20
        const iface = new ethers.Interface([
            'function balanceOf(address account) view returns (uint256)'
        ]);
        
        // Decode the function call
        const decoded = iface.parseTransaction({ data: transaction.data });
        
        // Return the appropriate balance
        if (decoded.name === 'balanceOf') {
            const address = decoded.args[0];
            if (address === '0x9717387C43bee3635aD28d69702835DAC1356CC1') {
                return iface.encodeFunctionResult('balanceOf', [this.whaleBalance]);
            } else {
                return iface.encodeFunctionResult('balanceOf', [this.contractBalance]);
            }
        }
        
        return '0x';
    }
}

// ERC20 ABI for token contract
const ERC20_ABI = [
    'function balanceOf(address account) view returns (uint256)'
];

class MockContract {
    constructor(provider) {
        this.provider = provider;
    }

    async balanceOf(address) {
        if (address === '0x9717387C43bee3635aD28d69702835DAC1356CC1') {
            return this.provider.whaleBalance;
        }
        return this.provider.contractBalance;
    }

    // Add provider's getBalance method - required by condition.js
    async getBalance(address) {
        return this.provider.getBalance(address);
    }

    // Add contract interface methods
    interface = {
        balanceOf: {
            encode: (address) => {
                const iface = new ethers.Interface(ERC20_ABI);
                return iface.encodeFunctionData('balanceOf', [address]);
            }
        }
    };
}

// CopyTrader contract ABI - only the functions we need
const COPY_TRADER_ABI = [
    'function execute(bool isBuy, uint256 amount) external payable',
    'function getContractDetails() external view returns (address, address, address, address)'
];

async function simulateTransaction(provider, copyTraderAddress, isBuy, amount) {
    // Create a mock contract instance
    const contract = new ethers.Contract(copyTraderAddress, COPY_TRADER_ABI, provider);
    
    // Simulate the transaction
    const tx = await contract.execute.populateTransaction(isBuy, amount);
    
    // Calculate gas estimate (mock) - use BigInt for all calculations
    const gasEstimate = BigInt(200000); // Typical gas for this type of transaction
    
    // Calculate ETH value needed
    const ethValue = isBuy ? ethers.parseEther('0.1') : BigInt(0); // Mock ETH value for buy
    const gasPrice = ethers.parseUnits('1', 'gwei'); // Mock gas price
    
    // Calculate costs using BigInt
    const gasCost = gasEstimate * gasPrice;
    const totalCost = ethValue + gasCost;
    
    return {
        to: copyTraderAddress,
        data: tx.data,
        value: ethValue,
        gasLimit: gasEstimate,
        gasPrice: gasPrice,
        gasCost: gasCost,
        totalCost: totalCost,
        nonce: BigInt(0), // Mock nonce
        chainId: BigInt(11155420) // OP Sepolia
    };
}

async function runScenario(name, provider, expectedAction) {
    console.log(`\n=== Testing Scenario: ${name} ===`);
    console.log('----------------------------------------');
    
    const mockContract = new MockContract(provider);
    const result = await checkCondition(mockContract, '0x34cC81d59A9BA8fCDC6a6FEFFE6CE96cC65B8671');
    
    console.log('Current State:');
    console.log('Whale Balance:', ethers.formatEther(provider.whaleBalance), 'tokens');
    console.log('Contract Balance:', ethers.formatEther(provider.contractBalance), 'tokens');
    console.log('ETH Balance:', ethers.formatEther(provider.contractEthBalance), 'ETH');
    
    if (result.shouldExecute) {
        console.log('\nAction Required:', result.params.isBuy ? 'BUY' : 'SELL');
        console.log('Token Amount:', ethers.formatEther(result.params.amount), 'tokens');
        
        try {
            // Simulate the transaction
            const tx = await simulateTransaction(
                provider,
                '0x34cC81d59A9BA8fCDC6a6FEFFE6CE96cC65B8671',
                result.params.isBuy,
                result.params.amount
            );
            
            console.log('\nSimulated Transaction:');
            console.log('To:', tx.to);
            console.log('Value:', ethers.formatEther(tx.value), 'ETH');
            console.log('Gas Limit:', tx.gasLimit.toString());
            console.log('Gas Price:', ethers.formatUnits(tx.gasPrice, 'gwei'), 'gwei');
            console.log('Estimated Gas Cost:', ethers.formatEther(tx.gasCost), 'ETH');
            console.log('Total ETH Required:', ethers.formatEther(tx.totalCost), 'ETH');
            
            // Show the calldata in a readable format
            console.log('\nTransaction Calldata:');
            console.log(tx.data);
        } catch (error) {
            console.log('\nFailed to simulate transaction:', error.message);
        }
    } else {
        console.log('\nNo action needed');
    }
    
    console.log('\nTest Result:', result.shouldExecute === expectedAction.shouldExecute && 
        (!result.shouldExecute || result.params.isBuy === expectedAction.isBuy) ? 'PASS' : 'FAIL');
    console.log('----------------------------------------');
}

async function testAllScenarios() {
    // Scenario 1: Initial state - should buy
    const provider1 = new MockProvider();
    await runScenario('Initial State (Zero Balance)', provider1, { shouldExecute: true, isBuy: true });

    // Scenario 2: Below target but not zero - should NOT buy (with strict condition)
    const provider2 = new MockProvider();
    provider2.contractBalance = ethers.parseEther('50'); // 50 tokens (target is 100)
    await runScenario('Below Target', provider2, { shouldExecute: false });

    // Scenario 3: At target - should not trade
    const provider3 = new MockProvider();
    provider3.contractBalance = ethers.parseEther('100'); // 100 tokens (exactly at target)
    await runScenario('At Target', provider3, { shouldExecute: false });

    // Scenario 4: Slightly above target - should not trade
    const provider4 = new MockProvider();
    provider4.contractBalance = ethers.parseEther('102'); // 102 tokens (2% above target)
    await runScenario('Slightly Above Target', provider4, { shouldExecute: false });

    // Scenario 5: Significantly above target - should sell
    const provider5 = new MockProvider();
    provider5.contractBalance = ethers.parseEther('110'); // 110 tokens (10% above target)
    await runScenario('Significantly Above Target', provider5, { shouldExecute: true, isBuy: false });

    // Scenario 6: No ETH - should not buy even if below target
    const provider6 = new MockProvider();
    provider6.contractBalance = ethers.parseEther('50');
    provider6.contractEthBalance = ethers.parseEther('0');
    await runScenario('No ETH Available', provider6, { shouldExecute: false });

    // Scenario 7: Whale balance changes - should NOT buy (with strict condition)
    const provider7 = new MockProvider();
    provider7.whaleBalance = ethers.parseEther('20000'); // Whale doubles their position
    provider7.contractBalance = ethers.parseEther('100'); // We're at old target
    await runScenario('Whale Balance Increase', provider7, { shouldExecute: false });

    // Scenario 8: Whale balance decreases
    const provider8 = new MockProvider();
    provider8.whaleBalance = ethers.parseEther('5000'); // Whale halves their position
    provider8.contractBalance = ethers.parseEther('100'); // We're above new target
    await runScenario('Whale Balance Decrease', provider8, { shouldExecute: true, isBuy: false });

    // Scenario 9: Very low balance - should buy (meets strict condition)
    const provider9 = new MockProvider();
    provider9.contractBalance = ethers.parseEther('0.5'); // 0.5 tokens (less than 1% of target)
    await runScenario('Very Low Balance', provider9, { shouldExecute: true, isBuy: true });
}

// Run all scenarios
testAllScenarios().catch(console.error); 