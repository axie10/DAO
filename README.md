# DAO Governance System
 
A fully on-chain Decentralized Autonomous Organization (DAO) built with Solidity and Foundry. This project implements a complete governance lifecycle: token-based voting power, proposal creation, decentralized voting, and treasury management — all controlled by the community with no single point of authority.
 
## Architecture
 
The system follows a modular multi-contract design where each component has a single, well-defined responsibility:
 
```
┌──────────────────────────────────────────────────────────────┐
│                       DAO System                             │
│                                                              │
│  ┌─────────────────┐         ┌────────────────────────────┐  │
│  │   Governance     │         │        Treasury            │  │
│  │     Token        │────────▶│   (Community Funds)        │  │
│  │   (ERC-20)       │ voting  │                            │  │
│  │                  │ power   │  • Fund management         │  │
│  │  • Mint/Burn     │         │  • Emergency withdraw      │  │
│  │  • Delegate      │         │  • Proposal execution      │  │
│  └────────┬────────┘         └─────────────▲──────────────┘  │
│           │                                │                  │
│           │ determines                     │ executes         │
│           │ who votes                      │ approved         │
│           ▼                                │ proposals        │
│  ┌─────────────────────────────────────────┴──────────────┐  │
│  │              Governor / Voting System                   │  │
│  │                                                         │  │
│  │  • Create proposals          • Cancel proposals         │  │
│  │  • Decentralized voting      • Execute proposals        │  │
│  │  • Approve proposals         • Quorum enforcement       │  │
│  └─────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```
 
## Features
 
### Governance Token
- ERC-20 token with voting power delegation
- Token holders delegate voting rights (to themselves or others)
- Voting power is tracked on-chain
### Treasury
- Secure community fund management
- Receives and holds ETH on behalf of the DAO
- Fund disbursements require governance approval
- Emergency withdrawal mechanism with access control
### Proposal System
- Any eligible member can create proposals
- Decentralized on-chain voting
- Proposal lifecycle: Created → Active → Approved/Rejected → Executed/Cancelled
- Only approved proposals can trigger treasury actions
### Security
- Access control on privileged operations
- Checks-Effects-Interactions pattern on all ETH transfers
- Emergency mechanisms with appropriate safeguards
- Modular contract design to minimize attack surface
## Tech Stack
 
| Tool            | Purpose                        |
| --------------- | ------------------------------ |
| Solidity ^0.8.x | Smart contract language        |
| Foundry         | Development and testing        |
| OpenZeppelin    | Battle-tested contract library |
 
## Project Structure
 
```
├── src/
│   ├── GovernanceToken.sol      # ERC-20 with voting delegation
│   ├── Treasury.sol             # Community fund management
│   └── Governor.sol             # Proposal and voting logic
├── test/
│   └── ...                      # Foundry test suite
├── script/
│   └── ...                      # Deployment scripts
└── foundry.toml
```
 
## Getting Started
 
### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
### Build
```bash
forge build
```
 
### Test
```bash
forge test -vv
```
 
## Course Context
 
This project is part of a comprehensive Blockchain and Solidity Master's program, covering the full DAO development lifecycle from governance token creation through proposal execution and treasury management.