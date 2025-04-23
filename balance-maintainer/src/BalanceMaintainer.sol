// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BalanceMaintainer {
    address public owner;
    mapping(address => uint256) public minimumBalances;
    address[] public trackedAddresses;
    mapping(address => bool) private isTracked;
    uint256 public lastMaintenance;
    uint256 public constant COOLDOWN = 1 hours;

    event BalanceToppedUp(address indexed recipient, uint256 amount);
    event MinimumBalanceSet(address indexed target, uint256 amount);

    constructor(address _owner) payable {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function setMultipleAddressesWithBalance(
        address[] calldata _targets,
        uint256[] calldata _minimumBalances
    ) external onlyOwner {
        require(
            _targets.length == _minimumBalances.length,
            "Arrays length mismatch"
        );
        require(_targets.length > 0, "Empty arrays not allowed");

        for (uint256 i = 0; i < _targets.length; i++) {
            require(_targets[i] != address(0), "Invalid address");

            if (!isTracked[_targets[i]]) {
                trackedAddresses.push(_targets[i]);
                isTracked[_targets[i]] = true;
            }
            minimumBalances[_targets[i]] = _minimumBalances[i];
            emit MinimumBalanceSet(_targets[i], _minimumBalances[i]);
        }
    }

    function maintainBalances() external {
        require(
            block.timestamp >= lastMaintenance + COOLDOWN,
            "Cooldown period active"
        );
        lastMaintenance = block.timestamp;
        for (uint256 i = 0; i < trackedAddresses.length; i++) {
            address target = trackedAddresses[i];
            uint256 minBalance = minimumBalances[target];
            if (minBalance == 0) continue;
            uint256 currentBalance = target.balance;
            if (currentBalance < minBalance) {
                uint256 amountNeeded = minBalance - currentBalance;
                require(
                    address(this).balance >= amountNeeded,
                    "Insufficient contract balance"
                );
                (bool success, ) = target.call{value: amountNeeded}("");
                require(success, "Transfer failed");
                emit BalanceToppedUp(target, amountNeeded);
            }
        }
    }

    function getTrackedAddressesCount() external view returns (uint256) {
        return trackedAddresses.length;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // New function to get all tracked addresses and their minimum balances
    function getAllTrackedAddressesWithBalances() external view returns (
        address[] memory addresses,
        uint256[] memory balances
    ) {
        uint256 length = trackedAddresses.length;
        addresses = new address[](length);
        balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            addresses[i] = trackedAddresses[i];
            balances[i] = minimumBalances[trackedAddresses[i]];
        }

        return (addresses, balances);
    }

    receive() external payable {}

    fallback() external payable {}
}
