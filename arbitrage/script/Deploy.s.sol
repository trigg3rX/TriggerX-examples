// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Arbitrage.sol";
import "../src/LiquidityToken1.sol";
import "../src/LiquidityToken2.sol";

contract DeployArbitrage is Script {
    // Static token addresses
    address constant TOKEN1_ADDRESS =
        0x0f1D6c76774926Bf4C4f5a8629066AF006e1B570;
    address constant TOKEN2_ADDRESS =
        0xe1A327AE69156ee7b5cE59A057b823c760438535;
    address constant DEX1_ADDRESS = 0xD05E72F6C74Be61d74Cb7e003f6E869C287606b0;
    address constant DEX2_ADDRESS = 0x02F957CF974797CF2CdeBd43994232A38802581c;

    function run() external {
        // Get private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Use existing DEX addresses
        address dex1Address = DEX1_ADDRESS;
        address dex2Address = DEX2_ADDRESS;

        // Deploy Arbitrage contract
        Arbitrage arbitrage = new Arbitrage(
            dex1Address,
            dex2Address,
            msg.sender // Set deployer as owner
        );

        // Mint and transfer tokens to arbitrage contract
        LiquidityToken1 token1 = LiquidityToken1(TOKEN1_ADDRESS);
        LiquidityToken2 token2 = LiquidityToken2(TOKEN2_ADDRESS);

        // Mint 100 tokens of each type
        uint256 amount = 100 * 10 ** 18; // 100 tokens with 18 decimals
        token1.mint(address(arbitrage), amount);
        token2.mint(address(arbitrage), amount);

        vm.stopBroadcast();

        // Log the deployed address and token transfers
        console.log("Arbitrage contract deployed at:", address(arbitrage));
        console.log("Transferred 100 Token1 to arbitrage contract");
        console.log("Transferred 100 Token2 to arbitrage contract");
    }
}
