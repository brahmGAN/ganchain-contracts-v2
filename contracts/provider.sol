// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 

contract providers is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors 
{
    address public _updater; 

    bool public _registerProvider;

    mapping(address => bool) public _registered; 

    /// @dev get all the provider addresses
    address[] public _providers; 

    /// @dev total providers count. _providers.length makes this redundant
    uint120 public _totalProviders; 

    mapping(address => uint120) public _pendingRewards;

    mapping(address => uint120) public _totalRewards;

    bool public _claimAllRewards;

    bool public _claimRewards; 

    modifier onlyUpdater 
    {
        require(msg.sender == _updater, "You are not the authorized updater");
        _; 
    }

    event registeredProvider
    (
        address provider, 
        uint120 totalProviders,
        uint providerRegisteredAt
    );

    event claimedAllRewards
    (
        address provider, 
        uint120 claimedRewards, 
        uint timestamp
    );

    event claimedRewards
    (
        address provider, 
        uint120 claimedRewards, 
        uint timestamp
    );

    event setRewardsAt
    (
        address provider, 
        uint120 rewards, 
        uint timestamp
    );

    event setBatchRewardsAt
    (
        uint timestamp
    );

    event setLockStatusAt
    (
        uint lock,
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

    function registerProvider() public 
    {
        if(!_registerProvider) revert notYetAvailable();
        if(_registered[msg.sender]) revert providerExists();
        _providers.push(msg.sender);
        _registered[msg.sender] = true; 
        ++_totalProviders; 
        emit registeredProvider(msg.sender, _totalProviders, block.timestamp);
    }

    function claimAllRewards() public 
    {
        if(!_claimAllRewards) revert notYetAvailable();
        uint120 pendingRewards = _pendingRewards[msg.sender]; 
        if(address(this).balance < pendingRewards) revert inSufficientBalanceInContract();
        _pendingRewards[msg.sender] = 0; 
        (bool success,) = payable(msg.sender).call{value:pendingRewards}("");
        if(!success) revert TransferFailed();
        emit claimedAllRewards(msg.sender, pendingRewards, block.timestamp);
    }

    function claimRewards(uint120 rewards) public 
    {
        if(!_claimRewards) revert notYetAvailable();
        if(rewards > _pendingRewards[msg.sender]) revert exceedesPendingRewards();
        if(address(this).balance < rewards) revert inSufficientBalanceInContract();
        _pendingRewards[msg.sender] -= rewards; 
        (bool success,) = payable(msg.sender).call{value:rewards}("");
        if(!success) revert TransferFailed();
        emit claimedRewards(msg.sender, rewards, block.timestamp);
    }

    // function setTotalRewards(address provider, uint120 rewards) public onlyUpdater
    // {
    //     _totalRewards[provider] += rewards; 
    // }

    // function setBatchTotalRewards(address[] calldata provider, uint120[] calldata rewards) public onlyUpdater
    // {
    //     uint totalProviders = provider.length; 
    //     for(uint i=0; i < totalProviders; i++)
    //     {
    //         _totalRewards[provider[i]] += rewards[i]; 
    //     } 
    // } 

    function setRewards(address provider, uint120 rewards) public onlyUpdater
    {
        _pendingRewards[provider] += rewards; 
        _totalRewards[provider] += rewards; 
        emit setRewardsAt(provider, rewards, block.timestamp);
    }  

    function setBatchRewards(address[] calldata provider, uint120[] calldata rewards) public onlyUpdater
    {
        uint totalProviders = provider.length; 
        for(uint i=0; i < totalProviders; i++)
        {
            _pendingRewards[provider[i]] += rewards[i]; 
            _totalRewards[provider[i]] += rewards[i];
        } 
        emit setBatchRewardsAt(block.timestamp);
    } 

    function setLockStatus(bool status, uint lock) public onlyUpdater
    {
        if(lock == 0)
        {
            _registerProvider = status; 
        }
        else if(lock == 1)
        {
            _claimAllRewards = status; 
        }
        else if(lock == 2)
        {
            _claimRewards = status; 
        }
        else
        {
            revert wrongFunctionType();
        }

        emit setLockStatusAt(lock, status, block.timestamp);
    }
}