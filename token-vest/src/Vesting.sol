// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract TokenVesting is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;

    constructor(address initialOwner, address _token) Ownable(initialOwner) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }
    
    struct VestingSchedule{
        address beneficiary;
        uint64 start;
        uint64 cliff;
        uint64 duration;
        uint256 amountTotal;
        uint256 amountClaimed;
        uint256 tgeAmount;
        uint64 lockupPeriod;
        bool revocable;
        bool revoked;
    }
    mapping(address => VestingSchedule[]) public vestingSchedules;

    event VestingScheduleCreated(
        address indexed beneficiary,
        uint64 start,
        uint64 cliff,
        uint64 duration,
        uint256 amountTotal,
        uint256 tgeAmount,
        uint64 lockupPeriod,
        bool revocable
    );
    function createVestingSchedule(address beneficiary, 
        uint64 start, 
        uint64 cliff, 
        uint64 duration,
        uint256 amountTotal, 
        uint256 tgeAmount, 
        uint64 lockupPeriod, 
        bool revocable
    ) external onlyOwner {
        // require(vestingSchedules[beneficiary].start==0,"Vesting schedule already exists");
        require(start>=block.timestamp,"Start time must be in the future");
        require(cliff>=start,"Cliff must be after start");
        require(duration>0,"duration should be greater than 0");
        require(amountTotal>0,"amountTotal should be greater than 0");
        if(tgeAmount>0){
            require(tgeAmount<=amountTotal,"tgeAmount should be less than or equal to amountTotal");
        }
        if(lockupPeriod>0){
            require(lockupPeriod<=duration,"lockupPeriod should be less than or equal to duration");
        }
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), amountTotal);

        vestingSchedules[beneficiary].push(VestingSchedule({
            beneficiary: beneficiary,
            start: start,
            cliff: cliff,
            duration: duration,
            amountTotal: amountTotal,
            amountClaimed: 0,
            tgeAmount: tgeAmount,
            lockupPeriod: lockupPeriod,
            revocable: revocable,
            revoked: false
        }));
        emit VestingScheduleCreated(
            beneficiary,
            start,
            cliff,
            duration,
            amountTotal,
            tgeAmount,
            lockupPeriod,
            revocable
        );
    }

    event Claimed(
            address indexed beneficiary,
            uint256 amount
        );

    function claim(address beneficiary) external nonReentrant whenNotPaused {
        VestingSchedule[] storage schedule = vestingSchedules[beneficiary];
        require(msg.sender==beneficiary,"Only beneficiary can claim");
        require(schedule.length > 0,"No vesting schedules found");
        uint256 totalClaimed = 0;
        for(uint256 i=0;i<schedule.length;i++){
            if(schedule[i].start==0) continue; 
            if(schedule[i].revoked) continue; 
            if(block.timestamp<schedule[i].start) continue; 
            if(block.timestamp<schedule[i].cliff) continue; 
            uint256 amount = _claimableAmount(schedule[i]);
            if(amount > 0) {
                schedule[i].amountClaimed+=amount;
                totalClaimed += amount;
            }
        }
        require(totalClaimed > 0, "no amount to claim");
        SafeERC20.safeTransfer(token,msg.sender,totalClaimed);
        emit Claimed(msg.sender,totalClaimed);
    }

    function _claimableAmount(VestingSchedule storage schedule) internal view returns (uint256) {
        if(schedule.revocable && schedule.revoked){
            return 0;
        }
        if(block.timestamp<schedule.start){
            return 0;
        }
        uint256 totalVested;
        uint256 elapsed = block.timestamp - schedule.start;

        //tge unlocked immediately
        if(elapsed<schedule.lockupPeriod){
            return 0;
        }
        totalVested += schedule.tgeAmount;

        //if past cliff, unlock the rest of the tokens
        if(block.timestamp>=schedule.cliff){
            uint256 timeAfterCliff = block.timestamp - schedule.cliff;
            uint256 vestingDurationAfterCliff = schedule.duration - (schedule.cliff - schedule.start);
            if(timeAfterCliff>vestingDurationAfterCliff){
                    timeAfterCliff = vestingDurationAfterCliff;
            }

        uint256 linearVested = (schedule.amountTotal - schedule.tgeAmount) * timeAfterCliff / vestingDurationAfterCliff;
        totalVested += linearVested;        
        }

        //subtract if claimed
        if(totalVested<schedule.amountClaimed){
            return 0;
        }
        return totalVested - schedule.amountClaimed;
    }

    function getClaimableAmounts(address _user) public view returns (uint256) {
        VestingSchedule[] storage schedule = vestingSchedules[_user];
        uint256 totalClaimable = 0;
        for(uint256 i=0;i<schedule.length;i++){
            totalClaimable += _claimableAmount(schedule[i]);
        }
        return totalClaimable;
    }

    event UnusedTokensWithdrawn(
        address indexed to,
        uint256 amount
    );
    function withdrawUnusedTokens(address to, uint256 amount) external onlyOwner{
        require(to!=address(0),"Invalid address");
        require(amount>0,"Invalid amount");
        SafeERC20.safeTransfer(token,to,amount);
        emit UnusedTokensWithdrawn(to,amount);
    }
    function getVestingSchedules(address _user) public view returns (VestingSchedule[] memory){
        return vestingSchedules[_user];
    }
    function revokeVestingSchedule(address _user, uint256 index) external onlyOwner{
        require(index<vestingSchedules[_user].length,"Invalid index");
        require(vestingSchedules[_user][index].revocable, "Schedule is not revocable");
        vestingSchedules[_user][index].revoked = true;
    }
    function pause() external onlyOwner{
        _pause();
    }
    function unpause() external onlyOwner{
        _unpause();
    }
    function estimateNextClaimTime(address _user) public view returns (uint256){
        VestingSchedule[] storage schedule = vestingSchedules[_user];
        require(schedule.length > 0, "No vesting schedules found");
        uint256 earliestTime = type(uint256).max;
        bool foundValidSchedule = false;
        
        for(uint256 i=0;i<schedule.length;i++){
            if(schedule[i].start==0) continue; 
            if(schedule[i].revoked) continue;
            
            foundValidSchedule = true;
            
            uint256 nextTime;
            if(block.timestamp<schedule[i].start){
                nextTime = schedule[i].start;
            } else if(block.timestamp<schedule[i].cliff){
                nextTime = schedule[i].cliff;
            } else if (block.timestamp >= schedule[i].start + schedule[i].duration) {
                nextTime = schedule[i].start + schedule[i].duration;
            } else {
                nextTime = block.timestamp + 1;
            }
            
            if(nextTime < earliestTime) {
                earliestTime = nextTime;
            }
        }
        
        require(foundValidSchedule, "No valid vesting schedules found");
        return earliestTime;
    }
    function getVestedAmounts(address _user) external view returns (uint256) {
        VestingSchedule[] storage schedule = vestingSchedules[_user];
        uint256 totalVested = 0;
        for(uint256 i=0;i<schedule.length;i++){
            totalVested += _claimableAmount(schedule[i]);
        }
        return totalVested;
    }

    function getTotalAmounts(address _user) external view returns (uint256) {
        VestingSchedule[] storage schedule = vestingSchedules[_user];
        uint256 totalAmount = 0;
        for(uint256 i=0;i<schedule.length;i++){
            totalAmount += schedule[i].amountTotal;
        }
        return totalAmount;
    }

    function createVestingBatches(
        address[] calldata beneficiaries,
        uint256[] calldata startTimes,
        uint256[] calldata cliffs,
        uint256[] calldata durations,
        uint256[] calldata totalAmounts,
        uint256[] calldata tgeAmounts,
        uint256[] calldata lockupDurations,
        bool[] calldata revocables
    ) external onlyOwner{
        uint256 len = beneficiaries.length;
        require(
            len == startTimes.length &&
            len == cliffs.length &&
            len == durations.length &&
            len == totalAmounts.length &&
            len == tgeAmounts.length &&
            len == lockupDurations.length &&
            len == revocables.length,
            "Invalid input lengths"
        );
        for(uint256 i=0; i<len; i++){
            address beneficiary = beneficiaries[i];
            require(beneficiary!=address(0),"Invalid beneficiary");
            require(vestingSchedules[beneficiary].length == 0, "Schedule exists");
            vestingSchedules[beneficiary].push(VestingSchedule({
            beneficiary: beneficiary,
            start: uint64(startTimes[i]),
            cliff: uint64(cliffs[i]),
            duration: uint64(durations[i]),
            amountTotal: totalAmounts[i],
            amountClaimed: 0,
            tgeAmount: tgeAmounts[i],
            lockupPeriod: uint64(lockupDurations[i]),
            revocable: revocables[i],
            revoked: false
            }));
            SafeERC20.safeTransferFrom(token, msg.sender, address(this), totalAmounts[i]);
        }
    }
}
