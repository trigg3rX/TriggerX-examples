// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

interface IDEX {
    function getCurrentPrice() external view returns (uint256);
    function swap(address _tokenIn, uint256 _amountIn) external;
    function getOutputAmount(
        address _tokenIn,
        uint256 _amountIn
    ) external view returns (uint256);
    function liquidityToken1() external view returns (IERC20);
    function liquidityToken2() external view returns (IERC20);
}

contract Arbitrage is Ownable {
    IDEX public dex1;
    IDEX public dex2;
    IERC20 public token1;
    IERC20 public token2;

    event ArbitrageExecuted(
        uint256 profit,
        uint256 dex1Price,
        uint256 dex2Price
    );

    constructor(
        address _dex1,
        address _dex2,
        address initialOwner
    ) Ownable(initialOwner) {
        dex1 = IDEX(_dex1);
        dex2 = IDEX(_dex2);
        token1 = dex1.liquidityToken1();
        token2 = dex1.liquidityToken2();

        // Verify both DEXes use the same token pair
        require(
            address(token1) == address(dex2.liquidityToken1()) &&
                address(token2) == address(dex2.liquidityToken2()),
            "DEXes must use the same token pair"
        );
    }

    // Execute arbitrage
    function executeArbitrage(uint256 amount, bool buyFromDex1) external {
        require(
            token1.balanceOf(address(this)) >= amount,
            "Insufficient token1 balance"
        );
        require(
            amount <= 100 * 10 ** 18,
            "Swap amount cannot exceed 100 tokens"
        );

        uint256 initialToken1Balance = token1.balanceOf(address(this));

        // Approve tokens for DEXes
        token1.approve(address(dex1), amount);
        token1.approve(address(dex2), amount);

        if (buyFromDex1) {
            // Buy token2 from DEX1
            dex1.swap(address(token1), amount);

            // Verify we received the expected amount of token2
            uint256 actualToken2Amount = token2.balanceOf(address(this));
            require(actualToken2Amount > 0, "Failed to receive token2");

            token2.approve(address(dex2), actualToken2Amount);

            // Sell token2 on DEX2
            dex2.swap(address(token2), actualToken2Amount);
        } else {
            // Buy token2 from DEX2
            dex2.swap(address(token1), amount);

            // Verify we received the expected amount of token2
            uint256 actualToken2Amount = token2.balanceOf(address(this));
            require(actualToken2Amount > 0, "Failed to receive token2");

            token2.approve(address(dex1), actualToken2Amount);

            // Sell token2 on DEX1
            dex1.swap(address(token2), actualToken2Amount);
        }

        // Calculate actual profit
        uint256 finalToken1Balance = token1.balanceOf(address(this));
        require(
            finalToken1Balance > initialToken1Balance,
            "Arbitrage did not generate profit"
        );
        uint256 actualProfit = finalToken1Balance - initialToken1Balance;

        emit ArbitrageExecuted(
            actualProfit,
            dex1.getCurrentPrice(),
            dex2.getCurrentPrice()
        );
    }

    // Withdraw tokens from contract (for owner)
    function withdrawTokens(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "Insufficient balance");
        require(token.transfer(msg.sender, _amount), "Token withdrawal failed");
    }

    // Function to receive ETH (if needed)
    receive() external payable {}
}
