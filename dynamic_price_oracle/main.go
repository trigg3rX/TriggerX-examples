package main

import (
	"context"
	"encoding/json"
	"fmt"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/trigg3rX/triggerx-backend/execute/manager"
)

// DynamicPriceOracleChecker manages oracle updates
type DynamicPriceOracleChecker struct {
	OracleAddress common.Address
	Client        *ethclient.Client
	ABI           abi.ABI
}

// PriceUpdateParams mirrors the struct in the smart contract
type PriceUpdateParams struct {
	TradingPairs  []string   `json:"tradingPairs"`
	Thresholds    []*big.Int `json:"thresholds"`
	Confirmations *big.Int   `json:"confirmations"`
	MaxAge        *big.Int   `json:"maxAge"`
}

// NewDynamicPriceOracleChecker creates a new instance
func NewDynamicPriceOracleChecker(oracleAddress string, rpcURL string) (*DynamicPriceOracleChecker, error) {
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to Ethereum client: %v", err)
	}

	// Define the contract ABI (minimal version needed for our calls)
	contractABI, err := abi.JSON(strings.NewReader(`[
		{
			"inputs": [],
			"name": "prepareUpdateParams",
			"outputs": [
				{
					"components": [
						{
							"internalType": "string[]",
							"name": "tradingPairs",
							"type": "string[]"
						},
						{
							"internalType": "uint256[]",
							"name": "thresholds",
							"type": "uint256[]"
						},
						{
							"internalType": "uint256",
							"name": "confirmations",
							"type": "uint256"
						},
						{
							"internalType": "uint256",
							"name": "maxAge",
							"type": "uint256"
						}
					],
					"internalType": "struct DynamicPriceOracle.PriceUpdateParams",
					"name": "",
					"type": "tuple"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"components": [
						{
							"internalType": "string[]",
							"name": "tradingPairs",
							"type": "string[]"
						},
						{
							"internalType": "uint256[]",
							"name": "thresholds",
							"type": "uint256[]"
						},
						{
							"internalType": "uint256",
							"name": "confirmations",
							"type": "uint256"
						},
						{
							"internalType": "uint256",
							"name": "maxAge",
							"type": "uint256"
						}
					],
					"internalType": "struct DynamicPriceOracle.PriceUpdateParams",
					"name": "params",
					"type": "tuple"
				}
			],
			"name": "updatePrices",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		}
	]`))
	if err != nil {
		return nil, fmt.Errorf("failed to parse contract ABI: %v", err)
	}

	return &DynamicPriceOracleChecker{
		OracleAddress: common.HexToAddress(oracleAddress),
		Client:        client,
		ABI:           contractABI,
	}, nil
}

func main() {
	// Configuration
	oracleAddress := "YOUR_ORACLE_CONTRACT_ADDRESS"
	rpcURL := "YOUR_ETHEREUM_RPC_URL"

	// Create a new checker
	checker, err := NewDynamicPriceOracleChecker(oracleAddress, rpcURL)
	if err != nil {
		fmt.Printf(`{"success": false, "error": "%v"}`, err)
		return
	}

	// Create a job for testing
	job := &manager.Job{
		JobID:        "price_oracle_update",
		TimeInterval: 600, // 10 minutes in seconds
		LastExecuted: time.Now().Add(-10 * time.Minute),
		CreatedAt:    time.Now().Add(-time.Hour),
	}

	// Run the checker
	success, payload := checker.Checker(job, nil)

	// Structure the output
	output := struct {
		Success bool                   `json:"success"`
		Payload map[string]interface{} `json:"payload"`
	}{
		Success: success,
		Payload: payload,
	}

	// Convert to JSON and write to stdout
	jsonData, err := json.Marshal(output)
	if err != nil {
		errorOutput := struct {
			Success bool   `json:"success"`
			Error   string `json:"error"`
		}{
			Success: false,
			Error:   err.Error(),
		}
		jsonData, _ = json.Marshal(errorOutput)
	}

	fmt.Print(string(jsonData))
}

// Checker validates job execution and prepares update parameters
func (dpoc *DynamicPriceOracleChecker) Checker(job *manager.Job, customLogic interface{}) (bool, map[string]interface{}) {
	payload := make(map[string]interface{})

	// Validate interval
	if !dpoc.ValidateJobInterval(job) {
		payload["error"] = "job interval validation failed"
		return false, payload
	}

	// Validate time frame
	if isValid, msg := dpoc.ValidateJobTimeFrame(job); !isValid {
		payload["error"] = msg
		return false, payload
	}

	// Get update parameters from the contract
	params, err := dpoc.getPriceUpdateParams()
	if err != nil {
		payload["error"] = fmt.Sprintf("failed to get price update params: %v", err)
		return false, payload
	}

	// Prepare the transaction data
	txData, err := dpoc.prepareUpdatePricesTxData(params)
	if err != nil {
		payload["error"] = fmt.Sprintf("failed to prepare transaction data: %v", err)
		return false, payload
	}

	// Add transaction data to payload
	payload["to"] = dpoc.OracleAddress.Hex()
	payload["data"] = txData
	payload["value"] = "0"
	payload["params"] = params

	return true, payload
}

// ValidateJobInterval checks if enough time has passed since last execution
func (dpoc *DynamicPriceOracleChecker) ValidateJobInterval(job *manager.Job) bool {
	if job.LastExecuted.IsZero() {
		return true
	}

	elapsed := time.Since(job.LastExecuted)
	return elapsed.Seconds() >= float64(job.TimeInterval)
}

// ValidateJobTimeFrame checks if the job is still within its allowed time frame
func (dpoc *DynamicPriceOracleChecker) ValidateJobTimeFrame(job *manager.Job) (bool, string) {
	if job.TimeFrame <= 0 {
		return true, ""
	}

	age := time.Since(job.CreatedAt)
	if age.Seconds() > float64(job.TimeFrame) {
		return false, fmt.Sprintf("job expired: age %v exceeds time frame %d seconds", age.Round(time.Second), job.TimeFrame)
	}

	return true, ""
}

// getPriceUpdateParams calls the contract's prepareUpdateParams function
func (dpoc *DynamicPriceOracleChecker) getPriceUpdateParams() (*PriceUpdateParams, error) {
	// Prepare the call data for prepareUpdateParams
	callData, err := dpoc.ABI.Pack("prepareUpdateParams")
	if err != nil {
		return nil, fmt.Errorf("failed to pack prepareUpdateParams call: %v", err)
	}

	// Make the call
	ctx := context.Background()
	result, err := dpoc.Client.CallContract(ctx, ethereum.CallMsg{
		To:   &dpoc.OracleAddress,
		Data: callData,
	}, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to call prepareUpdateParams: %v", err)
	}

	// Unpack the result
	var params PriceUpdateParams
	err = dpoc.ABI.UnpackIntoInterface(&params, "prepareUpdateParams", result)
	if err != nil {
		return nil, fmt.Errorf("failed to unpack prepareUpdateParams result: %v", err)
	}

	return &params, nil
}

// prepareUpdatePricesTxData prepares the transaction data for updatePrices
func (dpoc *DynamicPriceOracleChecker) prepareUpdatePricesTxData(params *PriceUpdateParams) (string, error) {
	// Pack the parameters for updatePrices
	callData, err := dpoc.ABI.Pack("updatePrices", params)
	if err != nil {
		return "", fmt.Errorf("failed to pack updatePrices call: %v", err)
	}

	return fmt.Sprintf("0x%x", callData), nil
}
