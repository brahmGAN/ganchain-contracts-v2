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
    event setQueenRewardsAt( 
        uint lastQueenRewardsCalculatedAt 
    );
    event setKingRewardsAt( 
        uint lastKingRewardsCalculatedAt 
    );
    event authorizedRewardSent(
        uint timestamp
    );
    event setBatchSubnetsVotesAt(
        uint _setBatchSubnetsVotesAt
    );
    event setBatchUserMaxVotesAt(
        uint _setBatchUserMaxVotesAt
    );
    event setBatchUserCastedVotesAt(
        uint _setBatchUserCastedVotesAt
    );
    event setBatchUserVotesToSubnetAt(
        uint _setBatchUserVotesToSubnetAt
    );
    event setSubnetsVotesAt(
        uint timestamp
    );
    event setUserMaxVotesAt(
        uint timestamp
    );
    event setUserCastedVotesAt(
        uint timestamp
    );
    event setUserVotesToSubnetAt(
        uint timestamp
    );
}