package main

import (
	"encoding/json"
	"fmt"
	"math/big"
	"strings"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// ArbitrageParams represents the parameters needed for arbitrage execution
type ArbitrageParams struct {
	Amount      *big.Int `json:"amount"`
	BuyFromDex1 bool     `json:"buyFromDex1"`
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

// GetArbitrageParameters retrieves the parameters needed for arbitrage execution
func GetArbitrageParameters() (ArbitrageParams, error) {
	// Connect to Ethereum network
	client, err := ethclient.Dial("https://sepolia.base.org")
	if err != nil {
		return ArbitrageParams{}, fmt.Errorf("error connecting to network: %v", err)
	}

	// Parse ABIs
	arbitrageABIParsed, err := abi.JSON(strings.NewReader(arbitrageABI))
	if err != nil {
		return ArbitrageParams{}, fmt.Errorf("error parsing arbitrage ABI: %v", err)
	}

	dexABIParsed, err := abi.JSON(strings.NewReader(dexABI))
	if err != nil {
		return ArbitrageParams{}, fmt.Errorf("error parsing DEX ABI: %v", err)
	}

	erc20ABIParsed, err := abi.JSON(strings.NewReader(erc20ABI))
	if err != nil {
		return ArbitrageParams{}, fmt.Errorf("error parsing ERC20 ABI: %v", err)
	}

	// Arbitrage contract address
	arbitrageAddress := common.HexToAddress("0x1A14c7dfDd0f3513c4CaC29590D16706df876E3f")

	// Create contract instances
	arbitrageContract := bind.NewBoundContract(arbitrageAddress, arbitrageABIParsed, client, client, nil)

	// Get DEX and token addresses
	var dex1Address, dex2Address, token1Address common.Address
	var out []interface{}

	// Get addresses from contract
	err = arbitrageContract.Call(nil, &out, "dex1")
	if err != nil || len(out) == 0 {
		return ArbitrageParams{}, fmt.Errorf("error getting dex1 address: %v", err)
	}
	dex1Address = out[0].(common.Address)

	out = nil
	err = arbitrageContract.Call(nil, &out, "dex2")
	if err != nil || len(out) == 0 {
		return ArbitrageParams{}, fmt.Errorf("error getting dex2 address: %v", err)
	}
	dex2Address = out[0].(common.Address)

	out = nil
	err = arbitrageContract.Call(nil, &out, "token1")
	if err != nil || len(out) == 0 {
		return ArbitrageParams{}, fmt.Errorf("error getting token1 address: %v", err)
	}
	token1Address = out[0].(common.Address)

	// Create DEX contract instances
	dex1Contract := bind.NewBoundContract(dex1Address, dexABIParsed, client, client, nil)
	dex2Contract := bind.NewBoundContract(dex2Address, dexABIParsed, client, client, nil)

	// Get token decimals
	token1Contract := bind.NewBoundContract(token1Address, erc20ABIParsed, client, client, nil)
	var decimals uint8
	out = nil
	err = token1Contract.Call(nil, &out, "decimals")
	if err != nil || len(out) == 0 {
		return ArbitrageParams{}, fmt.Errorf("error getting token decimals: %v", err)
	}
	decimals = out[0].(uint8)

	// Calculate amount to check (50 tokens)
	amount := new(big.Int).Mul(big.NewInt(50), new(big.Int).Exp(big.NewInt(10), big.NewInt(int64(decimals)), nil))

	// Get output amounts from both DEXes
	var dex1Output, dex2Output big.Int
	out = nil
	err = dex1Contract.Call(nil, &out, "getOutputAmount", token1Address, amount)
	if err != nil || len(out) == 0 {
		return ArbitrageParams{}, fmt.Errorf("error getting DEX1 output: %v", err)
	}
	dex1Output = *out[0].(*big.Int)

	out = nil
	err = dex2Contract.Call(nil, &out, "getOutputAmount", token1Address, amount)
	if err != nil || len(out) == 0 {
		return ArbitrageParams{}, fmt.Errorf("error getting DEX2 output: %v", err)
	}
	dex2Output = *out[0].(*big.Int)

	// Determine which DEX to buy from based on prices
	buyFromDex1 := dex1Output.Cmp(&dex2Output) > 0

	return ArbitrageParams{
		Amount:      amount,
		BuyFromDex1: buyFromDex1,
	}, nil
}

// GetParametersAsJSON returns the arbitrage parameters as a JSON string
func GetParametersAsJSON() (string, error) {
	params, err := GetArbitrageParameters()
	if err != nil {
		return "", err
	}

	// Create result object with parameters
	resultPayload := map[string]interface{}{
		"amount":      params.Amount.String(),
		"buyFromDex1": params.BuyFromDex1,
	}

	// Convert to JSON
	jsonValue, err := json.Marshal(resultPayload)
	if err != nil {
		return "", fmt.Errorf("error marshaling JSON: %v", err)
	}

	return string(jsonValue), nil
}

func main() {
	// Get parameters as JSON
	jsonParams, err := GetParametersAsJSON()
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	fmt.Println("Payload received:", jsonParams)
}
