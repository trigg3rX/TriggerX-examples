# Arbitrage System

This project implements a decentralized arbitrage system that can execute trades between two DEXes to capture price differences. The system includes token contracts, DEX contracts, and an arbitrage contract that coordinates the trades.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js and npm
- A wallet with some ETH on the target network (e.g., Sepolia)

## Project Structure

```
arbitrage/
├── src/
│   ├── Arbitrage.sol      # Main arbitrage contract
│   ├── DEX1.sol          # First DEX implementation
│   ├── DEX2.sol          # Second DEX implementation
│   ├── LiquidityToken1.sol # First token contract
│   └── LiquidityToken2.sol # Second token contract
├── script/
│   └── Deploy.s.sol      # Deployment script
├── test/
│   └── ArbitrageSystem.t.sol # Test suite
└── foundry.toml          # Foundry configuration
```

## Setup

1. Clone the repository:
```bash
git clone https://github.com/trigg3rX/TriggerX-examples.git
cd arbitrage
```

2. Install dependencies:
```bash
forge install
```

3. Create a `.env` file in the root directory with the following variables:
```env
PRIVATE_KEY=0x...  # Your wallet private key with 0x prefix
SEPOLIA_RPC_URL=...  # Your Sepolia RPC URL
ETHERSCAN_API_KEY=...  # Your Etherscan API key
```

## Deployment

The deployment script will:
1. Deploy the arbitrage contract
2. Mint 100 tokens of each type to the arbitrage contract
3. Set up the necessary connections between contracts

To deploy:

```bash
# Make sure you're in the arbitrage directory
cd arbitrage

# Deploy to Sepolia
forge script script/Deploy.s.sol:DeployArbitrage --rpc-url https://sepolia.base.org --broadcast
```

## Contract Addresses

The system uses the following pre-deployed contract addresses:

- LiquidityToken1: `0x0f1D6c76774926Bf4C4f5a8629066AF006e1B570`
- LiquidityToken2: `0xe1A327AE69156ee7b5cE59A057b823c760438535`
- DEX1: `0xD05E72F6C74Be61d74Cb7e003f6E869C287606b0`
- DEX2: `0x02F957CF974797CF2CdeBd43994232A38802581c`

## Usage

### Executing Arbitrage

The arbitrage contract can be used to execute trades when price differences exist between the two DEXes. The contract owner can call:

```solidity
function executeArbitrage(uint256 amount, bool buyFromDex1)
```

Parameters:
- `amount`: Amount of token1 to use for the arbitrage
- `buyFromDex1`: If true, buy from DEX1 and sell on DEX2; if false, do the opposite

### Withdrawing Tokens

The contract owner can withdraw tokens from the arbitrage contract:

```solidity
function withdrawTokens(address _token, uint256 _amount)
```

Parameters:
- `_token`: Address of the token to withdraw
- `_amount`: Amount of tokens to withdraw

## Testing

Run the test suite:

```bash
forge test
```

## Security

- The arbitrage contract is Ownable, meaning only the owner can execute trades and withdraw tokens
- All token transfers use OpenZeppelin's SafeERC20 library
- The contract includes checks for sufficient balances and successful transfers

## License

MIT

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
