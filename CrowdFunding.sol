// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

contract Crowdfunding {
    address public owner;
    uint256 public goal;
    uint256 public deadline;
    uint256 public totalRaised;

    mapping(address => uint256) public contributions;
    bool public finalized;

    constructor(uint256 _goal, uint256 _duration) {
        owner = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _duration;
    }

    function contribute() external payable {
        require(block.timestamp < deadline, "Ended");
        require(msg.value > 0, "Cant contribute with zero wei");
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
    }

    function finalize() external {
        require(block.timestamp >= deadline, "Crowdfunding not ended");
        require(!finalized, "Already finalized");
        finalized = true;
        if (totalRaised >= goal) {
            payable(owner).transfer(address(this).balance);
        }
    }

    function refund() external {
        require(finalized, "Crowddfunding not finalized");
        require(totalRaised < goal, "Goal not achieved");
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "You cant refund");
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
