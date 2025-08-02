// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/Vesting.sol";
import "./mocks/MockERC20.sol";

contract VestingTest is Test {
    TokenVesting public vesting;
    MockERC20 public token;

    address public owner = address(0x1234567890123456789012345678901234567890);
    address public beneficiary = address(0x1224567890123456789012345678901234567890);

    function setUp() public {
        token = new MockERC20();
        token.mint(owner, 1_000_000 ether);

        vm.prank(owner);
        vesting = new TokenVesting(owner, address(token));

        // Approve vesting contract to pull tokens
        vm.prank(owner);
        token.approve(address(vesting), type(uint256).max);
    }

    function test_createVestingSchedule() public {
        vm.prank(owner);
        vesting.createVestingSchedule(
        beneficiary,
        1704067200,  
        1706745600,  
        31536000,    
        1000 ether, 
        123,         
        0,           
        true         
        );
        (
            address scheduleBeneficiary,
            uint64 start,
            uint64 cliff,
            uint64 duration,
            uint256 amountTotal,
            uint256 amountClaimed,
            uint256 slicePeriodSeconds,
            uint64 scheduleIndex,
            bool revocable,
            bool revoked
        ) = vesting.vestingSchedules(beneficiary, 0);

        assertEq(start, 1704067200);
        assertEq(cliff, 1706745600);
        assertEq(duration, 31536000);
        assertEq(amountTotal, 1000 ether);
        assertEq(amountClaimed, 0);
        assertEq(revocable, true);
        assertEq(revoked, false);
        assertEq(scheduleBeneficiary, beneficiary);
        assertEq(slicePeriodSeconds, 123);
        assertEq(scheduleIndex, 0);
    }

    function test_claim() public {
        vm.prank(owner);
        vesting.createVestingSchedule(
        beneficiary,
        1704067200,  
        1706745600,  
        31536000,    
        1000 ether, 
        123,         
        0,           
        true         
        );
        (
            address scheduleBeneficiary,
            uint64 start,
            uint64 cliff,
            uint64 duration,
            uint256 amountTotal,
            uint256 amountClaimed,
            uint256 slicePeriodSeconds,
            uint64 scheduleIndex,
            bool revocable,
            bool revoked
        ) = vesting.vestingSchedules(beneficiary, 0);
        vm.warp(start + cliff + duration);
        vm.prank(beneficiary);
        vesting.claim(beneficiary);
        assertEq(token.balanceOf(beneficiary), 1000 ether);
    }

 function test_vestingclaim() public {
    vm.prank(owner);
    vesting.createVestingSchedule(
        beneficiary,
        1704067200,  //jan 1, 2024
        1706745600,  //feb 1, 2024 (cliff)
        31536000,    //365 days
        1000 ether, 
        123 ether,   
        0,           
        true         
    );

    //warp to midpoint after cliff
    vm.warp(1721174400); //july 17, 2024

    vm.prank(beneficiary);
    vesting.claim(beneficiary);

    assertEq(token.balanceOf(beneficiary), 561.5 ether);
    }

    function test_revoke() public {
        vm.prank(owner);
        vesting.createVestingSchedule(
            beneficiary,
            1704067200,
            1706745600,
            31536000,
            1000 ether,
            123 ether,
            0,
            true
        );
        vm.prank(owner);
        vesting.revokeVestingSchedule(beneficiary, 0);
        (
            address scheduleBeneficiary,
            uint64 start,
            uint64 cliff,
            uint64 duration,
            uint256 amountTotal,
            uint256 amountClaimed,
            uint256 tgeAmount,
            uint64 lockupPeriod,
            bool revocable,
            bool revoked
        ) = vesting.vestingSchedules(beneficiary, 0);
        // vm.prank(owner);
        // vesting.revokeVestingSchedule(beneficiary, 0);
        assertEq(revoked, true);
    }

    function test_estimateNextClaimTime() public {
        vm.prank(owner);
        vesting.createVestingSchedule(
            beneficiary,
            1704067200,
            1706745600,
            31536000,
            1000 ether,
            123 ether,
            0,
            true
        );
        vm.warp(1706745500);
        uint256 nextClaimTime = vesting.estimateNextClaimTime(beneficiary);
        assertEq(nextClaimTime, 1706745600);
    }

    function test_createVestingBatches() public {
        vm.prank(owner);
        address[] memory beneficiaries = new address[](1);
        beneficiaries[0] = beneficiary;
        
        uint256[] memory starts = new uint256[](1);
        starts[0] = 1704067200;
        
        uint256[] memory cliffs = new uint256[](1);
        cliffs[0] = 1706745600;
        
        uint256[] memory durations = new uint256[](1);
        durations[0] = 31536000;
        
        uint256[] memory amountTotals = new uint256[](1);
        amountTotals[0] = 1000 ether;
        
        uint256[] memory tgeAmounts = new uint256[](1);
        tgeAmounts[0] = 123 ether;
        
        uint256[] memory lockupDurations = new uint256[](1);
        lockupDurations[0] = 0;
        
        bool[] memory revocables = new bool[](1);
        revocables[0] = true;
        
        vesting.createVestingBatches(
            beneficiaries,
            starts,
            cliffs,
            durations,
            amountTotals,
            tgeAmounts,
            lockupDurations,
            revocables
        );
        
        (
            address scheduleBeneficiary,
            uint64 start,
            uint64 cliff,
            uint64 duration,
            uint256 amountTotal,
            uint256 amountClaimed,
            uint256 tgeAmount,
            uint64 lockupPeriod,
            bool revocable,
            bool revoked
        ) = vesting.vestingSchedules(beneficiary, 0);
        assertEq(scheduleBeneficiary, beneficiary);
        assertEq(lockupPeriod, 0);
        assertEq(start, 1704067200);
        assertEq(cliff, 1706745600);
        assertEq(duration, 31536000);
        assertEq(amountTotal, 1000 ether);
        assertEq(amountClaimed, 0);
        assertEq(revocable, true);
        assertEq(revoked, false);   
    }


}
