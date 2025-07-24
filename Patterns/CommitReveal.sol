// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/*
    Commit-Reveal Pattern
*/

contract CommitReveal {
    struct Commit {
        bytes32 hash;
        bool revealed;
    }

    mapping(address => Commit) public commits;
    uint public commitDeadline;
    uint public revealDeadline;
    address public owner;

    event Committed(address indexed user, bytes32 commitHash);
    event Revealed(address indexed user, string choice, string salt);

    modifier onlyBefore(uint time) {
        require(block.timestamp < time, "Deadline passed");
        _;
    }

    modifier onlyAfter(uint time) {
        require(block.timestamp >= time, "Too early");
        _;
    }

    constructor(uint _commitDuration, uint _revealDuration) {
        owner = msg.sender;
        commitDeadline = block.timestamp + _commitDuration;
        revealDeadline = commitDeadline + _revealDuration;
    }

    function commit(bytes32 _hash) external onlyBefore(commitDeadline) {
        require(commits[msg.sender].hash == 0, "Already committed");
        commits[msg.sender] = Commit({hash: _hash, revealed: false});
        emit Committed(msg.sender, _hash);
    }

    function reveal(string calldata _choice, string calldata _salt)
        external
        onlyAfter(commitDeadline)
        onlyBefore(revealDeadline)
    {
        Commit storage userCommit = commits[msg.sender];
        require(userCommit.hash != 0, "No commit found");
        require(!userCommit.revealed, "Already revealed");

        bytes32 computedHash = keccak256(abi.encode(_choice, _salt));
        require(computedHash == userCommit.hash, "Invalid reveal");

        userCommit.revealed = true;
        emit Revealed(msg.sender, _choice, _salt);
    }

    function hasCommitted(address user) external view returns (bool) {
        return commits[user].hash != 0;
    }

    function hasRevealed(address user) external view returns (bool) {
        return commits[user].revealed;
    }
}
