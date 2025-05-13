// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Arbitrage.sol";
import "../src/DEX1.sol";
import "../src/DEX2.sol";
import "../src/LiquidityToken1.sol";
import "../src/LiquidityToken2.sol";

contract ArbitrageSystemTest is Test {
    // Contracts
    LiquidityToken1 public token1;
    LiquidityToken2 public token2;
    DEX1 public dex1;
    DEX2 public dex2;
    Arbitrage public arbitrage;

    // Test addresses
    address public owner;
    address public user;
    address public liquidityProvider;

    // Test amounts
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    uint256 public constant LIQUIDITY_AMOUNT = 100_000 * 10**18;
    uint256 public constant ARBITRAGE_AMOUNT = 1_000 * 10**18;

    function setUp() public {
        // Setup test addresses
        owner = makeAddr("owner");
        user = makeAddr("user");
        liquidityProvider = makeAddr("liquidityProvider");

        // Deploy tokens
        vm.startPrank(owner);
        token1 = new LiquidityToken1("Liquidity Token 1", "LT1", INITIAL_SUPPLY);
        token2 = new LiquidityToken2("Liquidity Token 2", "LT2", INITIAL_SUPPLY);
        vm.stopPrank();

        // Deploy DEXes
        vm.startPrank(owner);
        dex1 = new DEX1(address(token1), address(token2), owner);
        dex2 = new DEX2(address(token1), address(token2), owner);
        vm.stopPrank();

        // Deploy Arbitrage contract
        vm.startPrank(owner);
        arbitrage = new Arbitrage(address(dex1), address(dex2), owner);
        vm.stopPrank();

        // Setup initial liquidity
        vm.startPrank(owner);
        // Add liquidity to DEX1
        token1.transfer(address(dex1), LIQUIDITY_AMOUNT);
        token2.transfer(address(dex1), LIQUIDITY_AMOUNT);

        // Add liquidity to DEX2 with different ratio to create arbitrage opportunity
        token1.transfer(address(dex2), LIQUIDITY_AMOUNT);
        token2.transfer(address(dex2), LIQUIDITY_AMOUNT * 90 / 100); // 10% price difference for better arbitrage opportunity

        // Transfer tokens to arbitrage contract for testing
        token1.transfer(address(arbitrage), ARBITRAGE_AMOUNT);
        vm.stopPrank();
    }

    function test_InitialSetup() public view {
        // Check token balances
        assertEq(token1.balanceOf(address(dex1)), LIQUIDITY_AMOUNT);
        assertEq(token2.balanceOf(address(dex1)), LIQUIDITY_AMOUNT);
        assertEq(token1.balanceOf(address(dex2)), LIQUIDITY_AMOUNT);
        assertEq(token2.balanceOf(address(dex2)), LIQUIDITY_AMOUNT * 90 / 100);
        assertEq(token1.balanceOf(address(arbitrage)), ARBITRAGE_AMOUNT);

        // Check DEX prices
        uint256 dex1Price = dex1.getCurrentPrice();
        uint256 dex2Price = dex2.getCurrentPrice();
        assertTrue(dex1Price != dex2Price, "Prices should be different");
    }

    function test_ExecuteArbitrage_BuyFromDex1() public {
        vm.startPrank(owner);
        
        // Get initial balances
        uint256 initialToken1Balance = token1.balanceOf(address(arbitrage));
        
        // Execute arbitrage
        arbitrage.executeArbitrage(ARBITRAGE_AMOUNT, true);
        
        // Check final balance
        uint256 finalToken1Balance = token1.balanceOf(address(arbitrage));
        assertTrue(finalToken1Balance > initialToken1Balance, "Should have made profit");
        
        vm.stopPrank();
    }


    function test_ExecuteArbitrage_OnlyOwner() public {
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        arbitrage.executeArbitrage(ARBITRAGE_AMOUNT, true);
        vm.stopPrank();
    }

    function test_ExecuteArbitrage_InsufficientBalance() public {
        vm.startPrank(owner);
        vm.expectRevert("Insufficient token1 balance");
        arbitrage.executeArbitrage(ARBITRAGE_AMOUNT * 2, true);
        vm.stopPrank();
    }

    function test_WithdrawTokens() public {
        vm.startPrank(owner);
        
        // Get initial balance
        uint256 initialBalance = token1.balanceOf(owner);
        
        // Withdraw tokens
        uint256 withdrawAmount = ARBITRAGE_AMOUNT / 2;
        arbitrage.withdrawTokens(address(token1), withdrawAmount);
        
        // Check final balance
        uint256 finalBalance = token1.balanceOf(owner);
        assertEq(finalBalance, initialBalance + withdrawAmount);
        
        vm.stopPrank();
    }

    function test_WithdrawTokens_OnlyOwner() public {
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        arbitrage.withdrawTokens(address(token1), ARBITRAGE_AMOUNT);
        vm.stopPrank();
    }

    function test_WithdrawTokens_InsufficientBalance() public {
        vm.startPrank(owner);
        vm.expectRevert("Insufficient balance");
        arbitrage.withdrawTokens(address(token1), ARBITRAGE_AMOUNT * 2);
        vm.stopPrank();
    }

    function test_DEX_Swap() public {
        vm.startPrank(owner);
        
        // Approve tokens
        token1.approve(address(dex1), ARBITRAGE_AMOUNT);
        
        // Get initial balances
        uint256 initialToken1Balance = token1.balanceOf(owner);
        uint256 initialToken2Balance = token2.balanceOf(owner);
        
        // Execute swap
        dex1.swap(address(token1), ARBITRAGE_AMOUNT);
        
        // Check balances
        uint256 finalToken1Balance = token1.balanceOf(owner);
        uint256 finalToken2Balance = token2.balanceOf(owner);
        
        assertEq(finalToken1Balance, initialToken1Balance - ARBITRAGE_AMOUNT);
        assertTrue(finalToken2Balance > initialToken2Balance);
        
        vm.stopPrank();
    }

    function test_DEX_GetCurrentPrice() public view {
        uint256 dex1Price = dex1.getCurrentPrice();
        uint256 dex2Price = dex2.getCurrentPrice();
        
        assertTrue(dex1Price > 0);
        assertTrue(dex2Price > 0);
        assertTrue(dex1Price != dex2Price);
    }

    function test_DEX_GetOutputAmount() public view {
        uint256 amountOut = dex1.getOutputAmount(address(token1), ARBITRAGE_AMOUNT);
        assertTrue(amountOut > 0);
    }
} 