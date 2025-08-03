// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VoteERC20 {
    string public name = "Vote ERC20 Token";
    string public symbol = "VERC";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    struct Proposal {
        uint256 id;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public proposalCount;

    address public owner;

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event ProposalCreated(uint256 id, string description, uint256 deadline);
    event Voted(uint256 id, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 id, bool success);

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function createProposal(string memory _description, uint256 _duration) public {
        require(balanceOf[msg.sender] > 0);
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + _duration,
            executed: false
        });
        emit ProposalCreated(proposalCount, _description, block.timestamp + _duration);
    }

    function vote(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.deadline);
        require(balanceOf[msg.sender] > 0);
        require(!hasVoted[_proposalId][msg.sender]);
        hasVoted[_proposalId][msg.sender] = true;
        uint256 weight = balanceOf[msg.sender];
        if (_support) {
            proposal.votesFor += weight;
        } else {
            proposal.votesAgainst += weight;
        }
        emit Voted(_proposalId, msg.sender, _support, weight);
    }

    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.deadline);
        require(!proposal.executed);
        proposal.executed = true;
        bool success = proposal.votesFor > proposal.votesAgainst;
        emit ProposalExecuted(_proposalId, success);
    }
}
