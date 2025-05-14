// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockDEX is Ownable {
    IERC20 public whaleToken; // The WHALE TOKEN contract
    uint256 public price;     // Price in ETH per WHALE TOKEN, scaled by 1e18 (e.g., 0.001 ETH = 1e15)

    constructor(address _whaleToken) Ownable(msg.sender) {
        whaleToken = IERC20(_whaleToken);
        price = 1e15; // Initial price: 1 WHALE TOKEN = 0.001 ETH
    }

    // Set the price (only owner)
    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    // Buy WHALE TOKENs with ETH
    function buyTokens(uint256 tokenAmount) external payable {
        uint256 ethRequired = (tokenAmount * price) / 1e18;
        require(msg.value >= ethRequired, "Insufficient ETH sent");
        require(whaleToken.balanceOf(address(this)) >= tokenAmount, "Insufficient token balance in DEX");
        
        // Transfer tokens to buyer
        whaleToken.transfer(msg.sender, tokenAmount);
        
        // Refund excess ETH if any
        if (msg.value > ethRequired) {
            payable(msg.sender).transfer(msg.value - ethRequired);
        }
    }

    // Sell WHALE TOKENs for ETH
    function sellTokens(uint256 tokenAmount) external {
        uint256 ethToSend = (tokenAmount * price) / 1e18;
        require(address(this).balance >= ethToSend, "Insufficient ETH balance in DEX");
        require(whaleToken.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        
        // Transfer ETH to seller
        payable(msg.sender).transfer(ethToSend);
    }

    // Allow owner to deposit tokens into the DEX
    function depositTokens(uint256 amount) external onlyOwner {
        require(whaleToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
    }

    // Allow owner to withdraw tokens
    function withdrawTokens(uint256 amount) external onlyOwner {
        whaleToken.transfer(msg.sender, amount);
    }

    // Allow owner to withdraw ETH
    function withdrawETH(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    // Fallback to receive ETH
    receive() external payable {}
}