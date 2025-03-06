// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 
import "./interfaces/IQueenStake.sol"; 
import "./GPU/GPU.sol";

contract OptimizedQueenStaking is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable, IErrors, IQueenStake {

    // State variables - tightly packed for efficient storage
    uint40 private _lastRewardCalculated; 
    uint40 private _lastKingRewardsCalculatedAt;
    bool public _openRewards;
    bool public _stake;
    bool public _unStake;
    bool public _claim;
    bool public _accumulate;
    bool public _createSubnets;
    bool public _deleteSubnets;
    bool private _createMultipleSubnets;

    uint88 public _rewardsPerDay;
    uint88 public _subnetId;
    uint96 private _totalStakes;

    // External contracts
    IERC721 public _nftContract;
    GPU public GPUInstance;

    // Mappings
    mapping(address => uint88) private _stakedAmount;
    mapping(address => uint96) private _pendingQueenRewards;
    mapping(address => uint96) private _totalRewardsEarned;
    mapping(address => bool) private _enrolledForQueen;
    mapping(address => uint96) private _totalRewardsclaimed;
    mapping(address => uint88) public _unUsedStakes;
    mapping(address => uint88) public _castedVotes;

    // Subnet mappings
    mapping(uint88 => bool) public _subnetStatus;
    mapping(uint88 => address) public _subnetKing;
    mapping(address => bool) private _enrolledForKing;
    mapping(address => uint16) private _totalSubnetsHeld;
    mapping(address => uint96) public _totalKingRewardsEarned;

    // Arrays
    address[] private _queens;
    address[] public _kings;

    // Constants to avoid magic numbers
    uint256 private constant MULTIPLIER_1 = 100;
    uint256 private constant MULTIPLIER_2 = 125;
    uint256 private constant MULTIPLIER_3 = 150;
    uint256 private constant MULTIPLIER_4 = 175;
    uint256 private constant MULTIPLIER_5 = 200;

    // Threshold constants for stake multipliers
    uint256 private constant THRESHOLD_1 = 1e20;
    uint256 private constant THRESHOLD_2 = 1e21;
    uint256 private constant THRESHOLD_3 = 7e21;
    uint256 private constant THRESHOLD_4 = 25e21;

    // Events
    event QueensSkipped(uint96 skipped);
    event KingsSkipped(uint96 skipped, uint40 timestamp);

    /// @dev Authorizes the upgrade to a new implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Initializes the contract
    function initialize(address gpuContract, address nftContract, uint256 rewardsPerDay) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _nftContract = IERC721(nftContract);
        _rewardsPerDay = uint88(rewardsPerDay);
        GPUInstance = GPU(gpuContract);
    }

    /// @dev Stake tokens to become a queen node
    function stake() external payable nonReentrant {
        if (!_stake) revert stakeNotYetAvailable(); 
        
        uint88 amount = uint88(msg.value);
        _totalStakes += amount; 
        _stakedAmount[msg.sender] += amount; 
        _unUsedStakes[msg.sender] += amount; 
        
        if(!_enrolledForQueen[msg.sender]) {
            _queens.push(msg.sender);
            _enrolledForQueen[msg.sender] = true; 
        }
        
        emit staked(msg.sender, amount);  
    }  

    /// @dev Allows queens to unstake
    function unStake(uint88 amount) external nonReentrant {
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

    /// @dev Create a subnet
    function createSubnet() external {
        if (!_createSubnets) revert createSubnetsNotYetAvailable();
        
        // Check if user already has subnets
        if (_totalSubnetsHeld[msg.sender] > 0 && !_createMultipleSubnets) {
            revert cannotCreateMultipleSubnets();
        }
        
        // Increment subnet ID
        uint88 newSubnetId = _subnetId + 1;
        _subnetId = newSubnetId;
        
        // Set subnet data
        _subnetStatus[newSubnetId] = true; 
        _subnetKing[newSubnetId] = msg.sender; 
        _totalSubnetsHeld[msg.sender]++; 
        
        // Enroll user as king if not already
        if (!_enrolledForKing[msg.sender]) {
            _kings.push(msg.sender); 
            _enrolledForKing[msg.sender] = true; 
        } 
        
        emit createdSubnet(newSubnetId, msg.sender);
    }

    /// @dev Delete a subnet
    function deleteSubnet(uint88 subnetId) external {
        if (!_deleteSubnets) revert deleteSubnetsNotYetAvailable();
        if (!_subnetStatus[subnetId]) revert subnetDeletedOrDoesntExist();
        if (_subnetKing[subnetId] != msg.sender) revert unauthorizedKing(); 
        
        _subnetStatus[subnetId] = false;
        emit deletedSubnet(subnetId, msg.sender);
    }

    /// @dev Transfer pending queen rewards to staked amount
    function transferPendingQueenRewardsToStaked() external onlyOwner {
        address[] memory queensRef = _queens;
        uint256 length = queensRef.length;
        
        for (uint256 i = 0; i < length;) {
            address queen = queensRef[i];
            uint96 pendingReward = _pendingQueenRewards[queen];
            
            if (pendingReward > 0) {
                _stakedAmount[queen] += uint88(pendingReward);
                _pendingQueenRewards[queen] = 0;
            }
            
            unchecked { ++i; }
        }
    }

    /// @dev Set casted votes
    function setCastedVotes(address[] calldata queens, uint88[] calldata castedVotes) external onlyOwner { 
        uint256 length = queens.length;
        if (length != castedVotes.length) revert incorrectArraySize();

        uint96 skipped; 

        for(uint256 i = 0; i < length;) {
            address queen = queens[i];
            uint88 votes = castedVotes[i];
            
            if (_enrolledForQueen[queen] && ((votes * 1 ether) <= _stakedAmount[queen])) {
                _castedVotes[queen] = votes; 
                _unUsedStakes[queen] = _stakedAmount[queen] - (votes * 1 ether); 
            } else {
                unchecked { ++skipped; }
            }
            
            unchecked { ++i; }
        } 

        _accumulate = true;
        emit skippedQueens(skipped);
    }

    /// @dev Accumulate daily queen rewards
    function accumulateDailyQueenRewards() external onlyOwner {
        if (!_accumulate) revert setCastedVote();

        address[] memory queensRef = _queens;
        uint256 length = queensRef.length;
        
        // Use memory for calculations
        uint96 totalStakeScore;
        uint256 rewardsPerDay = _rewardsPerDay;

        // First pass - calculate total stake score
        for (uint256 i = 0; i < length;) {
            address queen = queensRef[i];
            uint96 stakeMultiplier;
            uint88 votes = _castedVotes[queen];
            uint88 stakedAmount = _stakedAmount[queen];
            
            // Determine multiplier based on staked amount
            if (stakedAmount <= THRESHOLD_1) {
                stakeMultiplier = MULTIPLIER_1;
            } else if (stakedAmount <= THRESHOLD_2) {
                stakeMultiplier = MULTIPLIER_2;
            } else if (stakedAmount <= THRESHOLD_3) {
                stakeMultiplier = MULTIPLIER_3;
            } else if (stakedAmount <= THRESHOLD_4) {
                stakeMultiplier = MULTIPLIER_4;
            } else {
                stakeMultiplier = MULTIPLIER_5;
            }
            
            uint96 stakeScore = votes * stakeMultiplier;
            totalStakeScore += stakeScore;
            
            unchecked { ++i; }
        }

        // Second pass - distribute rewards
        if (totalStakeScore > 0) {
            for (uint256 i = 0; i < length;) {
                address queen = queensRef[i];
                uint96 stakeMultiplier;
                uint88 votes = _castedVotes[queen];
                uint88 stakedAmount = _stakedAmount[queen];
                
                // Recalculate multiplier (could store in memory array but may use more gas than recalculating)
                if (stakedAmount <= THRESHOLD_1) {
                    stakeMultiplier = MULTIPLIER_1;
                } else if (stakedAmount <= THRESHOLD_2) {
                    stakeMultiplier = MULTIPLIER_2;
                } else if (stakedAmount <= THRESHOLD_3) {
                    stakeMultiplier = MULTIPLIER_3;
                } else if (stakedAmount <= THRESHOLD_4) {
                    stakeMultiplier = MULTIPLIER_4;
                } else {
                    stakeMultiplier = MULTIPLIER_5;
                }
                
                uint96 stakeScore = votes * stakeMultiplier;
                uint96 newRewards = uint96((stakeScore * rewardsPerDay) / totalStakeScore);
                
                if (newRewards > 0) {
                    _totalRewardsEarned[queen] += newRewards;
                    _totalStakes += newRewards;
                    _stakedAmount[queen] += uint88(newRewards);
                    _unUsedStakes[queen] += uint88(newRewards);
                }
                
                unchecked { ++i; }
            }
        }
        
        _lastRewardCalculated = uint40(block.timestamp);
        _accumulate = false;
        emit accumulatedDailyQueenRewards(_lastRewardCalculated);
    }

    /// @dev Set queen rewards
    function setQueenRewards(address[] calldata queens, uint88[] calldata queenRewards) external onlyOwner {
        uint256 length = queens.length;
        if (length != queenRewards.length) revert incorrectArraySize();

        for (uint256 i = 0; i < length;) {
            address queen = queens[i];
            uint88 reward = queenRewards[i];
            
            _totalRewardsEarned[queen] += reward;
            _totalStakes += reward;
            _stakedAmount[queen] += reward;
            _unUsedStakes[queen] += reward;
            
            unchecked { ++i; }
        }

        _lastRewardCalculated = uint40(block.timestamp);
        emit setQueenReward(_lastRewardCalculated);
    }

    /// @dev Set open rewards status
    function setOpenRewards(bool status) external onlyOwner {
        _openRewards = status;
    }

    /// @dev Enroll validator for queen rewards
    function validatorRewardsEnroll(address validator) external onlyOwner {
        if (_openRewards && GPUInstance.isValidator(validator) && !_enrolledForQueen[validator]) {
            _queens.push(validator);
            _enrolledForQueen[validator] = true;
        }
        emit validatorEnrolled(validator);
    }

    /// @dev Set rewards per day
    function setRewardsPerDay(uint88 rewardsPerDay) external onlyOwner {
        _rewardsPerDay = rewardsPerDay;
    }

    /// @dev Set user function status
    function setUserFunctionStatus(bool status, uint8 functionType) external onlyOwner {
        if (functionType == 0) {
            _stake = status;
        } else if (functionType == 1) {
            _unStake = status;
        } else if (functionType == 2) {
            _createSubnets = status;
        } else if (functionType == 3) {
            _deleteSubnets = status;
        } else if (functionType == 4) {
            _createMultipleSubnets = status;
        } else {
            revert wrongFunctionType();
        }
    }

    /// @dev Set total rewards claimed
    function setTotalRewardsClaimed(address queen, uint96 rewardsClaimed) external onlyOwner {
        _totalRewardsclaimed[queen] = rewardsClaimed;
    }

    /// @dev Authorized unstake
    function authorizedUnstake(address queen) external onlyOwner {
        uint88 stakedAmount = _stakedAmount[queen];
        
        if (stakedAmount > 0) {
            _stakedAmount[queen] = 0;
            _totalStakes -= stakedAmount;
            _unUsedStakes[queen] = 0;
            
            (bool success,) = payable(queen).call{value: stakedAmount}("");
            if (!success) revert TransferFailed();
            
            emit authorizedUnStaked(queen, stakedAmount);
        }
    }

    /// @dev Accumulate daily king rewards
    function accumulateDailyKingRewards(
        address[] calldata kings, 
        uint120[] calldata votesReceived,
        uint88 kingRewardsPerDay
    ) external onlyOwner {
        uint256 length = kings.length;
        if (length != votesReceived.length) revert incorrectArraySize();

        uint96 skippedKings;
        uint256 totalVotes;

        // First pass - calculate total votes
        for (uint256 i = 0; i < length;) {
            if (_enrolledForKing[kings[i]]) {
                totalVotes += votesReceived[i];
            } else {
                unchecked { ++skippedKings; }
            }
            
            unchecked { ++i; }
        }

        // Second pass - distribute rewards
        if (totalVotes > 0) {
            for (uint256 i = 0; i < length;) {
                address king = kings[i];
                
                if (_enrolledForKing[king]) {
                    uint120 votes = votesReceived[i];
                    uint96 kingRewards = uint96((votes * kingRewardsPerDay) / totalVotes);
                    
                    if (kingRewards > 0) {
                        _totalKingRewardsEarned[king] += kingRewards;
                        _totalStakes += kingRewards;
                        _stakedAmount[king] += uint88(kingRewards);
                        _unUsedStakes[king] += uint88(kingRewards);
                    }
                }
                
                unchecked { ++i; }
            }
        }
        
        _lastKingRewardsCalculatedAt = uint40(block.timestamp);
        emit KingsSkipped(skippedKings, _lastKingRewardsCalculatedAt);
    }

    /// @dev Set king rewards
    function setKingRewards(address[] calldata kings, uint88[] calldata kingRewards) external onlyOwner {
        uint256 length = kings.length;
        if (length != kingRewards.length) revert incorrectArraySize();

        for (uint256 i = 0; i < length;) {
            address king = kings[i];
            uint88 reward = kingRewards[i];
            
            _totalRewardsEarned[king] += reward;
            _totalStakes += reward;
            _stakedAmount[king] += reward;
            _unUsedStakes[king] += reward;
            
            unchecked { ++i; }
        }

        _lastKingRewardsCalculatedAt = uint40(block.timestamp);
        emit setKingReward(_lastKingRewardsCalculatedAt);
    }

    // Getter functions
    function getLastRewardCalculated() external view onlyOwner returns(uint40) {
        return _lastRewardCalculated;
    }

    function getStakedAmount(address queen) external view onlyOwner returns(uint88) {
        return _stakedAmount[queen];
    }

    function getMyStakedAmount() external view returns(uint88) {
        return _stakedAmount[msg.sender];
    }

    function getTotalStakes() external view onlyOwner returns(uint96) {
        return _totalStakes;
    }

    function getQueenRewards(address queen) external view onlyOwner returns(uint96) {
        return _pendingQueenRewards[queen];
    }

    function getMyPendingRewards() external view returns(uint96) {
        return _pendingQueenRewards[msg.sender];
    }

    function getMyTotalRewardsEarned() external view returns(uint96) {
        return _totalRewardsEarned[msg.sender];
    }

    function getAllQueens() external view returns(address[] memory) {
        return _queens;
    }

    function getOpenRewardStatus() external view returns(bool) {
        return _openRewards;
    }

    function getTotalRewards(address queen) external view onlyOwner returns(uint96) {
        return _totalRewardsEarned[queen];
    }
}