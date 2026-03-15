// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 

contract v1ValidatorRewards is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors 
{
    address public _updater; 

    mapping(address => uint) public _pendingRewards; 

    bool public _claimRewards; 

    mapping(address => uint) public _totalClaimedRewards;    

    mapping(address => uint) public _lastUpdateTime;
 
    modifier onlyUpdater 
    {
        require(msg.sender == _updater, "You are not the authorized updater");
        _; 
    }

    event claimedRewards
    (
        address validator,
        uint rewards,
        uint claimedRewardsAt
    );

    event setRewardsAt
    (
        address validator,
        uint rewards,
        uint timestamp
    );

    event setBatchRewardsAt
    (
        uint timestamp
    );

    event setClaimRewardsStatusAt
    (
        bool status, 
        uint timestamp
    );
 
    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function initialize(address updater) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _updater = updater; 
    }

    receive() external payable {}

    function claimRewards() public
    {
        uint pendingRewards = _pendingRewards[msg.sender]; 
        if(!_claimRewards) revert notYetAvailable();
        if(pendingRewards == 0) revert NothingToClaim();
        if(address(this).balance < pendingRewards) revert inSufficientBalanceInContract();

        _pendingRewards[msg.sender] = 0; 
        _totalClaimedRewards[msg.sender] += pendingRewards; 
        (bool success,) = payable(msg.sender).call{value:pendingRewards}("");
        if(!success) revert TransferFailed(); 

        emit claimedRewards(msg.sender, pendingRewards, block.timestamp);
    }

    function setPendingRewards(address nodeHolder, uint rewards) public onlyUpdater 
    {
        if(block.timestamp - _lastUpdateTime[nodeHolder] > 20 hours)
        {
            _pendingRewards[nodeHolder] += rewards; 
            _lastUpdateTime[nodeHolder] = block.timestamp;
            emit setRewardsAt(msg.sender, rewards, block.timestamp);
        }
    }

    function setBatchpendingRewards(address[] calldata nodeHolders, uint[] calldata rewards) public onlyUpdater 
    {
        uint totalNodeHolders = nodeHolders.length; 
        for(uint i=0; i < totalNodeHolders; i++)
        {
            if(block.timestamp - _lastUpdateTime[nodeHolders[i]] > 20 hours)
            {
                _pendingRewards[nodeHolders[i]] += rewards[i]; 
                _lastUpdateTime[nodeHolders[i]] = block.timestamp;
            }
        }
        emit setBatchRewardsAt(block.timestamp);
    }

    function setClaimRewardsStatus(bool status) public onlyOwner 
    {
        _claimRewards = status; 
        emit setClaimRewardsStatusAt(status,block.timestamp);
    }
}