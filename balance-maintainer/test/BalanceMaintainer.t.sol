// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import "../src/BalanceMaintainer.sol";

// contract BalanceMaintainerTest is Test {
//     BalanceMaintainer balanceMaintainer;
//     address owner = address(this);
//     address user1 = address(0x1);
//     address user2 = address(0x2);

//     function setUp() public {
//         // Deploy contract with 10 ETH
//         balanceMaintainer = new BalanceMaintainer{value: 10 ether}();
//     }

//     function testSetAddressWithBalance() public {
//         address[] memory addresses = new address[](1);
//         uint256[] memory balances = new uint256[](1);
//         addresses[0] = user1;
//         balances[0] = 1 ether;

//         balanceMaintainer.setMultipleAddressesWithBalance(addresses, balances);
//         assertEq(balanceMaintainer.minimumBalances(user1), 1 ether);
//         assertEq(balanceMaintainer.getTrackedAddressesCount(), 1);
//     }

//     function testMaintainBalances() public {
//         address[] memory addresses = new address[](1);
//         uint256[] memory balances = new uint256[](1);
//         addresses[0] = user1;
//         balances[0] = 1 ether;
//         // Set minimum balance
//         balanceMaintainer.setMultipleAddressesWithBalance(addresses, balances);

//         skip(3600);

//         // Deal some ETH to user1 (less than minimum)
//         vm.deal(user1, 0.5 ether);

//         // Call maintainBalances
//         balanceMaintainer.maintainBalances();

//         // Check if user1 balance is topped up to 1 ETH
//         assertEq(user1.balance, 1 ether);
//         assertEq(balanceMaintainer.getContractBalance(), 9.5 ether);
//     }

//     function testCooldown() public {
//         address[] memory addresses = new address[](1);
//         uint256[] memory balances = new uint256[](1);
//         addresses[0] = user1;
//         balances[0] = 1 ether;

//         balanceMaintainer.setMultipleAddressesWithBalance(addresses, balances);
//         vm.deal(user1, 0.5 ether);
//         skip(3600);

//         // First call should succeed
//         balanceMaintainer.maintainBalances();

//         // Second call should fail due to cooldown
//         vm.expectRevert("Cooldown period active");
//         balanceMaintainer.maintainBalances();

//         // Warp time forward by 1 hour
//         vm.warp(block.timestamp + 1 hours);

//         // // Should succeed again
//         vm.deal(user1, 0.5 ether);
//         balanceMaintainer.maintainBalances();
//         assertEq(user1.balance, 1 ether);
//     }

//     function testOnlyOwner() public {
//         // Try setting balance from non-owner
//         address[] memory addresses = new address[](1);
//         uint256[] memory balances = new uint256[](1);
//         addresses[0] = user2;
//         balances[0] = 1 ether;
//         vm.prank(user2);
//         vm.expectRevert("Only owner can call this function");
//         balanceMaintainer.setMultipleAddressesWithBalance(addresses, balances);
//     }

//     function testReceiveEth() public {
//         // Send 1 ETH to contract
//         (bool success, ) = address(balanceMaintainer).call{value: 1 ether}("");
//         assertTrue(success);
//         assertEq(balanceMaintainer.getContractBalance(), 11 ether);
//     }
// }
