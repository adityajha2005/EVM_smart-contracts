# EVM Smart Contracts Collection

A comprehensive collection of production-ready Ethereum smart contracts covering token standards, staking mechanisms, and vesting systems.

## Overview

This repository contains three fully-featured smart contracts designed for real-world DeFi applications:

- **ScratchERC20**: Custom ERC20 token with advanced features
- **Staking**: Reward-based staking system with lock periods
- **TokenVesting**: Multi-schedule token vesting with batch operations

## Project Structure

```
EVM/
├── ScratchERC20/          # Custom ERC20 Token Implementation
│   ├── src/ERC20.sol     # Main token contract
│   ├── test/ERC20.t.sol  # Comprehensive test suite
│   └── README.md         # Detailed documentation
├── staking/              # Staking Contract with Rewards
│   ├── src/Staking.sol   # Main staking contract
│   ├── test/Staking.t.sol # Test suite
│   └── README.md         # Documentation
└── token-vest/           # Token Vesting System
    ├── src/Vesting.sol   # Main vesting contract
    ├── test/Vesting.t.sol # Test suite
    └── README.md         # Documentation
```

## Contracts Overview

### 🪙 ScratchERC20
**Custom ERC20 Token with Advanced Features**

A complete ERC20 implementation with additional capabilities beyond the standard:

**Key Features:**
- Standard ERC20 functionality (transfer, approve, transferFrom)
- Minting capability for token creation
- Burning functionality for token destruction
- Advanced allowance management (increase/decrease)
- Ownership management with transfer capability
- Comprehensive event emission

**Use Cases:**
- Custom tokens for DeFi protocols
- Reward systems and loyalty programs
- Governance tokens with minting control
- Utility tokens with advanced allowance features

**Security Features:**
- Owner-only minting
- Comprehensive input validation
- Safe math operations (Solidity ^0.8.29)
- Complete audit trail with events

### 🏦 Staking Contract
**Reward-Based Staking System with Lock Periods**

A production-ready staking contract designed for DeFi applications:

**Key Features:**
- Single staking per user (one stake per address)
- Time-based reward calculation
- Configurable lock periods
- Emergency pause functionality
- Reward claiming and withdrawal mechanisms
- Administrative controls for reward rates

**Use Cases:**
- DeFi yield farming protocols
- DAO governance staking
- Loyalty and incentive programs
- Token economics and supply control

**Security Features:**
- Reentrancy protection
- Emergency pause controls
- Access control for administrative functions
- Safe ERC20 token transfers

### 📅 TokenVesting
**Multi-Schedule Token Vesting System**

A comprehensive vesting contract supporting multiple schedules per beneficiary:

**Key Features:**
- Multiple vesting schedules per beneficiary
- TGE (Token Generation Event) + linear vesting
- Configurable cliff periods and lockup periods
- Batch operations for gas efficiency
- Revocable vesting schedules
- Emergency pause functionality

**Use Cases:**
- Team token vesting schedules
- Investor token lockups
- Advisor compensation plans
- Community reward distributions

**Security Features:**
- Comprehensive access controls
- Reentrancy protection
- Graceful error handling
- Emergency controls and recovery mechanisms

## Technology Stack

### Core Technologies
- **Solidity**: ^0.8.28 - ^0.8.29
- **Foundry**: Ethereum development framework
- **OpenZeppelin**: Security-focused smart contract library

### Development Tools
- **Forge**: Testing and deployment framework
- **Anvil**: Local Ethereum node
- **Cast**: EVM interaction toolkit

## Quick Start

### Prerequisites
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Installation
```bash
# Clone the repository
git clone https://github.com/adityajha2005/EVM_smart-contracts
cd EVM_smart-contracts

# Install dependencies (if any)
forge install
```

### Testing
```bash
# Test all contracts
forge test

# Test specific contract
cd ScratchERC20 && forge test
cd staking && forge test
cd token-vest && forge test

# Run with verbose output
forge test -vv

# Generate gas report
forge test --gas-report
```

### Building
```bash
# Build all contracts
forge build

# Build specific contract
cd ScratchERC20 && forge build
```

## Contract Statistics

| Contract | Lines of Code | Functions | Events | Test Coverage |
|----------|---------------|-----------|--------|---------------|
| ScratchERC20 | ~92 | 10 | 2 | 4 tests |
| Staking | ~85 | 8 | 4 | 6 tests |
| TokenVesting | ~273 | 12 | 3 | 6 tests |

## Security Features

### Common Security Measures
- **Access Control**: Role-based permissions and ownership management
- **Reentrancy Protection**: Guards against reentrancy attacks
- **Input Validation**: Comprehensive parameter validation
- **Safe Operations**: Secure token transfers and state updates
- **Emergency Controls**: Pause functionality and recovery mechanisms

### Best Practices Implemented
- **OpenZeppelin Integration**: Using battle-tested libraries
- **Event Logging**: Complete audit trail for all operations
- **Gas Optimization**: Efficient storage and operation patterns
- **Error Handling**: Graceful failure modes and clear error messages

## Development Workflow

### 1. Local Development
```bash
# Start local node
anvil

# Deploy contracts
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key <key>
```

### 2. Testing Strategy
- **Unit Tests**: Individual function testing
- **Integration Tests**: Cross-contract interactions
- **Edge Case Testing**: Boundary conditions and error scenarios
- **Gas Testing**: Performance optimization validation

### 3. Deployment Process
1. **Local Testing**: Comprehensive test suite execution
2. **Testnet Deployment**: Staging environment validation
3. **Mainnet Deployment**: Production deployment with verification
4. **Post-Deployment**: Monitoring and maintenance

## Real-World Applications

### DeFi Protocols
- **Liquidity Mining**: Staking contracts for yield farming
- **Governance**: Token-based voting systems
- **Reward Distribution**: Automated incentive systems

### Token Economics
- **Supply Management**: Controlled token minting and burning
- **Vesting Schedules**: Team and investor token lockups
- **Incentive Alignment**: Long-term holder rewards

### Enterprise Solutions
- **Employee Compensation**: Token-based salary and bonus systems
- **Investor Relations**: Transparent token distribution
- **Compliance**: Regulatory-compliant token operations

## Contributing

### Development Guidelines
1. **Code Quality**: Follow Solidity best practices
2. **Testing**: Maintain 100% test coverage
3. **Documentation**: Keep README files updated
4. **Security**: Regular security audits and reviews

### Testing Requirements
- All functions must have corresponding tests
- Edge cases and error conditions must be covered
- Gas optimization should be validated
- Integration tests for cross-contract interactions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

### Documentation
- Each contract has detailed README documentation
- Code comments explain complex logic
- Usage examples provided for all functions

### Community
- Open source development
- Community contributions welcome
- Regular updates and improvements

## Roadmap

### Planned Features
- **Multi-token Staking**: Support for multiple token types
- **Advanced Vesting**: More complex vesting schedules
- **Governance Integration**: DAO voting mechanisms
- **Cross-chain Support**: Multi-chain deployment

### Future Enhancements
- **UI/UX**: Web interface for contract interaction
- **Analytics**: Dashboard for contract metrics
- **Mobile Support**: Mobile app integration
- **API Integration**: REST API for contract data

## Acknowledgments

- **OpenZeppelin**: For security-focused smart contract libraries
- **Foundry**: For the excellent development framework
- **Ethereum Community**: For continuous innovation and best practices

---

**Note**: These contracts are designed for educational and development purposes. For production use, ensure thorough testing and security audits are conducted. 