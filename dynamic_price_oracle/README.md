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

## 🚀 Automation with TriggerX

We’ve created a script and deployed it to IPFS that:
- Calls `prepareUpdateParams()` from the oracle
- Uses those parameters to call `updatePrices()` automatically

### 🧪 View the Trigger Script

📦 [IPFS - Trigger Script](https://ipfs.io/ipfs/QmDummyHashExample123456789)  
*(Replace with your actual IPFS CID when available)*

---

## ⚙️ TriggerX Integration Steps

Follow these steps to automate price updates using TriggerX:

1. **Prepare Your Script**  
   Create a script that:
   - Calls `prepareUpdateParams()` on the `DynamicPriceOracle`
   - Passes the returned struct into `updatePrices()`  

2. **Upload to IPFS**  
   Use tools like [web3.storage](https://web3.storage) or IPFS CLI to upload the script.

3. **Go to [TriggerX App](https://app.triggerx.io)**  
   Create a new trigger:
   - Select the **DynamicPriceOracle** contract address
   - Set method to `updatePrices(PriceUpdateParams)`
   - Link your IPFS script using the IPFS hash

4. **Configure Execution Settings**  
   - Set frequency (e.g. every 1 hour)
   - Define gas limits and simulation checks
   - Choose AVS (automation validator service) node(s)

5. **Launch the Job**  
   Once deployed, AVS will monitor and automatically call `updatePrices()` using fresh parameters.

---

## 📦 Deployment Parameters

When deploying `DynamicPriceOracle`, provide:
- `_minUpdateInterval`: Minimum seconds between price updates
- `_volatilityThreshold`: Multiplier for calculating deviation thresholds
- `_priceFeed`: Address of a price feed (mock or Chainlink-compatible)

---

## 🧪 Local Development

Install dependencies:
```bash
forge install
```

Run tests:
```bash
forge test
```

Simulate updates:
```bash
forge script scripts/UpdatePrices.s.sol --fork-url $RPC_URL --broadcast
```

---

## 📜 License

MIT

---

## 🙌 Contribution

Feel free to open PRs or issues to improve this example!

