// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AllInGame
 * @author Dewynd
 * @notice A commit-reveal “highest-bid-wins” game.  
 *         Players first commit a hashed bid during the **bidding phase** and later
 *         reveal the plaintext bid during the **reveal phase**.  
 *         After the reveal phase ends, anyone can execute the game,
 *         transferring the entire pot to the player who revealed the largest bid.
 * @dev    Uses `ReentrancyGuard` to protect the `execute` payout.
 */
contract AllInGame is ReentrancyGuard {

    uint256 private lastUsedId;

    /**
     * @dev A single game instance.
     * @param bidders           Ordered list of addresses that committed a bid.
     * @param endTimestamp      End of the bidding phase (unix time s).
     * @param revealTimestamp   End of the reveal phase (unix time s).
     * @param bids              Commitments
     * @param isActive          True while the game has not yet been executed.
     * @param biggestBid        Largest revealed bid so far (wei).
     * @param biggestBidder     Address that made `biggestBid`.
     * @param totalBids         Sum of all revealed bids (wei).
     */
    struct Game {
        address[] bidders;
        uint256 endTimestamp;
        uint256 revealTimestamp;
        mapping(address => bytes32) bids;
        bool isActive;
        uint256 biggestBid;
        address biggestBidder;
        uint256 totalBids;
    }

    /// @dev gameId => Game
    mapping(uint256 => Game) private games;

    /**
     * @notice Deploys the contract. No special initialization required.
    */
    constructor() {}

    /**
     * @notice Start a new game.
     * @dev    The caller does **not** gain any special rights over the game.
     * @param  durationSeconds   Length of the bidding phase in seconds.
     * @param  durationOfReveal  Length of the reveal phase in seconds.
     * @return gameId           The identifier of the newly created game.
     */
    function createGame(
        uint256 durationSeconds,
        uint256 durationOfReveal
    ) external returns (uint256 gameId) {
        lastUsedId++;
        Game storage g = games[lastUsedId];
        g.endTimestamp = block.timestamp + durationSeconds;
        g.revealTimestamp = g.endTimestamp + durationOfReveal;
        g.isActive = true;
        gameId = lastUsedId;
    }

    /**
     * @notice Commit a bid hash for an active game.
     * @param  gameId  The game identifier returned by `createGame`.
     * @param  hash    Commit hash = keccak256(abi.encodePacked(bidAmount, secretSeed)).
     */
    function bid(uint256 gameId, bytes32 hash) external {
        Game storage g = games[gameId];
        require(g.isActive && block.timestamp < g.endTimestamp, "Game is not active");
        g.bids[msg.sender] = hash;
        g.bidders.push(msg.sender);
    }

    /**
     * @notice Reveal a previously committed bid.
     * @param  gameId  The game identifier.
     * @param  amount  The bid amount in wei (must equal `msg.value`).
     * @param  seed    The secret seed used in the commitment.
     */
    function reveal(
        uint256 gameId,
        uint256 amount,
        uint256 seed
    ) external payable {
        Game storage g = games[gameId];
        require(
            block.timestamp >= g.endTimestamp && block.timestamp < g.revealTimestamp,
            "Not reveal interval"
        );
        require(msg.value == amount, "Amount mismatch");
        require(
            keccak256(abi.encodePacked(amount, seed)) == g.bids[msg.sender],
            "Commitment mismatch"
        );

        g.totalBids += amount;
        if (amount > g.biggestBid) {
            g.biggestBid = amount;
            g.biggestBidder = msg.sender;
        }
    }

    /**
     * @notice Finalise the game and pay the pot to the highest bidder.
     * @param  gameId  The game identifier.
     */
    function execute(uint256 gameId) external nonReentrant {
        Game storage g = games[gameId];
        require(block.timestamp >= g.revealTimestamp, "Reveal phase not over");
        require(g.isActive, "Already executed");
        g.isActive = false;
        payable(g.biggestBidder).transfer(g.totalBids);
    }
}
