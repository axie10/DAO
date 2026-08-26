// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DAOGovernanceToken} from "./DAOGovernanceToken.sol";

/**
 * @title DAO
 * @author Axie
 * @dev Descentralized Autonomous Organization contract
 */

contract DAOGovernor is Ownable {

    // Struct
    struct Proposal {
        uint256 id;
        address proposel;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted;
        mapping(address => bool) votedFor;
    }

    // Variables
    DAOGovernanceToken public governanceToken;
    uint256 public proposalTreshold;
    uint256 public votingPeriod;
    uint256 public quorumVotes;

    uint256 proposalCount;
    mapping(uint256 => Proposal) public proposal;

    // Events
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 stratTime, uint256 endTime);
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
    constructor(address _governanceToken, uint256 _proposalTreshold, uint256 _votingPeriod, uint256 _quorumVotes) Ownable(msg.sender) {
        governanceToken = DAOGovernanceToken(_governanceToken);
        proposalTreshold = _proposalTreshold;
        votingPeriod = _votingPeriod;
        quorumVotes = _quorumVotes;
    }


}
