# Pre-deployed Contract Addresses

This document contains the addresses of all pre-deployed contracts used in the arbitrage system across different networks.

## Base Sepolia Network

### Token Addresses
- LiquidityToken1 (LT1): `0x04c08015B3E4576C6D075d94Ed56Ba27Abd5758a`
- LiquidityToken2 (LT2): `0xa014218b898d422bF36064AEb6f99608790D26aE`

### DEX Addresses
- DEX1: `0x9cDE3307FF813F3e47C188388954D920AD59b09A`
- DEX2: `0x0CC94eb11b10980Eb3979a67d62A53Bb297a79b7`

### Arbitrage Contract
- Address: `0x1A14c7dfDd0f3513c4CaC29590D16706df876E3f`

### IPFS Script Links
- Condition Script: `https://ipfs.io/ipfs/QmUz6X9HUTwh8bJuRY81sJ8ALKHSfSmjxfuF9aqw9oX3J3`
- Parameter Script: `https://ipfs.io/ipfs/QmVyg9rTsNkmVtpi7oThikb2zPpUiF8b4818XZjKu4nD6B`

## Optimism Sepolia Network

### Token Addresses
- LiquidityToken1 (LT1): `0x6BBbfabe526Df61Ae9F2DC7264f09bAA137247b9`
- LiquidityToken2 (LT2): `0x0f1D6c76774926Bf4C4f5a8629066AF006e1B570`

### DEX Addresses
- DEX1: `0xdB67966cc9ebC62940392Ff193dCF4f021361a35`
- DEX2: `0x32f2D7626FbFD889605a511Dd959dCc4Ce4627F1`

### Arbitrage Contract
- Address: `0x71a68cC59B6251F7FFE225f0579777E73EE4FcC6`

### IPFS Script Links
- Condition Script: `https://ipfs.io/ipfs/QmQCWY1UF2AcvbTeD38cuRvDB5uT1eB3efY8KiJfMAFhqV`
- Parameter Script: `https://ipfs.io/ipfs/QmNdV7KFLps3wzC5mMzAXgidcL3f3Y71e1fLtF23P7aDFm`

## Usage Notes

1. When interacting with the arbitrage system, make sure to use the correct network-specific addresses.
2. The condition checking scripts are currently configured to use the Optimism Sepolia network by default.
3. To switch networks, update the RPC URL and contract addresses in the respective scripts.
4. Contracts are given in src Directory, if you want to deploy by your own. Make sure to change address while deploying arbitrage contract via `script/Deploy.s.sol`

## Network RPC URLs

- Base Sepolia: `https://sepolia.base.org`
- Optimism Sepolia: `https://sepolia.optimism.io`
