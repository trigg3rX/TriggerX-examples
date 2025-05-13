// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract DEX2 is Ownable {
    IERC20 public immutable liquidityToken1;
    IERC20 public immutable liquidityToken2;

    event Swap(
        address indexed user,
        address indexed tokenIn,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(
        address _liquidityToken1,
        address _liquidityToken2,
        address initialOwner
    ) Ownable(initialOwner) {
        liquidityToken1 = IERC20(_liquidityToken1);
        liquidityToken2 = IERC20(_liquidityToken2);
    }

    // Get current price of token2 in terms of token1 (token2/token1)
    function getCurrentPrice() public view returns (uint256) {
        uint256 balance1 = liquidityToken1.balanceOf(address(this));
        uint256 balance2 = liquidityToken2.balanceOf(address(this));
        require(balance1 > 0 && balance2 > 0, "Insufficient liquidity");
        return (balance2 * 1e18) / balance1;
    }

    // Swap tokens (specify input token and amount)
    function swap(address _tokenIn, uint256 _amountIn) external {
        require(_amountIn > 0, "Amount must be positive");
        require(
            _tokenIn == address(liquidityToken1) ||
                _tokenIn == address(liquidityToken2),
            "Invalid token"
        );

        (IERC20 tokenIn, IERC20 tokenOut) = _tokenIn == address(liquidityToken1)
            ? (liquidityToken1, liquidityToken2)
            : (liquidityToken2, liquidityToken1);

        uint256 balanceIn = tokenIn.balanceOf(address(this));
        uint256 balanceOut = tokenOut.balanceOf(address(this));
        require(balanceIn > 0 && balanceOut > 0, "Insufficient liquidity");

        // Calculate amount out using constant product formula: (x + Δx)(y - Δy) = xy
        uint256 amountOut;
        unchecked {
            amountOut = (balanceOut * _amountIn) / (balanceIn + _amountIn);
        }
        require(amountOut > 0, "Amount must be positive");

        require(
            tokenIn.transferFrom(msg.sender, address(this), _amountIn),
            "Input transfer failed"
        );
        require(
            tokenOut.transfer(msg.sender, amountOut),
            "Output transfer failed"
        );

        emit Swap(msg.sender, _tokenIn, _amountIn, amountOut);
    }

    // Withdraw tokens from contract (for owner)
    function withdrawTokens(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        require(_amount > 0, "Amount must be positive");
        require(
            IERC20(_token).transfer(msg.sender, _amount),
            "Withdrawal failed"
        );
    }

    // Get amount of output token for a given input token and amount
    function getOutputAmount(
        address _tokenIn,
        uint256 _amountIn
    ) external view returns (uint256) {
        require(_amountIn > 0, "Amount must be positive");
        require(
            _tokenIn == address(liquidityToken1) ||
                _tokenIn == address(liquidityToken2),
            "Invalid token"
        );

        (IERC20 tokenIn, IERC20 tokenOut) = _tokenIn == address(liquidityToken1)
            ? (liquidityToken1, liquidityToken2)
            : (liquidityToken2, liquidityToken1);

        uint256 balanceIn = tokenIn.balanceOf(address(this));
        uint256 balanceOut = tokenOut.balanceOf(address(this));
        require(balanceIn > 0 && balanceOut > 0, "Insufficient liquidity");

        uint256 k = balanceIn * balanceOut;
        uint256 newBalanceIn = balanceIn + _amountIn;
        uint256 newBalanceOut = k / newBalanceIn;
        return balanceOut - newBalanceOut;
    }
}
