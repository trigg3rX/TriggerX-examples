# 🪙 StakingRewards - TriggerX Event-Based Job Example

This project demonstrates how to **automate event-based reward distribution** using [TriggerX](https://www.triggerx.network/). Built with [Foundry](https://book.getfoundry.sh/), the `StakingRewards` smart contract allows users to stake tokens and automatically receive proportional rewards **when a threshold is reached**, with distribution triggered by **TriggerX**.

> ⚡ This example shows how **TriggerX** can react to **on-chain events** like milestone achievements to trigger functions.
> 📚 Check out the guide: [Create Your First Job on TriggerX](https://triggerx.gitbook.io/triggerx-docs/create-your-first-job)

---

## 🧠 What This Contract Does

The `StakingRewards` contract lets users:

- 🔐 Stake and unstake a specified ERC20 token (`stakingToken`)
- 🪙 Earn rewards in another ERC20 token (`rewardToken`)
- 🚀 Automatically trigger `distributeRewards()` **only** when a **threshold milestone** is crossed
- 📡 Emit a `ThresholdReached` event, which **TriggerX listens to** and uses to call `distributeRewards()`

---

## ⚙️ Features

- **Milestone-Based Distribution:** Rewards are only distributed when total staked amount crosses a new milestone (`threshold * N`).
- **Proportional Rewards:** Rewards are split proportionally based on the amount each user has staked.
- **Automatic Cleanup:** Automatically removes fully-unstaked users from the stakers array.
- **TriggerX Integration:** `distributeRewards()` is called automatically based on the emitted `ThresholdReached` event.
- **Events Emitted:**
  - `Staked`: When a user stakes tokens
  - `Unstaked`: When a user unstakes
  - `ThresholdReached`: When a new staking milestone is crossed
  - `RewardsDistributed`: When rewards are sent out

---

## 📦 Foundry Setup

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed

### Getting Started

```bash
git clone https://github.com/your-username/staking-rewards.git
cd staking-rewards
forge install
```

### Run Tests

```bash
forge test
```

### Deploy on supported Testnet

1. **Create a `.env`** file:

```env
PRIVATE_KEY=your_private_key
OP_SEPOLIA_RPC_URL=https://sepolia.optimism.io
OPTIMISM_ETHERSCAN_API_KEY=your_etherscan_api_key
```

2. **Deploy & Verify**:

```bash
forge script script/DeployStakingRewards.s.sol \
  --fork-url $OP_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

> ✅ *Verification enables function selection in the TriggerX interface.*

3. **Fund the Contract with Rewards**:

> ⚠️ **Important**: After deployment, send some `rewardToken` to the contract so it can distribute rewards when milestones are reached.

---

## ⚡ TriggerX Integration

Use **TriggerX** to call `distributeRewards()` automatically **when `ThresholdReached` is emitted.**

### ✅ Steps to Set It Up

1. Go to: [Create Your First Job on TriggerX](https://triggerx.gitbook.io/triggerx-docs/create-your-first-job)
2. Choose **Event-Based Trigger**
3. Select your deployed contract and listen for the `ThresholdReached` event
4. Select the `distributeRewards()` function to call when that event is emitted  
5. **Use the provided script template from TriggerX docs** (no arguments needed)  
   👉 Template Link: [TriggerX Job Script Template](https://triggerx.gitbook.io/triggerx-docs/create-your-first-job#template)
6. Upload the script to IPFS and paste the IPFS URL in the TriggerX job setup
7. Done! TriggerX will now **automatically distribute rewards** when a new staking milestone is reached 🎯

---

## 🔐 Security Considerations

- Only stakers can stake/unstake their tokens.
- Reward distribution can only be triggered externally via `distributeRewards()`.
- Ensure enough `rewardToken` balance exists in the contract for distribution to succeed.
- Looping over many stakers may hit gas limits; for large staker pools, consider batching or snapshot-based approaches.

---

## 📜 License

MIT

---

## 🙌 Contribution

Feel free to open PRs or issues to improve this example!  
Have an idea for another TriggerX automation use case? Let us know!
