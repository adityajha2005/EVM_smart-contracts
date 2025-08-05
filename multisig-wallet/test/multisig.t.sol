// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Multisig} from "../src/multisig.sol";

contract MultisigTest is Test{
    Multisig public multisig;
    address[] public owners;
    uint8 public requiredConfirmations;
    function setUp() public{
        owners = [address(0x1),address(0x2),address(0x3)];
        requiredConfirmations=2;
        multisig = new Multisig(owners,requiredConfirmations);
    }

    function test_submitTransaction() public{
        vm.prank(owners[0]);
        multisig.submitTransaction(address(0x4),1000000000000000000,"");
    (
        address to,
        uint256 value,
        bytes memory data,
        bool executed,
        uint256 numConfirmations
    ) = multisig.transactions(0);
        assertEq(to,address(0x4));
        assertEq(value,1000000000000000000);
        assertEq(executed,false);
        assertEq(numConfirmations,0);
        assertEq(data.length,0);
    }

    //will fail because not on owner
    // function test_submitNewTransaction() public{
    //     // vm.prank(owners[0]);
    //     multisig.submitTransaction(address(0x5),1000000000000000000,"");
    // (
    //     address to,
    //     uint128 value,
    //     bytes memory data,
    //     bool executed,
    //     uint8 numConfirmations
    // ) = multisig.transactions(0);
    //     assertEq(to,address(0x5));
    //     // assertEq(value,1000000000000000000);
    //     // assertEq(executed,false);
    //     // assertEq(numConfirmations,0);
    //     // assertEq(data.length,0);
    // }

    function test_confirmOwnTransaction() public{
        vm.startPrank(owners[0]);
        multisig.submitTransaction(address(0x4),1000000000000000000,"");
        multisig.confirmTransaction(0);
        vm.stopPrank();
        (
        address to,
        uint256 value,
        bytes memory data,
        bool executed,
        uint256 numConfirmations
        ) = multisig.transactions(0);
        assertEq(to,address(0x4));
        assertEq(value,1000000000000000000);
        assertEq(executed,false);
        assertEq(numConfirmations,1);
        assertEq(data.length,0);
    }

    function test_confirmTransaction() public{
        vm.prank(owners[0]);
        multisig.submitTransaction(address(0x4),1000000000000000000,"");
        vm.prank(owners[1]);
        multisig.confirmTransaction(0);
        (
        address to,
        uint256 value,
        bytes memory data,
        bool executed,
        uint256 numConfirmations
        ) = multisig.transactions(0);
        assertEq(to,address(0x4));
        assertEq(value,1000000000000000000);
        assertEq(executed,false);
        assertEq(numConfirmations,1);
        assertEq(data.length,0);
    }



    function test_executeTransaction() public{
        vm.deal(address(multisig), 1 ether);
        vm.prank(owners[0]);
        multisig.submitTransaction(address(0x4),1000000000000000000,"");
        vm.prank(owners[1]);
        multisig.confirmTransaction(0);
        vm.prank(owners[2]);
        multisig.confirmTransaction(0);
        vm.prank(owners[0]);
        multisig.executeTransaction(0);
        (
            address too,
            uint256 value,
            bytes memory data,
            bool executed, 
            uint256 numConfirmations
        ) = multisig.transactions(0);
        assertEq(too,address(0x4));
        assertEq(value,1000000000000000000);
        assertEq(executed,true);
        // assertEq(numConfirmations,3);
        assertEq(data.length,0);
    }
    // must fail because not enough money
    function test_MINmoneyexecuteTransaction() public{
        vm.deal(address(multisig), 0.000001 ether);
        vm.prank(owners[0]);
        multisig.submitTransaction(address(0x4),10000000000000,"");
        vm.prank(owners[1]);
        multisig.confirmTransaction(0);
        vm.prank(owners[2]);
        multisig.confirmTransaction(0);
        vm.prank(owners[0]);
        vm.expectRevert();
        multisig.executeTransaction(0);
       
    }

    function test_BORDERmoneyexecuteTransaction() public{
        vm.deal(address(multisig), 0.00001 ether);
        vm.prank(owners[0]);
        multisig.submitTransaction(address(0x4),10000000000000,"");
        vm.prank(owners[1]);
        multisig.confirmTransaction(0);
        vm.prank(owners[2]);
        multisig.confirmTransaction(0);
        vm.prank(owners[0]);
        multisig.executeTransaction(0);
        (
            address too,
            uint256 value,
            bytes memory data,
            bool executed, 
            uint256 numConfirmations
        ) = multisig.transactions(0);
        assertEq(too,address(0x4));
        assertEq(value,10000000000000);
        assertEq(executed,true);
        // assertEq(numConfirmations,3);
        assertEq(data.length,0);
    }

    function test_TransactionRevoked() public{
        vm.deal(address(multisig), 0.00001 ether);
        vm.prank(owners[0]);
        multisig.submitTransaction(address(0x4),10000000000000,"");
        vm.prank(owners[1]);
        multisig.confirmTransaction(0);
        vm.prank(owners[2]);
        multisig.confirmTransaction(0);
        vm.prank(owners[1]);
        multisig.revokeConfirmation(0);
        (
            address too,
            uint256 value,
            bytes memory data,
            bool executed, 
            uint256 numConfirmations
        ) = multisig.transactions(0);
        assertEq(too,address(0x4));
        assertEq(value,10000000000000);
        assertEq(executed,false);
        assertEq(numConfirmations,1);
        assertEq(data.length,0);
    }

    function test_checkOldOwner() public{
        vm.prank(owners[0]);
        vm.expectRevert();
        multisig.addOwner(address(0x1));
    }
    function test_addOwner() public{
        vm.prank(owners[0]);
        multisig.addOwner(address(0x6));
        assertEq(multisig.isOwner(address(0x6)),true);
    }
    function test_replaceOwner() public{
        vm.prank(owners[0]);
        multisig.replaceOwner(address(0x1),address(0x6));
        assertEq(multisig.isOwner(address(0x6)),true);
    }
    function test_submitTransactionFail_NotOwner() public {
        vm.expectRevert();
        multisig.submitTransaction(address(0x5), 1 ether, "");
    }
    function test_confirmTransactionFail_NotOwner() public {
        vm.prank(owners[0]);
        multisig.submitTransaction(address(0x4), 1 ether, "");
        vm.prank(address(0x99));
        vm.expectRevert();
        multisig.confirmTransaction(0);
    }
    function test_doubleconfirmFail() public {
        vm.prank(owners[0]);
        multisig.submitTransaction(address(0x4), 1 ether, "");
        vm.prank(owners[1]);
        multisig.confirmTransaction(0);
        vm.expectRevert();
        multisig.confirmTransaction(0);
    }
    function test_notenoughConfirmationFail() public{
        vm.prank(owners[0]);
        multisig.submitTransaction(address(0x4), 1 ether, "");
        vm.prank(owners[1]);
        multisig.confirmTransaction(0);
        vm.expectRevert();
        multisig.executeTransaction(0);
    }

}