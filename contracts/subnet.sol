// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 
import "./interfaces/ISubnet.sol"; 

contract Subnet is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors,ISubnet 
{
    mapping(uint120 => uint120) _subnetVotes; 

    address[] _queens; 

    mapping(address => uint120) _maxVotes; 

    mapping(address => uint120) _userTotalVotes; 

    mapping(address => mapping(uint120 => uint120)) _userVotesToSubnet;
 
    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Initializes the contract with GPU contract address and rewards per day for the queen nodes pool.
    /// @dev `rewardsPerDay` should be passed in wei and not as GPoints 
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    // function createSubnet() external 
    // {
    //     if (!_createSubnets) revert createSubnetsNotYetAvailable();
    //     if (_totalSubnetsHeld[msg.sender] > 0)
    //     {
    //         if (!_createMultipleSubnets) revert cannotCreateMultipleSubnets();
    //         _subnetId++;
    //         _subnetStatus[_subnetId] = true; 
    //         _subnetKing[_subnetId] = msg.sender; 
    //         _totalSubnetsHeld[msg.sender]++; 
    //         if (!_enrolledForKing[msg.sender])
    //         {
    //             _kings.push(msg.sender); 
    //             _enrolledForKing[msg.sender] =  true; 
    //         } 
    //         emit createdSubnet(_subnetId, msg.sender);
    //     }
    //     else 
    //     {
    //         _subnetId++;
    //         _subnetStatus[_subnetId] = true; 
    //         _subnetKing[_subnetId] = msg.sender; 
    //         _totalSubnetsHeld[msg.sender]++;
    //         if (!_enrolledForKing[msg.sender])
    //         {
    //             _kings.push(msg.sender); 
    //             _enrolledForKing[msg.sender] =  true; 
    //         } 
    //         emit createdSubnet(_subnetId, msg.sender);
    //     }
        
    // }

    // function deleteSubnet(uint88 subnetId) external 
    // {
    //     if (!_deleteSubnets) revert deleteSubnetsNotYetAvailable();
    //     if (!_subnetStatus[subnetId]) revert subnetDeletedOrDoesntExist();
    //     if (_subnetKing[subnetId] != msg.sender) revert unauthorizedKing(); 
    //     _subnetStatus[subnetId] = false;
    //     emit deletedSubnet(subnetId, msg.sender);
    // }

    // function claimRewards(uint120 rewards) external
    // {
    //     //todo 
    // } 

    function castVotes(uint120[] calldata subnetId, uint120[] calldata votes, uint120 totalVotes) external 
    {
        if(subnetId.length != votes.length) revert incorrectArraySize();
        uint totalSubnets = subnetId.length; 
        if(_maxVotes[msg.sender] >= (totalVotes + _userTotalVotes[msg.sender])) revert insufficientBalanceToCastVotes();
        for(uint i=0; i < totalSubnets; i++)
        {
            _subnetVotes[subnetId[i]] += votes[i]; 
            _userVotesToSubnet[msg.sender][subnetId[i]] += votes[i];
        }
        _userTotalVotes[msg.sender] += totalVotes; 
        _maxVotes[msg.sender] -= totalVotes; 
        _queens.push(msg.sender); 
        //todo emit event
    }

    function unCastVotes(uint120[] calldata subnetId, uint120[] calldata votes, uint120 totalVotes) external 
    {
        if(subnetId.length != votes.length) revert incorrectArraySize();
        uint totalSubnets = subnetId.length; 
        if(totalVotes <= _userTotalVotes[msg.sender]) revert insufficientBalanceToRemoveVotes();
        for(uint i=0; i < totalSubnets; i++)
        {
            _subnetVotes[subnetId[i]] -= votes[i]; 
            _userVotesToSubnet[msg.sender][subnetId[i]] -= votes[i];
        }
        _userTotalVotes[msg.sender] -= totalVotes; 
        _maxVotes[msg.sender] += totalVotes; 
        //todo emit event
    }

    // function setQueenRewards(address[] calldata queens, uint88[] calldata queenRewards) external onlyOwner 
    // {
    //     //todo keep track of queen rewards individually and totally earned by all so far but use the same pool for rewards claiming whether one is a queen or a king
    //     if (queens.length != queenRewards.length) revert incorrectArraySize(); 

    //     uint queensLength = queenRewards.length; 

    //     for (uint i=0; i < queensLength; i++)
    //     {
    //         _totalRewardsEarned[queens[i]] += queenRewards[i]; 
    //         _totalStakes += queenRewards[i]; 
    //         _stakedAmount[queens[i]] += queenRewards[i]; 
    //         _unUsedStakes[queens[i]] += queenRewards[i]; 
    //     }

    //     _lastRewardCalculated = uint40(block.timestamp); 

    //     emit setQueenReward(_lastRewardCalculated);
    // }

    // function authorizedRewardSender(address user) external onlyOwner 
    // {
    //     //todo
    // }

    // function setKingRewards(address[] calldata kings, uint88[] calldata kingRewards) external onlyOwner 
    // {
    //     //todo keep track of king rewards individually and totally earned by all so far but use the same pool for rewards claiming whether one is a queen or a king
    //     if (kings.length != kingRewards.length) revert incorrectArraySize(); 

    //     uint kingLength = kingRewards.length; 

    //     for (uint i=0; i < kingLength; i++)
    //     {
    //         _totalRewardsEarned[kings[i]] += kingRewards[i]; 
    //         _totalStakes += kingRewards[i]; 
    //         _stakedAmount[kings[i]] += kingRewards[i]; 
    //         _unUsedStakes[kings[i]] += kingRewards[i]; 
    //     }

    //     _lastKingRewardsCalculatedAt = uint40(block.timestamp);

    //     emit setKingReward(_lastKingRewardsCalculatedAt);
    // }

    // /// @dev Set the status of the functions that users interact with. 
    // function setUserFunctionStatus(bool status, uint8 functionType) external onlyOwner {

    //     /// @dev sets the status of stake(), functionType = 0
    //     if (functionType == 0) {
    //         _stake = status; 
    //     }

    //     /// @dev sets the status of unStake(), functionType = 1
    //     else if (functionType == 1) {
    //         _unStake = status;
    //     }

    //     /// @dev sets the status of createSubnet(), functionType = 2
    //     else if (functionType == 2) {
    //         _createSubnets = status;
    //     }
        
    //     /// @dev sets the status of deleteSubnet(), functionType = 3
    //     else if (functionType == 3) {
    //         _deleteSubnets = status;
    //     }

    //     /// @dev sets the status of _createMultipleSubnets, functionType = 4
    //     else if (functionType == 4) {
    //         _createMultipleSubnets = status;
    //     }

    //     else {
    //         revert wrongFunctionType(); 
    //     }
    // }

    function setBatchSubnetsVotes(uint120[] calldata subnetId, uint120[] calldata votes) external onlyOwner
    { 
        if(subnetId.length != votes.length) revert incorrectArraySize();
        uint totalSubnets = subnetId.length; 
        for(uint i=0; i < totalSubnets; i++)
        {
            _subnetVotes[subnetId[i]] = votes[i]; 
        }
    }

    function setSubnetsVotes(uint120 subnetId, uint120 votes) external onlyOwner
    {
        _subnetVotes[subnetId] = votes; 
    }


    function setBatchUserMaxVotes(address[] calldata queens,uint120[] calldata maxVotes) external onlyOwner
    {
        if (queens.length != maxVotes.length) revert incorrectArraySize(); 
        uint queensLength = queens.length; 
        for(uint i=0; i < queensLength; i++)
        {
            _maxVotes[queens[i]] = maxVotes[i];
        }
    }

    function setUserMaxVotes(address queen,uint120 maxVotes) external onlyOwner
    {
        _maxVotes[queen] = maxVotes; 
    }
}