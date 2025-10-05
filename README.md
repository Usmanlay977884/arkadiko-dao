# Arkadiko DAO

DeFi protocol inspired by MakerDAO implementing stablecoin $DIKO and governance token $ARE with over-collateralized STX tokens.

## Overview

Arkadiko DAO is a decentralized finance protocol built on the Stacks blockchain that allows users to:

- **Lock STX tokens as collateral** to mint DIKO stablecoins
- **Participate in governance** using ARE governance tokens
- **Access reliable price feeds** through the integrated oracle system

## Smart Contracts

### 1. Arkadiko Token (`arkadiko-token.clar`)
- **Symbol**: ARE
- **Purpose**: Governance token for DAO voting and protocol decisions
- **Total Supply**: 1,000,000,000 tokens (with 6 decimals)
- **Features**:
  - Standard SIP-010 fungible token implementation
  - Mint/burn capabilities for authorized contracts
  - Contract authorization system for protocol integration

### 2. Arkadiko Oracle (`arkadiko-oracle.clar`)
- **Purpose**: Price oracle system for determining collateralization ratios and asset values
- **Features**:
  - Multi-asset price feeds (STX, BTC, ETH, etc.)
  - Price validity checking (24-hour expiration)
  - Authorized source management
  - Owner controls for source authorization/revocation

### 3. Arkadiko Vault (`arkadiko-vault.clar`)
- **Purpose**: Collateral management system for over-collateralizing STX tokens to mint stablecoins
- **Token**: DIKO Stablecoin
- **Features**:
  - Create vaults with STX collateral
  - Mint DIKO stablecoins against collateral
  - Minimum 150% collateralization ratio
  - Liquidation threshold at 120%
  - Repay debt and add/remove collateral
  - Multi-vault support per user

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development toolkit
- [Node.js](https://nodejs.org/) - For running tests
- [Git](https://git-scm.com/) - Version control

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Usmanlay977884/arkadiko-dao.git
cd arkadiko-dao
```

2. Install dependencies:
```bash
npm install
```

3. Check contracts syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

## Usage

### Creating a Vault

```clarity
;; Create a vault with 1000 STX as collateral
(contract-call? .arkadiko-vault create-vault u1000000000)
```

### Minting DIKO Stablecoins

```clarity
;; Mint 500 DIKO from vault #1 (must maintain >150% collateralization)
(contract-call? .arkadiko-vault mint-diko u1 u500000000)
```

### Oracle Price Updates

```clarity
;; Set STX price to $2.50 (authorized sources only)
(contract-call? .arkadiko-oracle set-price "STX" u2500000)
```

### Governance Token Operations

```clarity
;; Transfer 100 ARE tokens
(contract-call? .arkadiko-token transfer u100000000 tx-sender 'recipient-address none)
```

## Protocol Parameters

| Parameter | Value |
|-----------|--------|
| Minimum Collateral Ratio | 150% |
| Liquidation Threshold | 120% |
| ARE Total Supply | 1,000,000,000 |
| Price Feed Validity | 144 blocks (~24 hours) |
| Stability Fee | 0.5% annual (simplified) |

## Testing

The project includes comprehensive test suites for all contracts:

- **Token Tests**: Metadata, transfers, minting, burning, authorization
- **Oracle Tests**: Price feeds, authorization, ownership, validity
- **Vault Tests**: Creation, minting, repayment, collateral management

Run all tests:
```bash
npm test
```

Run specific test file:
```bash
npx vitest tests/arkadiko-token.test.ts
```

## Development

### Project Structure

```
arkadiko-dao/
├── contracts/
│   ├── arkadiko-token.clar      # Governance token (ARE)
│   ├── arkadiko-oracle.clar     # Price oracle system
│   └── arkadiko-vault.clar      # Collateral & stablecoin system
├── tests/
│   ├── arkadiko-token.test.ts   # Token contract tests
│   ├── arkadiko-oracle.test.ts  # Oracle contract tests
│   └── arkadiko-vault.test.ts   # Vault contract tests
├── settings/
│   ├── Devnet.toml
│   ├── Testnet.toml
│   └── Mainnet.toml
├── Clarinet.toml               # Project configuration
└── README.md
```

### Adding New Features

1. Create feature branch: `git checkout -b feature/new-feature`
2. Implement contract changes in `contracts/`
3. Add corresponding tests in `tests/`
4. Run `clarinet check` to validate syntax
5. Run `npm test` to ensure all tests pass
6. Submit pull request

## Security Considerations

- All contracts implement proper authorization checks
- Collateralization ratios prevent under-collateralized positions
- Oracle price feeds have time-based validity
- Contract ownership is transferable for upgradability
- Input validation prevents invalid parameter attacks

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet/)