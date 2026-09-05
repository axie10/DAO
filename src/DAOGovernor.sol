// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DAOGovernanceToken} from "./DAOGovernanceToken.sol";
import "./interface/IDAOTreasury.sol";

/**
 * @title DAO
 * @author Axie
 * @dev Descentralized Autonomous Organization contract
 */

contract DAOGovernor is Ownable {
    // Struct
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 favorVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
        address recipient;
        uint256 amount;
        address token;
        // if voted or not voted
        mapping(address => bool) hasVoted;
        // if voted in favor or against
        mapping(address => bool) votedFor;
    }

    // Variables
    DAOGovernanceToken public governanceToken;
    uint256 public proposalThreshold;
    uint256 public votingPeriod;
    uint256 public quorumVotes;

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    // Interface
    IDAOTreasury public treasury;

    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description,
        address recipient,
        uint256 amount,
        address token,
        uint256 stratTime,
        uint256 endTime
    );
    event Voted(uint256 indexed proposalId, address indexed voted, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event ConfigurationUpdated(uint256 proposalThreshold, uint256 votingPeriod, uint256 quorumVotes);

    /**
     * @dev Constructor
     * @param _governanceToken address of gorvernance token contract
     * @param _proposalTreshold minimun token required to create a proposal
     * @param _votingPeriod duration of the voting period seconds
     * @param _quorumVotes minimum votes required for proposal to pass
     */
    constructor(
        address _governanceToken,
        address _treasury,
        uint256 _proposalTreshold,
        uint256 _votingPeriod,
        uint256 _quorumVotes
    ) Ownable(msg.sender) {
        governanceToken = DAOGovernanceToken(_governanceToken);
        treasury = IDAOTreasury(_treasury);
        proposalThreshold = _proposalTreshold;
        votingPeriod = _votingPeriod;
        quorumVotes = _quorumVotes;
    }

    /**
     * @dev Create new proposal
     * @param description Description of the proposal
     * @param recipient Address to receive funds if proposal passes
     * @param amount Amount of funds to be spend
     * @param token Token address (address(0) for ETH)
     * @return proposalId Id generate of different params
     */
    function createProposal(string memory description, address recipient, uint256 amount, address token)
        external
        returns (uint256 proposalId)
    {
        require(
            governanceToken.getVotingPower(msg.sender) >= proposalThreshold,
            "Insufficient voting power to create proposal"
        );
        require(bytes(description).length > 0, "description can not be empty");
        require(recipient != address(0), "invalid recipient address");
        require(amount > 0, "amount must be greater than 0");

        proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.recipient = recipient;
        proposal.amount = amount;
        proposal.token = token;
        proposal.startTime = block.timestamp + votingPeriod;
        proposal.executed = false;
        proposal.canceled = false;

        emit ProposalCreated(
            proposalId,
            msg.sender,
            description,
            proposal.recipient,
            proposal.amount,
            proposal.token,
            proposal.startTime,
            proposal.endTime
        );
    }

    /**
     * @dev User vote in proposal
     * @param proposalId Id of proposal
     * @param support user vote, a favor or against
     */
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.proposer != address(0), "Proposal does not exit");
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp < proposal.endTime, "Voting finished");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(!proposal.canceled, "Proposal was canceled");
        require(!proposal.executed, "Proposal was executed");

        uint256 votes = governanceToken.getVotingPower(msg.sender);
        require(votes > 0, "Not votin power");

        proposal.hasVoted[msg.sender] = true;
        proposal.votedFor[msg.sender] = support;

        if (support) {
            proposal.favorVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }

        emit Voted(proposalId, msg.sender, support, votes);
    }

    /**
     * @dev Cancel proposal
     * @param proposalId id of the proposal to cancel
     */
    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal already canceled");
        require(msg.sender == proposal.proposer || msg.sender == owner(), "Not autorized to cancel");
        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    /**
     * @dev Execution proposal
     * @param proposalId id of the proposal to execute
     */
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp >= proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal is canceled");
        require(proposal.favorVotes + proposal.againstVotes >= quorumVotes, "Quorum not reached");
        require(proposal.favorVotes > proposal.againstVotes, "Proposal not passed");

        // First approve the proposal in treasury
        treasury.approveProposal(proposalId);

        // Then spend the funds
        treasury.spendFundsForProposal(proposalId, proposal.recipient, proposal.amount, proposal.token);

        // Mark as executed
        proposal.executed = true;

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Get proposal details
     * @param proposalId ID of the proposal
     * @return proposer Address of the proposer
     * @return description Description of the proposal
     * @return forVotes Number of votes for the proposal
     * @return againstVotes Number of votes against the proposal
     * @return startTime Start time of voting
     * @return endTime End time of voting
     * @return executed Whether the proposal has been executed
     * @return canceled Whether the proposal has been canceled
     * @return recipient Address to receive funds
     * @return amount Amount of funds to be spent
     * @return token Token address for the proposal
     */
    function getProposal(uint256 proposalId)
        external
        view
        returns (
            address proposer,
            string memory description,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 startTime,
            uint256 endTime,
            bool executed,
            bool canceled,
            address recipient,
            uint256 amount,
            address token
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.description,
            proposal.favorVotes,
            proposal.againstVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            proposal.canceled,
            proposal.recipient,
            proposal.amount,
            proposal.token
        );
    }

    /**
     * @dev Check if an address has voted on a proposal
     * @param proposalId ID of the proposal
     * @param voter Address to check
     * @return hasVoted Whether the address has voted
     * @return votedFor Whether the address voted for the proposal (only meaningful if hasVoted is true)
     */
    function getVoteInfo(uint256 proposalId, address voter) external view returns (bool hasVoted, bool votedFor) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.hasVoted[voter], proposal.votedFor[voter]);
    }

    /**
     * @dev Update DAO configuration (only owner)
     * @param _proposalThreshold New proposal threshold
     * @param _votingPeriod New voting period
     * @param _quorumVotes New quorum votes
     */
    function updateConfiguration(uint256 _proposalThreshold, uint256 _votingPeriod, uint256 _quorumVotes)
        external
        onlyOwner
    {
        proposalThreshold = _proposalThreshold;
        votingPeriod = _votingPeriod;
        quorumVotes = _quorumVotes;

        emit ConfigurationUpdated(_proposalThreshold, _votingPeriod, _quorumVotes);
    }

    /**
     * @dev Set the treasury contract address (only owner)
     * @param _treasury New treasury contract address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid treasury address");
        treasury = IDAOTreasury(_treasury);
    }

    /**
     * @dev Check if a proposal has passed
     * @param proposalId ID of the proposal
     * @return passed Whether the proposal has passed
     */
    function proposalPassed(uint256 proposalId) external view returns (bool passed) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.proposer == address(0) || proposal.canceled || proposal.executed) {
            return false;
        }

        if (block.timestamp < proposal.endTime) {
            return false; // Voting not ended
        }

        if (proposal.favorVotes + proposal.againstVotes < quorumVotes) {
            return false; // Quorum not reached
        }

        return proposal.favorVotes > proposal.againstVotes;
    }
}
