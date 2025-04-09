# ⏱️ Dynamic Price Oracle – Automated with TriggerX

This project showcases how to automate price updates using the `DynamicPriceOracle` smart contract and **TriggerX**, enabling decentralized, condition-based oracle updates based on volatility, trading thresholds, and time.

---

## 🧠 Key Concepts

- **Volatility-Aware Updates**: Adjusts price update thresholds dynamically based on recent market volatility.
- **Pair-Specific Logic**: Only updates trading pairs when price deviation crosses a calculated threshold.
- **Confirmation Requirements**: Varies the number of confirmations needed based on recent volatility.
- **24h Data Tracking**: Tracks and updates rolling 24-hour volatility and trading volume for each pair.

---

## 🔁 Use Case

This oracle is perfect for DeFi projects and data-driven dApps that:
- Require frequent yet gas-optimized price updates
- Want dynamic control over when and how prices are refreshed
- Need logic for rejecting minor/noisy market fluctuations

---

## 🛠️ Contracts

### `DynamicPriceOracle.sol`

A robust price oracle that:
- Supports multiple trading pairs
- Stores price, volatility, and volume per pair
- Enforces a minimum time between updates
- Uses a mock price feed (can be swapped for real Chainlink feed)

### `MockPriceFeed.sol`

A simple mock contract to simulate price feeds for local testing and simulation.

---
## 📦 Foundry Setup

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed

### Getting Started

```bash
git clone https://github.com/your-username/dynamic-price-oracle.git
cd dynamic-price-oracle
forge install
```

### Run Tests

```bash
forge test
```

### Deploy on supported Testnet

1. **Create a `.env`** file with:

```env
PRIVATE_KEY=your_private_key
OP_SEPOLIA_RPC_URL=https://sepolia.optimism.io
OPTIMISM_ETHERSCAN_API_KEY=your_etherscan_api_key
```

2. **Deploy & Verify**:

```bash
forge script script/DeployDynamicPriceOracle.s.sol \
  --fork-url $OP_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

> ✅ *Verification enables proper function recognition on TriggerX.*

3. **Register Pair Data** (after deployment):

Call `setInitialPrice()` with token pair, initial price, and other settings  
*(or use a helper script from the repo to automate it)*

---

## ⏱️ TriggerX Integration

Use **TriggerX** to automate calls to `updatePrices()` using values returned from `prepareUpdateParams()`.

### ✅ Steps to Set It Up

1. Go to: [Create Your First Job on TriggerX](https://triggerx.gitbook.io/triggerx-docs/create-your-first-job)
2. Choose **Time-Based Trigger**
3. Set the interval (e.g., every 15 minutes)
4. Provide the contract address and target function: `updatePrices((PriceUpdateParams))`
5. Use a custom script that:
   - Calls `prepareUpdateParams()`
   - Passes the result to `updatePrices()`

6. Upload the script to IPFS

> 📦 Example script: [IPFS - Trigger Script](https://ipfs.io/ipfs/QmDummyHashExample123456789)

7. Paste your IPFS URL in the TriggerX Job setup
8. ✅ You’re done! TriggerX will now keep your oracle updated on-chain

---

## 🔐 Security Considerations

- Only owner can configure new token pairs.
- `updatePrices()` will revert if called too soon or with stale parameters.
- Cooldown and volatility thresholds protect against spam and noise updates.

---

## 📜 License

MIT

---

## 🙌 Contribution

Found an issue? Want to extend volatility metrics?  
PRs are welcome — let's build smarter oracles together!
```

