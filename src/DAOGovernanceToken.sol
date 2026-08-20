// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Governance token for the DAO.
/// @dev Token used for DAO Governance voting
contract DAOGovernanceToken is ERC20, Ownable {
    // Variables
    mapping(address => bool) hasDelegated;
    mapping(address => address) delegates;
    mapping(address => uint256) delegatesVotes;

    // Events
    event VotingPowerDelegated(address indexed delegator, address indexed delegated, uint256 amount);
    event VotingPowerUndelegated(address indexed delegator, address indexed delegated, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
    }

    // Functions
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev function to get power of address to voting
     * @param account address to get power
     * @return total voting power
     */
    function getVotingPower(address account) external view returns (uint256) {
        return balanceOf(account);
    }

    /**
     * @dev delegateVotingPower function to delegate votes to other account
     * @param delegate address to get votes
     * @param amount amount to transfer other account
     */
    function delegateVotingPower(address delegate, uint256 amount) external {
        require(delegate != address(0), "cannot delegate to  zero address");
        require(delegate != msg.sender, "Not possible transfer to your account");
        require(amount > 0, "amount must be > 0");
        require(balanceOf(msg.sender) > amount, "Insufficient balance");

        _transfer(msg.sender, delegate, amount);
        delegates[msg.sender] = delegate;
        delegatesVotes[delegate] += amount;
        hasDelegated[msg.sender] = true;

        emit VotingPowerDelegated(msg.sender, delegate, amount);
    }

    /**
     * @dev function to undelegate votes to other account
     * @param amount amount to transfer other account
     */
    function undelegateVotingPower(uint256 amount) external {
        require(hasDelegated[msg.sender] = true, "No delegation found");
        require(amount > 0, "amount must be > 0");
        require(delegatesVotes[delegates[msg.sender]] >= amount, "Insufficient delegated amount");

        address delegate = delegates[msg.sender];
        _transfer(delegate, msg.sender, amount);
        delegatesVotes[delegate] -= amount;

        if (delegatesVotes[delegate] == 0) {
            hasDelegated[msg.sender] = false;
            delete delegates[msg.sender];
        }

        emit VotingPowerUndelegated(msg.sender, delegate, amount);
    }
}
