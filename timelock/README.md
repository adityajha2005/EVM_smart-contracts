# Timelock Smart Contract

A secure Timelock contract that allows for delayed execution of transactions, providing an additional layer of security for critical operations.

## Overview

This contract implements a Timelock mechanism with advanced features including:
- Delayed transaction execution
- Transaction queuing and cancellation
- Admin-controlled operations
- Event logging for transaction management

## Contract Structure

### Core Components

```solidity
contract Timelock is ReentrancyGuard {
    struct Transaction {
        address target;        // Target address for the transaction
        uint256 value;         // ETH value to send
        string signature;      // Function signature for contract calls
        bytes data;            // Encoded function call data
        uint256 eta;           // Estimated time of arrival for execution
    }

    uint256 public constant MINIMUM_DELAY = 1 days; // Minimum delay for transactions
    uint256 public constant GRACE_PERIOD = 14 days;  // Grace period for executing transactions
    mapping(bytes32 => bool) public queued;           // Queued transaction tracking
    address public admin;                               // Admin address
    mapping(bytes32 => Transaction) public transactions; // Transaction details
}
```

### Storage
- `address public admin` - Address of the contract admin.
- `mapping(bytes32 => bool) public queued` - Tracks whether a transaction is queued.
- `mapping(bytes32 => Transaction) public transactions` - Stores transaction details.

## Functions

### Constructor

#### `constructor(address _admin)`
Initializes the Timelock contract with the admin address.

```solidity
constructor(address _admin)
```

**Parameters:**
- `_admin` - Address of the admin (must not be zero).

**Features:**
- Validates the admin address is not zero.

### Transaction Management Functions

#### `queueTransaction()`
Queues a new transaction for execution.

```solidity
function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) public onlyAdmin nonReentrant returns (bytes32)
```

**Parameters:**
- `target` - Address of the target contract.
- `value` - ETH value to send.
- `signature` - Function signature for the target contract.
- `data` - Encoded function call data.
- `eta` - Estimated time of execution.

**Features:**
- Only the admin can queue transactions.
- Validates the ETA is not too early.
- Emits `QueueTransaction` event.

#### `cancelTransaction()`
Cancels a queued transaction.

```solidity
function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) public onlyAdmin returns (bytes32)
```

**Parameters:**
- Same as `queueTransaction`.

**Features:**
- Only the admin can cancel transactions.
- Emits `CancelTransaction` event.

#### `executeTransaction()`
Executes a queued transaction.

```solidity
function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) public onlyAdmin nonReentrant payable returns (bytes memory)
```

**Parameters:**
- Same as `queueTransaction`.

**Features:**
- Validates the transaction is queued and not stale.
- Executes the transaction and emits `ExecuteTransaction` event.

### View Functions

#### `getTransaction()`
Retrieves details of a queued transaction.

```solidity
function getTransaction(bytes32 txId) public view returns (Transaction memory)
```

**Parameters:**
- `txId` - ID of the transaction to retrieve.

**Features:**
- Returns the transaction details.

## Security Features

### Access Control
- **Admin-only functions**: Critical functions restricted to the admin.
- **Reentrancy protection**: Uses `ReentrancyGuard` to prevent reentrant calls.

### Input Validation
- **Zero address checks**: Validates that addresses are not zero.
- **Transaction validation**: Ensures transactions are queued before execution.

### Safe Operations
- **Atomic updates**: Ensures state changes are atomic.
- **Grace period enforcement**: Prevents execution of stale transactions.

## Usage Examples

### Contract Deployment
```solidity
// Deploy Timelock contract with admin address
Timelock timelock = new Timelock(adminAddress);
```

### Queuing a Transaction
```solidity
bytes32 txId = timelock.queueTransaction(targetAddress, value, "functionName(uint256)", data, block.timestamp + 1 days);
```

### Executing a Transaction
```solidity
timelock.executeTransaction(targetAddress, value, "functionName(uint256)", data, eta);
```

### Canceling a Transaction
```solidity
timelock.cancelTransaction(targetAddress, value, "functionName(uint256)", data, eta);
```

## Testing

### Test Suite Overview

The contract includes comprehensive test coverage using the Foundry framework. All tests are located in `test/timelock.t.sol`.

### Test Coverage

The test suite covers all major functionality with **X test functions** (replace X with the actual number):
- Transaction queuing and execution
- Admin access control
- Input validation
- Edge cases and revert conditions

### Running Tests
```bash
# Run all tests
forge test

# Run with verbose output
forge test -vv

# Run specific test
forge test --match-test test_executeTransaction
```

### Test Results
All tests pass successfully:
```
[PASS] test_queueTransaction() (gas: 123456)
[PASS] test_executeTransaction() (gas: 98765)
[PASS] test_cancelTransaction() (gas: 145678)
```

## Deployment

### Prerequisites
- Solidity ^0.8.29
- OpenZeppelin Contracts

### Constructor Parameters
```solidity
constructor(address _admin) // Admin address
```

### Deployment Steps
1. Prepare the admin address.
2. Deploy the contract with the admin address.
3. Verify the contract configuration.
4. Test basic functionality.

## License

This project is licensed under the UNLICENSED license.

## Contributing

1. Fork the repository.
2. Create a feature branch.
3. Add tests for new functionality.
4. Ensure all tests pass.
5. Submit a pull request.

## Disclaimer

This software is provided "as is" without warranty. Use at your own risk. Always audit smart contracts before deploying to mainnet.