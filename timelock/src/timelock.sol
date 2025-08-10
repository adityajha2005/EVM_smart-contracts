//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
contract Timelock is ReentrancyGuard {
    
    constructor(address _admin) {
        require(_admin != address(0), "Invalid admin address");
        admin = _admin;
    }


    struct Transaction {
        address target;
        uint256 value;
        string signature;
        bytes data;
        uint256 eta;
    }

    uint256 public constant MINIMUM_DELAY = 1 days;
    uint256 public constant GRACE_PERIOD = 14 days;
    mapping(bytes32 => bool) public queued;
    address public admin;
    mapping(bytes32 => Transaction) public transactions; //for storing the transaction details


    event QueueTransaction(bytes32 indexed txId, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    event ExecuteTransaction(bytes32 indexed txId, address indexed target, uint256 value, string signature, bytes data);
    event CancelTransaction(bytes32 indexed txId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    function getTxId(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public pure returns (bytes32){
        return keccak256(abi.encode(target,value,signature,data,eta));
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public onlyAdmin nonReentrant returns (bytes32) {
        require(eta >=block.timestamp + MINIMUM_DELAY, "ETA too early");
        // require(block.timestamp <= eta + GRACE_PERIOD, "Transaction is stale");
        bytes32 txId = getTxId(target,value,signature,data,eta);
        require(!queued[txId], "Transaction already queued");
        queued[txId] = true;
        transactions[txId] = Transaction(target,value,signature,data,eta); //for storing the transaction details

        emit QueueTransaction(txId,target,value,signature,data,eta);
        return txId;
    }

    function cancelTransaction(address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public onlyAdmin returns (bytes32) {
        bytes32 txId = getTxId(target,value,signature,data,eta);
        require(queued[txId], "Transaction not queued");
        delete queued[txId];
        delete transactions[txId];
        emit CancelTransaction(txId);
        return txId;
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public onlyAdmin nonReentrant payable returns (bytes memory) {
        bytes32 txId = getTxId(target,value,signature,data,eta);
        require(queued[txId], "Transaction not queued");
        require(block.timestamp <= eta + GRACE_PERIOD, "Transaction is stale");
        require(block.timestamp >= eta, "Transaction not yet executable");

        delete queued[txId];

        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data; 
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returnData) = target.call{value:value}(callData);
        require(success, "Transaction failed");
        delete transactions[txId];
        emit ExecuteTransaction(txId,target,value,signature,data);
        return returnData;
    }

    receive() external payable {}

    function getTransaction(bytes32 txId) public view returns (Transaction memory) {
        return transactions[txId];
    }
} 