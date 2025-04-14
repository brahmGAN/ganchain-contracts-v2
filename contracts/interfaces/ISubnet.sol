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
    event castedVotes(
        address user, 
        uint timestamp
    );
    event unCastedVotes(
        address user, 
        uint timestamp
    );
    event setQueenRewards( 
        uint40 lastQueenRewardsCalculatedAt 
    );
    event setKingRewards( 
        uint40 lastKingRewardsCalculatedAt 
    );
}