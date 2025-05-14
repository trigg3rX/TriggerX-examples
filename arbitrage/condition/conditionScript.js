const { ethers } = require("ethers");

// ABI for the contracts we need to interact with
const ARBITRAGE_ABI = [
    "function dex1() view returns (address)",
    "function dex2() view returns (address)",
    "function token1() view returns (address)",
    "function token2() view returns (address)",
];

const DEX_ABI = [
    "function getOutputAmount(address _tokenIn, uint256 _amountIn) view returns (uint256)",
    "function getCurrentPrice() view returns (uint256)",
];

const ERC20_ABI = [
    "function balanceOf(address account) view returns (uint256)",
    "function decimals() view returns (uint8)",
    "function symbol() view returns (string)",
    "function name() view returns (string)",
];

async function checkArbitrageOpportunity(provider, arbitrageAddress) {
    try {
        console.log("\nChecking arbitrage opportunity...");
        console.log("Arbitrage Contract:", arbitrageAddress);

        // Create contract instances
        const arbitrageContract = new ethers.Contract(
            arbitrageAddress,
            ARBITRAGE_ABI,
            provider
        );

        // Get DEX and token addresses
        const dex1Address = await arbitrageContract.dex1();
        const dex2Address = await arbitrageContract.dex2();
        const token1Address = await arbitrageContract.token1();
        const token2Address = await arbitrageContract.token2();

        console.log("\nContract Addresses:");
        console.log("DEX1:", dex1Address);
        console.log("DEX2:", dex2Address);
        console.log("Token1:", token1Address);
        console.log("Token2:", token2Address);

        // Create contract instances for DEXes and tokens
        const dex1 = new ethers.Contract(dex1Address, DEX_ABI, provider);
        const dex2 = new ethers.Contract(dex2Address, DEX_ABI, provider);
        const token1 = new ethers.Contract(token1Address, ERC20_ABI, provider);
        const token2 = new ethers.Contract(token2Address, ERC20_ABI, provider);

        // Get token details
        const token1Decimals = await token1.decimals();
        const token1Symbol = await token1.symbol();
        const token2Symbol = await token2.symbol();

        console.log("\nToken Details:");
        console.log("Token1 Symbol:", token1Symbol);
        console.log("Token2 Symbol:", token2Symbol);
        console.log("Token1 Decimals:", token1Decimals);

        const amount = ethers.parseUnits("50", token1Decimals); // Check with 50 tokens
        const minProfitBps = 100; // 1% minimum profit

        console.log(
            "\nChecking with amount:",
            ethers.formatUnits(amount, token1Decimals),
            token1Symbol
        );
        console.log("Minimum profit threshold:", minProfitBps, "basis points (1%)");

        // Get output amounts from both DEXes
        const dex1Output = await dex1.getOutputAmount(token1Address, amount);
        const dex2Output = await dex2.getOutputAmount(token1Address, amount);

        console.log("\nPrice Information:");
        console.log(
            "DEX1 Output:",
            ethers.formatUnits(dex1Output, token1Decimals),
            token2Symbol
        );
        console.log(
            "DEX2 Output:",
            ethers.formatUnits(dex2Output, token1Decimals),
            token2Symbol
        );

        // Check for arbitrage opportunity
        if (dex1Output > dex2Output) {
            const profitAmount = dex1Output - dex2Output;
            const profitBps = (profitAmount * 10000n) / dex2Output;

            console.log("\nPotential arbitrage found (DEX1 > DEX2):");
            console.log(
                "Profit Amount:",
                ethers.formatUnits(profitAmount, token1Decimals),
                token2Symbol
            );
            console.log("Profit in basis points:", profitBps.toString());

            if (profitBps >= BigInt(minProfitBps)) {
                console.log("\n✅ Profitable arbitrage opportunity found!");
                console.log("Strategy: Buy from DEX1, sell on DEX2");
                return {
                    shouldExecute: true,
                    params: {
                        amount: amount,
                        buyFromDex1: true,
                    },
                    dex1Output: dex1Output,
                    dex2Output: dex2Output,
                    profitAmount: profitAmount,
                    profitBps: profitBps,
                };
            } else {
                console.log("❌ Profit below minimum threshold");
            }
        } else if (dex2Output > dex1Output) {
            const profitAmount = dex2Output - dex1Output;
            const profitBps = (profitAmount * 10000n) / dex1Output;

            console.log("\nPotential arbitrage found (DEX2 > DEX1):");
            console.log(
                "Profit Amount:",
                ethers.formatUnits(profitAmount, token1Decimals),
                token2Symbol
            );
            console.log("Profit in basis points:", profitBps.toString());

            if (profitBps >= BigInt(minProfitBps)) {
                console.log("\n✅ Profitable arbitrage opportunity found!");
                console.log("Strategy: Buy from DEX2, sell on DEX1");
                return {
                    shouldExecute: true,
                    params: {
                        amount: amount,
                        buyFromDex1: false,
                    },
                    dex1Output: dex1Output,
                    dex2Output: dex2Output,
                    profitAmount: profitAmount,
                    profitBps: profitBps,
                };
            } else {
                console.log("❌ Profit below minimum threshold");
            }
        } else {
            console.log("\n❌ No price difference found between DEXes");
        }

        return {
            shouldExecute: false,
            dex1Output: dex1Output,
            dex2Output: dex2Output,
        };
    } catch (error) {
        console.error("\n❌ Error in checkArbitrageOpportunity:", error.message);
        return {
            shouldExecute: false,
            error: error.message,
        };
    }
}

module.exports = {
    checkArbitrageOpportunity,
};
