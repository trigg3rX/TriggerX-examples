package main

import (
	"fmt"
	"math/big"
	"strings"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// ConditionResult represents the result of the arbitrage check
type ConditionResult struct {
	Satisfied bool
}

// Contract ABIs
const (
	arbitrageABI = `[{"constant":true,"inputs":[],"name":"dex1","outputs":[{"name":"","type":"address"}],"type":"function"},
		{"constant":true,"inputs":[],"name":"dex2","outputs":[{"name":"","type":"address"}],"type":"function"},
		{"constant":true,"inputs":[],"name":"token1","outputs":[{"name":"","type":"address"}],"type":"function"},
		{"constant":true,"inputs":[],"name":"token2","outputs":[{"name":"","type":"address"}],"type":"function"}]`

	dexABI = `[{"constant":true,"inputs":[{"name":"_tokenIn","type":"address"},{"name":"_amountIn","type":"uint256"}],"name":"getOutputAmount","outputs":[{"name":"","type":"uint256"}],"type":"function"}]`

	erc20ABI = `[{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"}]`
)

func condition() ConditionResult {
	// Connect to Ethereum network (replace with your network URL)
	client, err := ethclient.Dial("https://sepolia.base.org")
	if err != nil {
		return ConditionResult{Satisfied: false}
	}

	// Parse ABIs
	arbitrageABIParsed, err := abi.JSON(strings.NewReader(arbitrageABI))
	if err != nil {
		return ConditionResult{Satisfied: false}
	}

	dexABIParsed, err := abi.JSON(strings.NewReader(dexABI))
	if err != nil {
		return ConditionResult{Satisfied: false}
	}

	erc20ABIParsed, err := abi.JSON(strings.NewReader(erc20ABI))
	if err != nil {
		return ConditionResult{Satisfied: false}
	}

	// Arbitrage contract address (replace with your contract address)
	arbitrageAddress := common.HexToAddress("0x1A14c7dfDd0f3513c4CaC29590D16706df876E3f")

	// Create contract instances
	arbitrageContract := bind.NewBoundContract(arbitrageAddress, arbitrageABIParsed, client, client, nil)

	// Get DEX and token addresses
	var dex1Address, dex2Address, token1Address common.Address
	var out []interface{}

	// Get DEX1 address
	err = arbitrageContract.Call(nil, &out, "dex1")
	if err != nil {
		return ConditionResult{Satisfied: false}
	}
	if len(out) == 0 {
		return ConditionResult{Satisfied: false}
	}
	dex1Address = out[0].(common.Address)

	// Get DEX2 address
	out = nil // Clear the output slice
	err = arbitrageContract.Call(nil, &out, "dex2")
	if err != nil {
		return ConditionResult{Satisfied: false}
	}
	if len(out) == 0 {
		return ConditionResult{Satisfied: false}
	}
	dex2Address = out[0].(common.Address)

	// Get Token1 address
	out = nil // Clear the output slice
	err = arbitrageContract.Call(nil, &out, "token1")
	if err != nil {
		return ConditionResult{Satisfied: false}
	}
	if len(out) == 0 {
		return ConditionResult{Satisfied: false}
	}
	token1Address = out[0].(common.Address)

	// Create DEX contract instances
	dex1Contract := bind.NewBoundContract(dex1Address, dexABIParsed, client, client, nil)
	dex2Contract := bind.NewBoundContract(dex2Address, dexABIParsed, client, client, nil)

	// Get token decimals
	token1Contract := bind.NewBoundContract(token1Address, erc20ABIParsed, client, client, nil)
	var decimals uint8
	out = nil // Clear the output slice
	err = token1Contract.Call(nil, &out, "decimals")
	if err != nil {
		return ConditionResult{Satisfied: false}
	}
	if len(out) == 0 {
		return ConditionResult{Satisfied: false}
	}
	decimals = out[0].(uint8)

	// Calculate amount to check (50 tokens)
	amount := new(big.Int).Mul(big.NewInt(50), new(big.Int).Exp(big.NewInt(10), big.NewInt(int64(decimals)), nil))

	// Get output amounts from both DEXes
	var dex1Output, dex2Output big.Int
	out = nil // Clear the output slice
	err = dex1Contract.Call(nil, &out, "getOutputAmount", token1Address, amount)
	if err != nil {
		return ConditionResult{Satisfied: false}
	}
	if len(out) == 0 {
		return ConditionResult{Satisfied: false}
	}
	dex1Output = *out[0].(*big.Int)

	out = nil // Clear the output slice
	err = dex2Contract.Call(nil, &out, "getOutputAmount", token1Address, amount)
	if err != nil {
		return ConditionResult{Satisfied: false}
	}
	if len(out) == 0 {
		return ConditionResult{Satisfied: false}
	}
	dex2Output = *out[0].(*big.Int)

	// Check for arbitrage opportunity
	minProfitBps := big.NewInt(100) // 1% minimum profit

	if dex1Output.Cmp(&dex2Output) > 0 {
		profitAmount := new(big.Int).Sub(&dex1Output, &dex2Output)
		profitBps := new(big.Int).Mul(profitAmount, big.NewInt(10000))
		profitBps.Div(profitBps, &dex2Output)

		if profitBps.Cmp(minProfitBps) >= 0 {
			return ConditionResult{Satisfied: true}
		}
	} else if dex2Output.Cmp(&dex1Output) > 0 {
		profitAmount := new(big.Int).Sub(&dex2Output, &dex1Output)
		profitBps := new(big.Int).Mul(profitAmount, big.NewInt(10000))
		profitBps.Div(profitBps, &dex1Output)

		if profitBps.Cmp(minProfitBps) >= 0 {
			return ConditionResult{Satisfied: true}
		}
	}

	return ConditionResult{Satisfied: false}
}

func main() {
	result := condition()
	fmt.Println("Condition satisfied:", result.Satisfied)
}
