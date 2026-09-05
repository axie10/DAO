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
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
        address recipient;
        uint256 amount;
        address token;
        mapping(address => bool) hasVoted;
        mapping(address => bool) votedFor;
    }

    // Variables
    DAOGovernanceToken public governanceToken;
    uint256 public proposalTreshold;
    uint256 public votingPeriod;
    uint256 public quorumVotes;
    
    uint256 proposalCount;
    mapping(uint256 => Proposal) public proposals;

    // Interface
    IDAOTreasury public treasury;


    // Events
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, address recipient, uint256 amount, address token, uint256 stratTime, uint256 endTime);
    event Voted(uint256 indexed proposalId, address indexed proposer, string description, uint256 stratTime, uint256 endTime);
    event ProposalExecuted(uint256 indexed proposalId, address indexed proposer, string description, uint256 stratTime, uint256 endTime);
    event ProposalCanceled(uint256 indexed proposalId, address indexed proposer, string description, uint256 stratTime, uint256 endTime);
    event ConfigurationUpdate(uint256 indexed proposalId, address indexed proposer, string description, uint256 stratTime, uint256 endTime);


    /**
     * @dev Constructor
     * @param _governanceToken address of gorvernance token contract
     * @param _proposalTreshold minimun token required to create a proposal
     * @param _votingPeriod duration of the voting period seconds
     * @param _quorumVotes minimum votes required for proposal to pass
     */
    constructor(address _governanceToken, address _treasury, uint256 _proposalTreshold, uint256 _votingPeriod, uint256 _quorumVotes) Ownable(msg.sender) {
        governanceToken = DAOGovernanceToken(_governanceToken);
        treasury = IDAOTreasury(_treasury);
        proposalTreshold = _proposalTreshold;
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
    function createProposal(string memory description, address recipient, uint256 amount, address token) external returns (uint256 proposalId) {
        require(governanceToken.getVotingPower(msg.sender) >= proposalTreshold, "Insufficient voting power to create proposal");
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

        emit ProposalCreated(proposalId, msg.sender, description, proposal.recipient, proposal.amount, proposal.token, proposal.startTime, proposal.endTime);

    }


}
