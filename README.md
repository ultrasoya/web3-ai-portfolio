# Web3 AI Portfolio

A decentralized platform for generating and managing AI-powered blockchain analytics reports as NFTs.

## Key Features

- **User Profile Management** - Register users with customizable preferences for report types (JSON, PDF, NFT) and focus areas (DeFi, NFT, Tokens, Portfolio)
- **EIP-712 Signature Verification** - Secure report creation with cryptographic signature validation using standardized typed data signing
- **NFT Report Minting** - Automatically mint reports as NFTs on-chain with IPFS content storage
- **Authorized Backend Integration** - Role-based access control for trusted backend services to create verified reports

## Stack

**Smart Contracts:**
- Solidity ^0.8.30
- Foundry (Forge, Cast, Anvil)
- OpenZeppelin Contracts
- Chainlink

**Backend:**
- Node.js
- Express.js

**Storage:**
- IPFS (Content addressing via CID)

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js v16+
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/web3-ai-portfolio.git
cd web3-ai-portfolio

# Install dependencies
npm install

# Install Foundry dependencies
cd apps/contracts
forge install
```

### Running Tests

```bash
# Run all tests
cd apps/contracts
forge test

# Run tests with verbosity
forge test -vvv

# Run specific test file
forge test --match-path test/unit/UserProfiles.t.sol
```

### Deploy Contracts

```bash
# Set environment variables
cp .env.example .env
# Edit .env with your SEPOLIA_RPC_URL and PRIVATE_KEY

# Deploy to Sepolia testnet
cd apps/contracts
forge script script/DeployContracts.s.sol:DeployContracts --rpc-url sepolia --broadcast --verify
```

### Run Backend

```bash
cd apps/backend
npm install
npm start
```

## Contract Architecture

- **UserProfiles** - Manages user registration, profiles, and preferences
- **ReportsManager** - Handles report creation with signature verification
- **ReportNFT** - ERC721 implementation for minting report NFTs
- **VerifyEIP712** - EIP-712 typed data signature verification

## License

MIT
