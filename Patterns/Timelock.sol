// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TimeLock {
    address public owner;
    uint public constant MIN_DELAY = 2 days;
    uint public constant MAX_DELAY = 30 days;
    uint public constant GRACE_PERIOD = 14 days;

    mapping(bytes32 => bool) public queuedTransactions;

    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, uint eta);
    event CancelTransaction(bytes32 indexed txHash, address indexed target);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) external onlyOwner {
        require(eta >= block.timestamp + MIN_DELAY && eta <= block.timestamp + MAX_DELAY, "Invalid eta");
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;
        emit QueueTransaction(txHash, target, value, signature, eta);
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) external onlyOwner {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;
        emit CancelTransaction(txHash, target);
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) external payable returns (bytes memory) {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Transaction not queued");
        require(block.timestamp >= eta, "Too early");
        require(block.timestamp <= eta + GRACE_PERIOD, "Transaction is invalidated");

        queuedTransactions[txHash] = false;

        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Transaction execution reverted");

        emit ExecuteTransaction(txHash, target, value);
        return returnData;
    }
}
