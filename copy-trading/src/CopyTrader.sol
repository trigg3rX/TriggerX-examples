// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMockDEX {
    function buyTokens(uint256 tokenAmount) external payable;
    function sellTokens(uint256 tokenAmount) external;
}

contract CopyTrader is Ownable {
    IERC20 public whaleToken;     // The WHALE TOKEN being tracked
    address public whaleWallet;   // The wallet to monitor
    IMockDEX public dex;          // The MockDEX contract
    address public keeper;        // The keeper address that can execute trades

    event KeeperUpdated(address indexed oldKeeper, address indexed newKeeper);
    event TradeExecuted(bool isBuy, uint256 amount);

    modifier onlyKeeperOrOwner() {
        require(msg.sender == keeper || msg.sender == owner(), "Not authorized");
        _;
    }

    constructor(
        address _whaleToken,
        address _whaleWallet,
        address _dex,
        address _keeper
    ) Ownable(msg.sender) { 
        whaleToken = IERC20(_whaleToken);
        whaleWallet = _whaleWallet;
        dex = IMockDEX(_dex);
        keeper = _keeper;
        // Approve DEX to spend tokens
        whaleToken.approve(_dex, type(uint256).max);
    }

    // Update keeper address
    function setKeeper(address _newKeeper) external onlyOwner {
        require(_newKeeper != address(0), "Invalid keeper address");
        address oldKeeper = keeper;
        keeper = _newKeeper;
        emit KeeperUpdated(oldKeeper, _newKeeper);
    }

    // Execute trade function - handles both buy and sell
    function execute(bool isBuy, uint256 amount) external onlyKeeperOrOwner {
        if (isBuy) {
            uint256 ethBalance = address(this).balance;
            require(ethBalance > 0, "Insufficient ETH balance");
            dex.buyTokens{value: ethBalance}(amount);
        } else {
            require(whaleToken.balanceOf(address(this)) >= amount, "Insufficient token balance");
            dex.sellTokens(amount);
        }
        emit TradeExecuted(isBuy, amount);
    }

    // Allow owner to deposit ETH for buying tokens
    function depositETH() external payable onlyOwner {}

    // Allow owner to withdraw ETH
    function withdrawETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient ETH balance");
        payable(msg.sender).transfer(amount);
    }

    // Allow owner to withdraw tokens
    function withdrawTokens(uint256 amount) external onlyOwner {
        require(whaleToken.balanceOf(address(this)) >= amount, "Insufficient token balance");
        whaleToken.transfer(msg.sender, amount);
    }

    // Fallback to receive ETH from DEX
    receive() external payable {}
}