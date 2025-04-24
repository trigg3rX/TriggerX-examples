const dotenv = require("dotenv");
const ethers = require("ethers");
const axios = require("axios");
const path = require("path");
const fs = require("fs");

dotenv.config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const RPC_URL = process.env.OP_SEPOLIA_RPC;
const FACTORY_ADDRESS = "0x9eF8E2E3A3B5B813b2fc787522fca2654738B92b";
const ETHERSCAN_API_KEY = process.env.OPSCAN_API_KEY;
const BLOCKSCOUT_API_KEY = process.env.OP_BLOCKSCOUT_API_KEY;
const ETHERSCAN_API_URL = "https://api-sepolia-optimistic.etherscan.io/api";
const BLOCKSCOUT_API_URL = "https://sepolia-optimism.blockscout.com/api/v2/smart-contracts/verify";

if (!PRIVATE_KEY || !RPC_URL || !FACTORY_ADDRESS || !ETHERSCAN_API_KEY || !BLOCKSCOUT_API_KEY) {
  console.error("Missing env vars. Please set PRIVATE_KEY, RPC_URL, FACTORY_ADDRESS, ETHERSCAN_API_KEY, and OP_BLOCKSCOUT_API_KEY in .env");
  process.exit(1);
}

// Read contract from src/ directory
const contractPath = path.join(__dirname, "src", "BalanceMaintainer.sol");
let BALANCE_MAINTAINER_SOURCE = "";
try {
  BALANCE_MAINTAINER_SOURCE = fs.readFileSync(contractPath, "utf8");
} catch (err) {
  console.error("❌ Could not read BalanceMaintainer.sol from src/ directory");
  process.exit(1);
}

async function verifyOnEtherscan(contractAddress, constructorArguments) {
  console.log("🔍 Submitting source verification to Etherscan...");
  const params = new URLSearchParams({
    apikey: ETHERSCAN_API_KEY,
    module: "contract",
    action: "verifysourcecode",
    contractaddress: contractAddress,
    sourceCode: BALANCE_MAINTAINER_SOURCE,
    codeformat: "solidity-single-file",
    contractname: "BalanceMaintainer",
    compilerversion: "v0.8.20+commit.610ad54b",
    optimizationUsed: "1",
    runs: "200",
    constructorArguements: constructorArguments,
  });

  const response = await axios.post(ETHERSCAN_API_URL, params.toString(), {
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
  });
  console.log("📡 Etherscan response:", response.data);
  return response.data;
}

async function verifyOnBlockscout(contractAddress, constructorArguments) {
  console.log("🔍 Submitting source verification to Blockscout...");
  const verificationData = {
    addressHash: contractAddress,
    name: "BalanceMaintainer",
    compilerVersion: "v0.8.20+commit.610ad54b",
    optimization: true,
    optimizationRuns: 200,
    contractSourceCode: BALANCE_MAINTAINER_SOURCE,
    constructorArguments: constructorArguments,
    autodetectConstructorArguments: false
  };

  try {
    const response = await axios.post(BLOCKSCOUT_API_URL, verificationData, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${BLOCKSCOUT_API_KEY}`
      }
    });
    console.log("📡 Blockscout response:", response.data);
    return response.data;
  } catch (error) {
    console.error("❌ Error verifying contract on Blockscout:", error.response?.data || error.message);
    throw error;
  }
}

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const signer = new ethers.Wallet(PRIVATE_KEY, provider);

  const factoryAbi = [
    "event BalanceMaintainerDeployed(address indexed owner, address indexed balanceMaintainer)",
    "function createBalanceMaintainer() payable returns (address)",
    "function userContract(address) view returns (address)"
  ];
  const factory = new ethers.Contract(FACTORY_ADDRESS, factoryAbi, signer);

  console.log("▶️ Deploying new BalanceMaintainer with 0.0001 ETH...");
  const tx = await factory.createBalanceMaintainer({ value: ethers.parseEther("0.0001") });
  console.log("⏳ Waiting for transaction confirmation...");
  const receipt = await tx.wait();
  console.log("✅ Transaction confirmed. Receipt:", receipt.hash);

//   // Add a 10-second pause
//   console.log("⏸️ Pausing for 10 seconds before fetching address...");
//   await new Promise(resolve => setTimeout(resolve, 10000));
//   console.log("⏯️ Resuming script...");

  console.log("ℹ️ Fetching address from userContracts mapping...");
  const childAddress = await factory.userContract(signer.address);
  console.log("✅ Address from mapping:", childAddress);

  const constructorArguments = ethers.AbiCoder.defaultAbiCoder()
    .encode(["address"], [signer.address])
    .replace(/^0x/, "");

  // Verify on both explorers
  console.log("\n=== Starting Verification Process ===");
  
  try {
    // Verify on Etherscan
    const etherscanResult = await verifyOnEtherscan(childAddress, constructorArguments);
    console.log("\n=== Etherscan Verification Complete ===");
    
    // Verify on Blockscout
    const blockscoutResult = await verifyOnBlockscout(childAddress, constructorArguments);
    console.log("\n=== Blockscout Verification Complete ===");
    
    console.log("\nVerification process completed. Please check the explorers in a few minutes.");
    console.log("Etherscan URL: https://sepolia-optimistic.etherscan.io/address/" + childAddress);
    console.log("Blockscout URL: https://sepolia-optimism.blockscout.com/address/" + childAddress);
  } catch (error) {
    console.error("❌ Error during verification process:", error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});