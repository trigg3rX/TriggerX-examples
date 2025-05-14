require('dotenv').config();
const { ethers } = require('ethers');

// ABI for the contracts we need to interact with
const ARBITRAGE_ABI = [
    "function dex1() view returns (address)",
    "function dex2() view returns (address)",
    "function token1() view returns (address)",
    "function token2() view returns (address)",
    "function executeArbitrage(uint256 amount, bool buyFromDex1) external"
];

const DEX_ABI = [
    "function getOutputAmount(address _tokenIn, uint256 _amountIn) view returns (uint256)",
    "function getCurrentPrice() view returns (uint256)"
];

const ERC20_ABI = [
    "function balanceOf(address account) view returns (uint256)",
    "function decimals() view returns (uint8)",
    "function symbol() view returns (string)",
    "function name() view returns (string)"
];

async function checkContractBalance(provider, arbitrageAddress, amount) {
    try {
        const arbitrageContract = new ethers.Contract(arbitrageAddress, ARBITRAGE_ABI, provider);

        // Get token1 address
        const token1Address = await arbitrageContract.token1();
        const token1 = new ethers.Contract(token1Address, ERC20_ABI, provider);

        // Get token details
        const token1Decimals = await token1.decimals();
        const token1Symbol = await token1.symbol();
        const token1Name = await token1.name();

        console.log("\nToken Details:");
        console.log("Name:", token1Name);
        console.log("Symbol:", token1Symbol);
        console.log("Decimals:", token1Decimals);
        console.log("Address:", token1Address);

        // Check contract's token balance
        const contractBalance = await token1.balanceOf(arbitrageAddress);
        console.log("\nContract's Token Balance:");
        console.log("Raw Balance:", contractBalance.toString());
        console.log("Formatted Balance:", ethers.formatUnits(contractBalance, token1Decimals));
        console.log("Required Amount:", ethers.formatUnits(amount, token1Decimals));

        if (contractBalance < amount) {
            throw new Error(`Contract has insufficient tokens. Required: ${ethers.formatUnits(amount, token1Decimals)}, Available: ${ethers.formatUnits(contractBalance, token1Decimals)}`);
        }

        return true;
    } catch (error) {
        console.error("Error checking contract balance:", error.message);
        throw error;
    }
}

async function executeArbitrage(provider, arbitrageAddress, amount, buyFromDex1) {
    try {
        // First check contract's token balance
        await checkContractBalance(provider, arbitrageAddress, amount);

        // Create a signer using the private key from .env
        const privateKey = process.env.PRIVATE_KEY;
        if (!privateKey) {
            throw new Error("PRIVATE_KEY not found in .env file");
        }
        const signer = new ethers.Wallet(privateKey, provider);

        // Create contract instance with signer
        const arbitrageContract = new ethers.Contract(arbitrageAddress, ARBITRAGE_ABI, signer);

        console.log("\nExecuting arbitrage transaction...");
        console.log("Amount:", ethers.formatUnits(amount, 18));
        console.log("Buy from DEX1:", buyFromDex1);

        // Execute the arbitrage
        const tx = await arbitrageContract.executeArbitrage(amount, buyFromDex1);
        console.log("Transaction sent:", tx.hash);

        // Wait for transaction confirmation
        const receipt = await tx.wait();
        console.log("Transaction confirmed in block:", receipt.blockNumber);

        return receipt;
    } catch (error) {
        console.error("Error executing arbitrage:", error.message);
        throw error;
    }
}

async function checkArbitrageOpportunity(provider, arbitrageAddress) {
    try {
        // Create contract instances
        const arbitrageContract = new ethers.Contract(arbitrageAddress, ARBITRAGE_ABI, provider);

        // Get DEX and token addresses
        const dex1Address = await arbitrageContract.dex1();
        const dex2Address = await arbitrageContract.dex2();
        const token1Address = await arbitrageContract.token1();
        const token2Address = await arbitrageContract.token2();

        console.log("Contract addresses:");
        console.log("DEX1:", dex1Address);
        console.log("DEX2:", dex2Address);
        console.log("Token1:", token1Address);
        console.log("Token2:", token2Address);

        // Create contract instances for DEXes and tokens
        const dex1 = new ethers.Contract(dex1Address, DEX_ABI, provider);
        const dex2 = new ethers.Contract(dex2Address, DEX_ABI, provider);
        const token1 = new ethers.Contract(token1Address, ERC20_ABI, provider);
        const token2 = new ethers.Contract(token2Address, ERC20_ABI, provider);

        // Get token decimals
        const token1Decimals = await token1.decimals();
        const amount = ethers.parseUnits("10", token1Decimals); // Check with 5 tokens
        const minProfitBps = 100; // 1% minimum profit

        // Get output amounts from both DEXes
        const dex1Output = await dex1.getOutputAmount(token1Address, amount);
        const dex2Output = await dex2.getOutputAmount(token1Address, amount);

        console.log("\nPrice Information:");
        console.log("DEX1 Output:", ethers.formatUnits(dex1Output, token1Decimals));
        console.log("DEX2 Output:", ethers.formatUnits(dex2Output, token1Decimals));

        // Check for arbitrage opportunity
        if (dex1Output > dex2Output) {
            const profitAmount = dex1Output - dex2Output;
            const profitBps = (profitAmount * 10000n) / dex2Output;

            if (profitBps >= BigInt(minProfitBps)) {
                console.log("\nArbitrage opportunity found!");
                console.log("Strategy: Buy from DEX1, sell on DEX2");
                console.log("Expected profit:", ethers.formatUnits(profitAmount, token1Decimals));
                console.log("Profit in basis points:", profitBps.toString());
                return {
                    hasOpportunity: true,
                    profit: profitAmount,
                    buyFromDex1: true,
                    amount: amount
                };
            }
        } else if (dex2Output > dex1Output) {
            const profitAmount = dex2Output - dex1Output;
            const profitBps = (profitAmount * 10000n) / dex1Output;

            if (profitBps >= BigInt(minProfitBps)) {
                console.log("\nArbitrage opportunity found!");
                console.log("Strategy: Buy from DEX2, sell on DEX1");
                console.log("Expected profit:", ethers.formatUnits(profitAmount, token1Decimals));
                console.log("Profit in basis points:", profitBps.toString());
                return {
                    hasOpportunity: true,
                    profit: profitAmount,
                    buyFromDex1: false,
                    amount: amount
                };
            }
        }

        console.log("\nNo profitable arbitrage opportunity found");
        return {
            hasOpportunity: false,
            profit: 0n,
            buyFromDex1: false,
            amount: 0n
        };
    } catch (error) {
        console.error("Error in checkArbitrageOpportunity:", error.message);
        throw error;
    }
}

async function main() {
    try {
        const RPC = process.env.BASE_SEPOLIA_RPC_URL;
        if (!RPC) {
            throw new Error("BASE_SEPOLIA_RPC_URL not found in .env file");
        }

        // Connect to the network
        const provider = new ethers.JsonRpcProvider(RPC);

        // Verify connection
        const network = await provider.getNetwork();
        console.log("Connected to network:", network.name, "(Chain ID:", network.chainId, ")");

        // Arbitrage contract address
        const arbitrageAddress = process.env.ARBITRAGE_CONTRACT_ADDRESS;
        if (!arbitrageAddress) {
            throw new Error("ARBITRAGE_CONTRACT_ADDRESS not found in .env file");
        }

        // Check for arbitrage opportunity
        const opportunity = await checkArbitrageOpportunity(provider, arbitrageAddress);

        if (opportunity.hasOpportunity) {
            console.log("\nExecuting arbitrage...");
            await executeArbitrage(
                provider,
                arbitrageAddress,
                opportunity.amount,
                opportunity.buyFromDex1
            );
        }
    } catch (error) {
        console.error("Error:", error.message);
        process.exit(1);
    }
}

// Run the script
main(); 