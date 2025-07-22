// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.28;


contract ERC20 {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;

    mapping (address=>uint256) balances;
    mapping (address=>mapping(address=>uint256)) allowances;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply;
    }

    function balanceOf(address account) public view returns (uint256 balance) {
        balance = balances[account];
    }

    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance!");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(balances[msg.sender]<=amount, "Insufficient balance");
        allowances[msg.sender][spender] = amount;
        
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowances[from][msg.sender]>=amount, "Youre not allowed to spend that much");
        allowances[from][msg.sender] -= amount;
        balances[from] -= amount;
        balances[to] += amount;

        return true;
    }
}