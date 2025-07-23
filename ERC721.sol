// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.28;

library ArrayPlus {
    function removeByValue(uint[] storage array,  uint value) internal {
        for (uint i = 0; i<array.length; i++) {
            if (array[i] == value) {
                array[i] = array[array.length-1];
                array.pop();
                break;
            }
        }
    }
}

contract ERC721 {
    using ArrayPlus for uint[];
    address owner;
    mapping (uint=>address) tokens;
    mapping (address=>uint[]) tokenOwners;
    uint lastUsedTokenId;
    mapping (uint=>mapping(address=>bool)) approvals;
    mapping (address=>mapping(address=>bool)) approvalsForAll;


    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner () {
        require(msg.sender==owner, "You are not an owner");
        _;
    }

    function mint(address to) public onlyOwner {
        lastUsedTokenId++;
        tokens[lastUsedTokenId] = to;
        tokenOwners[to].push(lastUsedTokenId);
    }

    function balanceOf(address _owner) external view returns (uint balance) {
        balance = tokenOwners[_owner].length;
    }

    function onwerOf(uint _tokenId) external view returns (address _owner) {
        _owner = tokens[_tokenId];
    }

    function transferFrom(address _from, address _to, uint _tokenId) external {
        require(tokens[_tokenId] == _from, "There is no token with such id that belongs to user");
        if (!(_from == msg.sender || approvals[_tokenId][msg.sender] || approvalsForAll[_from][msg.sender])) {
            revert("You are not allowed to do that");
        }
        tokens[_tokenId] = _to;
        tokenOwners[_to].push(_tokenId);
        tokenOwners[_from].removeByValue(_tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external {
        require (tokens[_tokenId]==_approved, "You are not an owner of token");
        approvals[_tokenId][_approved] = true;
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        approvalsForAll[msg.sender][_operator] = _approved;
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return approvalsForAll[_owner][_operator];
    }

}