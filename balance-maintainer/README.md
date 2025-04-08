# 🔄 BalanceMaintainer - TriggerX Automation Example

This project demonstrates an example of **automating time-based balance maintenance** using [TriggerX](https://www.triggerx.network/). Built with [Foundry](https://book.getfoundry.sh/), the `BalanceMaintainer` smart contract ensures that specific addresses always maintain a minimum balance by topping them up periodically.

> 💡 This is a great starting point for using **TriggerX** to automate time-based actions on-chain.  
> 📚 Check out the guide: [Create Your First Job on TriggerX](https://triggerx.gitbook.io/triggerx-docs/create-your-first-job)

---

## 🧠 What This Contract Does

The `BalanceMaintainer` contract allows an owner to:

- ✅ Track multiple addresses.
- 💰 Set a **minimum ETH balance** for each address.
- ⏰ Automatically **top-up** those addresses when their balance drops below the minimum (executed at regular intervals using TriggerX).
- 🔁 Enforce a **cooldown** between top-ups (default: `1 hour`).

---

## ⚙️ Features

- **Batch Configuration:** Add multiple addresses with their required balances using `setMultipleAddressesWithBalance`.
- **Automated Top-ups:** `maintainBalances` checks tracked addresses and tops them up if needed.
- **Cooldown Support:** Prevents frequent top-ups with a 1-hour cooldown window.
- **TriggerX Integration:** Automate the `maintainBalances` call with a time-based job on TriggerX.
- **Events Emitted:**
  - `BalanceToppedUp`: When an address is topped up.
  - `MinimumBalanceSet`: When a new address and balance are set.

---

## 📦 Foundry Setup

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed

### Getting Started

```bash
git clone https://github.com/your-username/balance-maintainer.git
cd balance-maintainer
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
forge script script/DeployBalanceMaintainer.s.sol \
  --fork-url $OP_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

> ✅ *Verification enables function selection in the TriggerX interface.*

---

## ⏱️ TriggerX Integration

You can use **TriggerX** to call the `maintainBalances()` function at a fixed time interval.

### ✅ Steps to Set It Up

1. Go to: [Create Your First Job on TriggerX](https://triggerx.gitbook.io/triggerx-docs/create-your-first-job)
2. Choose **Time-Based Trigger**
3. Set the interval (e.g., every hour)
4. Provide the contract address and the select target function `maintainBalances()`  
5. **Use the provided script template from TriggerX docs** (no arguments needed for this function)  
   👉 Template Link: [TriggerX Job Script Template](https://triggerx.gitbook.io/triggerx-docs/create-your-first-job#template)
6. Upload the script to IPFS and paste the IPFS URL in the TriggerX Job setup
7. Done! TriggerX will automatically call `maintainBalances()` at the specified time interval 🎯

---

## 🔐 Security Considerations

- Only the contract owner can modify tracked addresses and minimum balances.
- The contract will revert if it doesn't hold enough ETH to top up accounts.
- `maintainBalances` is protected by a cooldown window to avoid abuse.

---

## 📜 License

MIT

---

## 🙌 Contribution

Feel free to open PRs or issues to improve this example!

