// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 
import "./interfaces/ISubnetStaking.sol"; 

contract SubnetStaking is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors,ISubnetStaking {

    /// @dev Timestamp of the last queen rewards calculated at 
    uint40 public _lastQueenRewardsCalculatedAt; 

    /// @dev Timestamp of the last king rewards calculated at 
    uint40 public _lastKingRewardsCalculatedAt; 

    /// @dev The rewards set aside for the entire queen nodes pool per day 
    uint120 public _queenRewardsPerDay; 

    /// @dev The rewards set aside for the entire king nodes pool per day 
    uint120 _kingRewardsPerDay;  

    /// @dev Maps the amount staked by a particular queen 
    mapping(address => uint120) public _stakedAmount;

    /// @dev Total stakes in the staking pool
    uint120 public _totalStakes; 

    /// @dev Pending Queen's rewards 
    mapping(address => uint120) public _pendingQueenRewards;

    /// @dev Total earned rewards of the queen 
    mapping(address => uint120) public _totalRewardsEarned;

    /// @dev List of queens that stakes
    address[] public _queens; 

    /// @dev Checkes whether the user has already enrolled for the queen rewards
    mapping(address => bool) public _enrolledForQueen;

    /// @dev Boolean switch to control the availability of stake() 
    bool public _stake;

    /// @dev Boolean switch to control the availability of unStake()
    bool public _unStake;

    /// @dev Boolean switch to control the availability of claim()
    bool public _claim; 

    /// @dev Boolean switch that makes sure owner has called setCastedVotes
    bool public _accumulate; 

    /// @dev Mapping that stores the rewards claimed by a user so far
    mapping(address => uint120) public _totalRewardsclaimed; 

    mapping(address => uint120) public _unUsedStakes; 

    mapping(address => uint120) public _castedVotes;

    /// @dev Total earned rewards of the king 
    mapping(address => uint120) public _totalKingRewardsEarned;

    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Initializes the contract with GPU contract address and rewards per day for the queen nodes pool.
    /// @dev `rewardsPerDay` should be passed in wei and not as GPoints 
    function initialize(uint256 queenRewardsPerDay, uint256 kingRewardsPerDay) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        /// @todo set king and queen rewards
        _queenRewardsPerDay = uint120(queenRewardsPerDay);
        _kingRewardsPerDay = uint120(kingRewardsPerDay);
    }

    /// @notice No minimum staking amount 
    /// @dev Allows the users to stake and become a queen node.
    function stake() external  payable {
        if (!_stake) revert stakeNotYetAvailable(); 
        _totalStakes += uint96(msg.value); 
        _stakedAmount[msg.sender] += uint120(msg.value); 
        _unUsedStakes[msg.sender] += uint88(msg.value); 
        if(!_enrolledForQueen[msg.sender]) {
            _queens.push(msg.sender);
            _enrolledForQueen[msg.sender] = true; 
        }
        emit staked(msg.sender, uint88(msg.value));  
    }  

    /// @notice No rewards for staking below 1000 GPoints
    /// @dev Allows the queens to unstake 
    function unStake(uint120 amount) public {
        if (!_unStake) revert unStakeNotYetAvailable();
        if (amount == 0) revert ZeroUnstakeAmount();
        if (_unUsedStakes[msg.sender] < amount) revert ExceedsStakedAmount();
        _stakedAmount[msg.sender] -= amount; 
        _unUsedStakes[msg.sender] -= amount;    
        _totalStakes -= amount; 
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed(); 
        emit unStaked(msg.sender, amount);
    }

    /// @dev call this function first before accumulateDailyQueenRewards is called
    function setCastedVotes(address[] memory queens, uint88[] memory castedVotes) external onlyOwner {
        /// @todo merge this with accumulate queen rewards 
        /// @todo stress test this with 100 queens 
        
        if (queens.length != castedVotes.length) revert incorrectArraySize();

        uint96 skipped; 

        for(uint i = 0; i < queens.length; i++) 
        {

            if (_enrolledForQueen[queens[i]] && ((castedVotes[i] * 1 ether) <= _stakedAmount[queens[i]])) 
            {
                _castedVotes[queens[i]] = castedVotes[i]; 
                _unUsedStakes[queens[i]] = _stakedAmount[queens[i]] - (castedVotes[i] * 1 ether); 
            }
            else 
            {
                skipped++; 
            }
        } 

        _accumulate = true; 

        emit skippedQueens(skipped);
    }

    function accumulateDailyQueenRewards() public onlyOwner {

        if (!_accumulate) revert setCastedVote(); 

        address[] memory queens = _queens; 
        uint24 totalQueens = uint24(queens.length); 
        uint120[] memory stakeScores = new uint120[](totalQueens); 
        uint120 stakeMultiplier;  
        uint120 totalStakeScore;

        /// @dev Calculates the SS = su * sm 
        for (uint i = 0; i < totalQueens; i++) {

                
                if (_stakedAmount[queens[i]] <= 1e20) {
                    stakeMultiplier = 100; 
                }
                else if (_stakedAmount[queens[i]] <= 1e21) {
                    stakeMultiplier = 125;  
                }
                else if (_stakedAmount[queens[i]] <= 7e21) {
                    stakeMultiplier = 150; 
                }
                else if (_stakedAmount[queens[i]] <= 25e21) {
                    stakeMultiplier = 175; 
                }
                else {
                    stakeMultiplier = 200; 
                }

                stakeScores[i] = _castedVotes[queens[i]] * stakeMultiplier;

                /// @dev ∑SS
                totalStakeScore += stakeScores[i]; 
        }

        /// @dev This check makes sure rewards are handed out only if validators and queens are still setup. It's done as the first step of the loop.
        /// @dev If this check fails then we iterate to the next address.  
        /// @dev Calculates the queen rewards 
        /// @dev (ss/∑ss) * Rewards per day
        if (totalStakeScore > 0) {
            uint256 rewardsPerDay = _queenRewardsPerDay;
            uint96 newRewards; 
            for (uint i = 0; i < totalQueens; i++) {
                /// @dev queen rewards = (ss * _queenRewardsPerDay) / ∑SS
                newRewards = uint96((stakeScores[i] * rewardsPerDay) / (totalStakeScore));
                // _pendingQueenRewards[queens[i]] +=  newRewards; 
                _totalRewardsEarned[queens[i]] += newRewards; 
                _totalStakes += newRewards; 
                _stakedAmount[queens[i]] += uint88(newRewards); 
                _unUsedStakes[queens[i]] += uint88(newRewards); 
            } 
        }
        _lastQueenRewardsCalculatedAt = uint40(block.timestamp); 
        _accumulate = false; 
        emit accumulatedDailyQueenRewards(_lastQueenRewardsCalculatedAt);
    }

    function setQueenRewards(address[] memory queens, uint88[] memory queenRewards) external onlyOwner 
    {
        /// @todo stress test this with 100 queens
        if (queens.length != queenRewards.length) revert incorrectArraySize(); 

        uint queensLength = queenRewards.length; 

        for (uint i=0; i < queensLength; i++)
        {
            _totalRewardsEarned[queens[i]] += queenRewards[i]; 
            _totalStakes += queenRewards[i]; 
            _stakedAmount[queens[i]] += queenRewards[i]; 
            _unUsedStakes[queens[i]] += queenRewards[i]; 
        }

        _lastQueenRewardsCalculatedAt = uint40(block.timestamp); 

        emit setQueenReward(_lastQueenRewardsCalculatedAt);
    }

    /// @dev set the rewards per day for queen's
    function setQueenRewardsPerDay(uint120 queenRewardsPerDay) external onlyOwner {
        _queenRewardsPerDay = queenRewardsPerDay;  
    }

    function setKingRewardsPerDay(uint120 kingRewardsPerDay) external onlyOwner {
        _kingRewardsPerDay = kingRewardsPerDay;  
    }

    /// @dev Set the status of the functions that users interact with. 
    function setUserFunctionStatus(bool status, uint8 functionType) external onlyOwner {

        /// @dev sets the status of stake(), functionType = 0
        if (functionType == 0) {
            _stake = status; 
        }

        /// @dev sets the status of unStake(), functionType = 1
        else if (functionType == 1) {
            _unStake = status;
        }

        // /// @dev sets the status of createSubnet(), functionType = 2
        // else if (functionType == 2) {
        //     _createSubnets = status;
        // }
        
        // /// @dev sets the status of deleteSubnet(), functionType = 3
        // else if (functionType == 3) {
        //     _deleteSubnets = status;
        // }

        // /// @dev sets the status of _createMultipleSubnets, functionType = 4
        // else if (functionType == 4) {
        //     _createMultipleSubnets = status;
        // }

        else {
            revert wrongFunctionType(); 
        }
    }

    /// @dev Set the total rewards claimed by the queens so far 
    function setTotalRewardsClaimed(address queen, uint96 rewardsClaimed) external onlyOwner {
        _totalRewardsclaimed[queen] = rewardsClaimed; 
    }

    function authorizedUnstake(address queen) external onlyOwner {
        uint120 stakedAmount = _stakedAmount[msg.sender]; 

        //_pendingQueenRewards[msg.sender] = 0;
        //_totalRewardsclaimed[msg.sender] += rewards;

        _stakedAmount[queen] = 0;
        _totalStakes -= stakedAmount; 
        _unUsedStakes[queen] = 0; 

        (bool success,) = payable(queen).call{value: (stakedAmount)}("");
        if (!success) revert TransferFailed(); 
        emit authorizedUnStaked(queen, (stakedAmount));
    }

    /// @dev kingRewardsPerDay should be in wei
    function accumulateDailyKingRewards(address[] memory kings, uint120[] memory votesReceived,uint88 kingRewardsPerDay) external onlyOwner
    {
        /// @todo stress test this with 100 kings
        if (kings.length != votesReceived.length) revert incorrectArraySize();
        uint kingsLength = kings.length;
        uint totalVotes; 

        for(uint i=0; i < kingsLength; i++)
        {
            totalVotes += votesReceived[i]; 
        }

        if (totalVotes > 0)
        {

            uint96 kingRewards; 

            for(uint i=0; i < kingsLength; i++)
            {
                kingRewards = uint96((votesReceived[i] * kingRewardsPerDay) / (totalVotes));
                _totalKingRewardsEarned[kings[i]] += kingRewards; 
                _totalStakes += kingRewards; 
                _stakedAmount[kings[i]] += uint88(kingRewards); 
                _unUsedStakes[kings[i]] += uint88(kingRewards); 
            }
        }
        _lastKingRewardsCalculatedAt = uint40(block.timestamp);

        emit accumulatedDailyKingRewards(_lastKingRewardsCalculatedAt); 
    }

    function setKingRewards(address[] memory kings, uint88[] memory kingRewards) external onlyOwner 
    {
        /// @todo stress test this with 100 kings
        if (kings.length != kingRewards.length) revert incorrectArraySize(); 

        uint kingLength = kingRewards.length; 

        for (uint i=0; i < kingLength; i++)
        {
            _totalRewardsEarned[kings[i]] += kingRewards[i]; 
            _totalStakes += kingRewards[i]; 
            _stakedAmount[kings[i]] += kingRewards[i]; 
            _unUsedStakes[kings[i]] += kingRewards[i]; 
        }
        //TODO: emit timestamp for both king and queen

        _lastKingRewardsCalculatedAt = uint40(block.timestamp);

        emit setKingReward(_lastKingRewardsCalculatedAt);
    }
    // todo: reqrite tests accordingly and add more owner callable functions to set things directly 
}