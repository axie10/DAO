// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DAOGovernor} from "./DAOGovernor.sol";

contract DAOTreasury is Ownable {
    using SafeERC20 for IERC20;

    // Variable
    // DAO contract reference
    DAOGovernor public dao;

    // Mapping
    mapping(uint256 => bool) public approveProposal;
    mapping(uint256 => bool) public executedProposal;

    // Events
    event ApproveProposal(uint256 indexed proposalId);
    event FundsSpend(uint256 indexed proposalId, address indexed recipient, uint256 amount, address token);
    event RecivedFundsTreasury(address indexed sender, uint256 amount);
    event DAOSet(address indexed dao);

    constructor(address _dao) Ownable(msg.sender) {
        dao = DAOGovernor(_dao);
    }

    // Functions
    /**
     * @dev function to change DAOGrovernance (rules smart contract)
     * @param _dao new address to DAO smart Contract
     */
    function setDao(address _dao) external onlyOwner {
        require(_dao != address(0), "Address not valid");
        dao = DAOGovernor(_dao);
        emit DAOSet(_dao);
    }

    /**
     * @dev fund treasury with ETH
     */
    function fundTreasury() external payable {
        require(msg.value > 0, "Must send ETH");
        emit RecivedFundsTreasury(msg.sender, msg.value);
    }

    /**
     * @dev fund treasury with ERC20 tokens
     * @param token address token
     * @param amount amount send to treasury
     */
    function fundTreasuryWithToken(address token, uint256 amount) external {
        require(token != address(0), "Invalid addres");
        require(amount > 0, "Must send tokens");

        IERC20 tokenContract = IERC20(token);
        tokenContract.safeTransferFrom(msg.sender, address(this), amount);

        emit RecivedFundsTreasury(msg.sender, amount);
    }

    /**
     * @dev recived eth without call any functions
     */
    receive() external payable {
        emit RecivedFundsTreasury(msg.sender, msg.value);
    }

    /**
     * @dev withdraw ETH and other token
     * @param token address token
     * @param to address to send
     * @param amount amount to send
     */
    function emergencyWithdraw(address token, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Must send tokens");

        if (token == address(0)) {
            require(address(this).balance >= amount, "Insufficient ETH balance");
            (bool success,) = to.call{value: amount}("");
            require(success, "DAOTreasury: ETH transfer failed");
        } else {
            IERC20 tokenContract = IERC20(token);
            require(tokenContract.balanceOf(address(this)) >= amount, "Insufficient token balance");
            tokenContract.safeTransfer(to, amount);
        }
    }
}
