// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 
import "./interfaces/ISubnet.sol"; 

contract Subnet is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors,ISubnet 
{
    mapping(uint120 => uint120) public _subnetVotes; 

    address[] public _queens; 

    mapping(address => uint120) public _maxVotes; 

    mapping(address => uint120) public _userTotalVotes; 

    mapping(address => mapping(uint120 => uint120)) public _userVotesToSubnet;

    address public _updater; 

    mapping(address => uint120) public _pendingRewards; 

    mapping(address => uint120) public _totalRewardsClaimed; 

    mapping(address => bool) public _enrolledForQueen;

    bool public _createSubnets; 

    mapping(address => uint120) public _totalSubnetsHeld; 

    uint120 public _subnetId;

    mapping(uint120 => bool) public _subnetStatus; 

    mapping(uint120 =>  address) public _subnetKing;

    mapping(address => bool) public _enrolledForKing;

    address[] public _kings;

    bool public _deleteSubnets;

    bool public _createMultipleSubnets;

    mapping(address => uint120) _totalRewardsEarned;

    bool public _claimRewards;

    bool public _castVotes;

    bool public _unCastVotes;

    modifier onlyUpdater 
    {
        require(msg.sender == _updater, "You are not the authorized updater");
        _; 
    }
 
    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Initializes the contract with GPU contract address and rewards per day for the queen nodes pool.
    /// @dev `rewardsPerDay` should be passed in wei and not as GPoints 
    function initialize(address updater) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _updater = updater; 
    }

    function createSubnet() external 
    {
        if (!_createSubnets) revert createSubnetsNotYetAvailable();
        if (_totalSubnetsHeld[msg.sender] > 0)
        {
            if (!_createMultipleSubnets) revert cannotCreateMultipleSubnets();
            ++_subnetId;
            _subnetStatus[_subnetId] = true; 
            _subnetKing[_subnetId] = msg.sender; 
            ++_totalSubnetsHeld[msg.sender]; 
            if (!_enrolledForKing[msg.sender])
            {
                _kings.push(msg.sender); 
                _enrolledForKing[msg.sender] =  true; 
            } 
            //    todo emit event
        }
        else 
        {
            ++_subnetId;
            _subnetStatus[_subnetId] = true; 
            _subnetKing[_subnetId] = msg.sender; 
            ++_totalSubnetsHeld[msg.sender];
            if (!_enrolledForKing[msg.sender])
            {
                _kings.push(msg.sender); 
                _enrolledForKing[msg.sender] =  true; 
            } 
            //    todo emit event
        }
    }

    function deleteSubnet(uint88 subnetId) external 
    {
        if (!_deleteSubnets) revert deleteSubnetsNotYetAvailable();
        if (!_subnetStatus[subnetId]) revert subnetDeletedOrDoesntExist();
        if (_subnetKing[subnetId] != msg.sender) revert unauthorizedKing(); 
        _subnetStatus[subnetId] = false;
        --_totalSubnetsHeld[msg.sender];
        //    todo emit event
    }

    function claimRewards(uint120 rewards) external
    {
        if (!_claimRewards) revert claimRewardsNotYetAvailable();
        if(rewards > _pendingRewards[msg.sender]) revert exceedesPendingRewards();
        if((address(this).balance) < rewards) revert inSufficientBalanceInContract();
        _pendingRewards[msg.sender] -= rewards; 
        _totalRewardsClaimed[msg.sender] += rewards;
        (bool success,) = payable(msg.sender).call{value:rewards}("");
        if(!success) revert TransferFailed();  
        //todo emit event
    } 

    function castVotes(uint120[] calldata subnetId, uint120[] calldata votes, uint120 totalVotes) external 
    {
        if (!_castVotes) revert castVotesNotYetAvailable();
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
        if(!_enrolledForQueen[msg.sender]) {
            _queens.push(msg.sender);
            _enrolledForQueen[msg.sender] = true; 
        }
        //todo emit event
    }

    function unCastVotes(uint120[] calldata subnetId, uint120[] calldata votes, uint120 totalVotes) external 
    {
        if (!_unCastVotes) revert unCastVotesNotYetAvailable();
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

    function setQueenRewards(address[] calldata queens, uint88[] calldata queenRewards) external onlyOwner 
    {
        if (queens.length != queenRewards.length) revert incorrectArraySize(); 

        uint queensLength = queenRewards.length; 

        for (uint i=0; i < queensLength; i++)
        {
            _totalRewardsEarned[queens[i]] += queenRewards[i]; 
            _pendingRewards[queens[i]] += queenRewards[i];
        }

        //todo emit event
    }

    function setKingRewards(address[] calldata kings, uint88[] calldata kingRewards) external onlyOwner 
    {
        if (kings.length != kingRewards.length) revert incorrectArraySize(); 

        uint kingLength = kingRewards.length; 

        for (uint i=0; i < kingLength; i++)
        {
            _totalRewardsEarned[kings[i]] += kingRewards[i]; 
            _pendingRewards[kings[i]] += kingRewards[i]; 
        }

        //todo emit event    
    }

    /// @dev Set the status of the functions that users interact with. 
    function setUserFunctionStatus(bool status, uint8 functionType) external onlyOwner 
    {
        /// @dev sets the status of createSubnet(), functionType = 0
        if (functionType == 0) {
            _createSubnets = status;
        }
        
        /// @dev sets the status of deleteSubnet(), functionType = 1
        else if (functionType == 1) {
            _deleteSubnets = status;
        }

        /// @dev sets the status of _createMultipleSubnets, functionType = 2
        else if (functionType == 2) {
            _createMultipleSubnets = status;
        }

        /// @dev sets the status of _createMultipleSubnets, functionType = 3
        else if (functionType == 3) {
            _claimRewards = status;
        }

        /// @dev sets the status of _createMultipleSubnets, functionType = 4
        else if (functionType == 4) {
            _castVotes = status;
        }

        /// @dev sets the status of _createMultipleSubnets, functionType = 5
        else if (functionType == 5) {
            _unCastVotes = status;
        }

        else {
            revert wrongFunctionType(); 
        }
    }

    function authorizedRewardSender(address[] calldata users, uint120[] calldata rewards) external onlyOwner 
    {
        uint usersLength = users.length; 
        if(usersLength != rewards.length) revert incorrectArraySize();

        for(uint i=0; i < usersLength; i++)
        {
            if(rewards[i] > _pendingRewards[users[i]]) revert exceedesPendingRewards();
            if((address(this).balance) < rewards[i]) revert inSufficientBalanceInContract();
            _pendingRewards[users[i]] -= rewards[i]; 
            _totalRewardsClaimed[users[i]] += rewards[i];
            (bool success,) = payable(users[i]).call{value:rewards[i]}("");
            if(!success) revert TransferFailed(); 
        } 
        //todo emit event 
    }

    function setBatchSubnetsVotes(uint120[] calldata subnetId, uint120[] calldata votes) external onlyUpdater
    { 
        if(subnetId.length != votes.length) revert incorrectArraySize();
        uint totalSubnets = subnetId.length; 
        for(uint i=0; i < totalSubnets; i++)
        {
            _subnetVotes[subnetId[i]] = votes[i]; 
        }
        //todo emit timestamp
    }

    function setSubnetsVotes(uint120 subnetId, uint120 votes) external onlyUpdater
    {
        _subnetVotes[subnetId] = votes; 
        //todo emit timestamp
    }


    function setBatchUserMaxVotes(address[] calldata queens,uint120[] calldata maxVotes) external onlyUpdater
    {
        if (queens.length != maxVotes.length) revert incorrectArraySize(); 
        uint queensLength = queens.length; 
        for(uint i=0; i < queensLength; i++)
        {
            _maxVotes[queens[i]] = maxVotes[i];
        }
        //todo emit timestamp
    }

    function setUserMaxVotes(address queen,uint120 maxVotes) external onlyUpdater
    {
        _maxVotes[queen] = maxVotes; 
        //todo emit timestamp
    }
}