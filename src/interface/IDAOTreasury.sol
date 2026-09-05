// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

interface IDAOTreasury {
    function approveProposal(uint256 proposalId) external;
    function spendFundsForProposal(uint256 proposalId, address recipient, uint256 amount, address token) external;
}
