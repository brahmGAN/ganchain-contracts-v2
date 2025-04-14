// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

interface ISubnet 
{
    event createdSubnet(
        uint120 subnetId,
        address subnetKing,
        uint timeStamp 
    ); 
    event deletedSubnet(
        uint120 subnetId,
        address subnetKing,
        uint timeStamp  
    );
    event claimedRewards(
        address user, 
        uint120 rewardsClaimed
    );
}