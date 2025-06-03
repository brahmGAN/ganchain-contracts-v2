// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 

contract GpuBridge is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors 
{
    address[] public _gpuLockers; 

    uint120 public _lockId; 

    mapping(uint120 => address) public _lockedUser; 

    mapping(uint120 => mapping(address => uint)) public _lockedAmount; 

    bool public _lockGpu; 

    event lockedGpu
    (
        address user,
        uint amountLocked, 
        uint120 lockId 
    );

    event setLockStatusAt
    (
        uint lock, 
        bool status, 
        uint timestamp
    );
 
    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    receive() external payable {}

    function lockGpu() public payable 
    {
        if(!_lockGpu) revert notYetAvailable(); 
        uint120 lockId = _lockId; 
        _lockedUser[lockId] = msg.sender;
        _lockedAmount[lockId][msg.sender] = msg.value; 
        _lockId++; 
        _gpuLockers.push(msg.sender); 
        emit lockedGpu(msg.sender, msg.value, lockId);
    }
    
    function setLockStatus(bool status, uint lock) public onlyOwner
    {
        if(lock == 0)
        {
            _lockGpu = status; 
        }
        else
        {
            revert wrongFunctionType();
        }

        emit setLockStatusAt(lock, status, block.timestamp);
    }
} 