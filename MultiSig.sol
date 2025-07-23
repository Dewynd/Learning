// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/*
    MultiSig Wallet
*/

contract MultiSigWallet {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    struct Transaction {
        address target;
        uint value;
        bytes data;
        bool executed;
        uint confirmations;
    }

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public confirmed;

    event Submit(uint indexed txId, address indexed owner, address indexed target, uint value);
    event Confirm(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "Transaction doe`t exist");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }

    modifier notConfirmed(uint _txId) {
        require(!confirmed[_txId][msg.sender], "Already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid required number of confirmations");

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not uniq");
            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    function submitTransaction(address _target, uint _value, bytes memory _data) external onlyOwner {
        transactions.push(Transaction({
            target: _target,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 0
        }));

        uint txId = transactions.length - 1;
        emit Submit(txId, msg.sender, _target, _value);
    }

    function confirmTransaction(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) notConfirmed(_txId) {
        confirmed[_txId][msg.sender] = true;
        transactions[_txId].confirmations += 1;
        emit Confirm(msg.sender, _txId);
    }

    function revokeConfirmation(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(confirmed[_txId][msg.sender], "Transaction not confirmed");
        confirmed[_txId][msg.sender] = false;
        transactions[_txId].confirmations -= 1;
        emit Revoke(msg.sender, _txId);
    }

    function executeTransaction(uint _txId) external txExists(_txId) notExecuted(_txId) {
        Transaction storage transaction = transactions[_txId];
        require(transaction.confirmations >= required, "Not enough confirmations");

        transaction.executed = true;

        (bool success, ) = transaction.target.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");
        emit Execute(_txId);
    }

    receive() external payable {}
}
