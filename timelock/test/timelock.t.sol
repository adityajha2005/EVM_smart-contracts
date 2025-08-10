//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import {Test, console2} from "forge-std/Test.sol";
import {Timelock} from "../src/timelock.sol";

contract Target {
    uint256 public stored;
    event Stored(uint256 value);

    function setValue(uint256 value) external {
        stored = value;
        emit Stored(value);
    }
}

contract TimelockTest is Test {
    Timelock public timelock;
    address public admin;
    address public user;

    function setUp() public {
        admin = makeAddr("admin");
        user = makeAddr("user");
        timelock = new Timelock(admin);
    }

    function test_constructor_sets_admin_correctly() public {
        assertEq(timelock.admin(), admin);
    }

    function test_constructor_reverts_on_zero_admin() public {
        vm.expectRevert();
        new Timelock(address(0));
    }

    function test_queueTransaction_stores_data_correctly() public {
        uint256 etaIn = block.timestamp + 1 days + 100;
        vm.prank(admin);
        bytes32 txId = timelock.queueTransaction(address(this), 100, "function()", "", etaIn);
        (address target, uint256 value, string memory signature, bytes memory data, uint256 eta) = timelock.transactions(txId);
        assertEq(target, address(this));
        assertEq(value, 100);
        assertEq(signature, "function()");
        assertEq(data, bytes(""));
        assertEq(eta, etaIn);
    }

    function test_queueTransaction_reverts_if_eta_too_early() public {
        uint256 etaIn = block.timestamp + 1; 
        vm.startPrank(admin);
        vm.expectRevert("ETA too early");
        timelock.queueTransaction(address(this), 100, "function()", "", etaIn);
        vm.stopPrank();
    }

   function test_queueTransaction_reverts_if_already_queued() public {
        uint256 etaIn = block.timestamp + 1 days + 100;
        vm.prank(admin);
        timelock.queueTransaction(address(this), 100, "function()", "", etaIn);
        vm.startPrank(admin);
        vm.expectRevert("Transaction already queued");
        timelock.queueTransaction(address(this), 100, "function()", "", etaIn);
        vm.stopPrank();
    }

    function test_cancelTransaction_deletes_tx() public {
        uint256 etaIn = block.timestamp + 1 days + 100;
        vm.prank(admin);
        bytes32 txId = timelock.queueTransaction(address(this), 100, "function()", "", etaIn);
        vm.prank(admin);
        timelock.cancelTransaction(address(this), 100, "function()", "", etaIn);
        assertEq(timelock.queued(txId), false);
        Timelock.Transaction memory txData = timelock.getTransaction(txId);
        assertEq(txData.target, address(0));
        assertEq(txData.value, 0);
        assertEq(bytes(txData.signature).length, 0);
        assertEq(txData.data.length, 0);
        assertEq(txData.eta, 0);
    }

    function test_cancelTransaction_reverts_if_not_queued() public {
        uint256 etaIn = block.timestamp + 1 days + 100;
        vm.startPrank(admin);
        vm.expectRevert("Transaction not queued");
        timelock.cancelTransaction(address(this), 100, "function()", "", etaIn);
        vm.stopPrank();
    }

    function test_executeTransaction_succeeds_after_eta() public {
        Target target = new Target();
        uint256 etaIn = block.timestamp + 1 days + 100;

        vm.prank(admin);
        bytes32 txId = timelock.queueTransaction(
            address(target),
            0,
            "setValue(uint256)",
            abi.encode(uint256(77)),
            etaIn
        );
        vm.warp(etaIn + 1);
        vm.prank(admin);
        timelock.executeTransaction(
            address(target),
            0,
            "setValue(uint256)",
            abi.encode(uint256(77)),
            etaIn
        );
        assertEq(timelock.queued(txId), false);
        assertEq(target.stored(), 77);
    }

    function test_executeTransaction_reverts_if_before_eta() public {
        Target target = new Target();
        uint256 etaIn = block.timestamp + 1 days + 100;

        vm.prank(admin);
        bytes32 txId = timelock.queueTransaction(
            address(target),
            0,
            "setValue(uint256)",
            abi.encode(uint256(77)),
            etaIn
        );
        vm.warp(etaIn - 1);
        vm.prank(admin);
        vm.expectRevert("Transaction not yet executable");
        timelock.executeTransaction(
            address(target),
            0,
            "setValue(uint256)",
            abi.encode(uint256(77)),
            etaIn
        );
        assertEq(timelock.queued(txId), true);
    }

  function test_executeTransaction_forwards_eth_correctly() public {
        Target target = new Target();
        uint256 etaIn = block.timestamp + 1 days + 100;
        vm.prank(admin);
        bytes32 txId = timelock.queueTransaction(
            address(target),
            0,
            "setValue(uint256)",
            abi.encode(uint256(77)),
            etaIn
        );

        vm.warp(etaIn + 1);
        vm.prank(admin);
        timelock.executeTransaction(
            address(target), 
            0, 
            "setValue(uint256)",
            abi.encode(uint256(77)),
            etaIn
        );

        assertEq(timelock.queued(txId), false);
        assertEq(target.stored(), 77);
    }

    function test_non_admin_cannot_queue() public {
        uint256 etaIn = block.timestamp + 1 days + 100;
        vm.startPrank(user);
        vm.expectRevert();
        timelock.queueTransaction(address(this), 100, "function()", "", etaIn);
        vm.expectRevert();
        timelock.cancelTransaction(address(this), 100, "function()", "", etaIn);
        vm.expectRevert();
        timelock.executeTransaction(address(this), 100, "function()", "", etaIn);
        vm.stopPrank();
    }




    
}