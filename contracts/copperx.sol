// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 

contract CopperxGPU is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors 
{
    bool public _releaseGpu; 

    address public _fundsHandler; 

    mapping(address => uint120) public _releasedAmount;  

    uint120 public _totalReleasedAmount; 

    event setLockStatusAt
    (
        uint indexed lock,
        bool indexed status,
        uint indexed timestamp
    );

    event releasedGpu 
    (
        address indexed receiver, 
        uint indexed timestamp, 
        uint120 indexed amount 
    );

    event fundsHandlerSet 
    (
        address indexed fundsHandler, 
        uint indexed timestamp
    );

    modifier onlyFundsHandler 
    {
        if(msg.sender != _fundsHandler) revert UnauthorizedFundsHandler();
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {} 
    
    function initialize(address fundsHandler) public initializer 
    { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _fundsHandler = fundsHandler; 
    }

    receive() external payable {} 

    function releaseGpu(uint120 amount, address receiver) public onlyFundsHandler nonReentrant 
    {
        if(!_releaseGpu) revert notYetAvailable();
        if(amount > address(this).balance) revert inSufficientBalanceInContract();
        _releasedAmount[receiver] += amount; 
        _totalReleasedAmount += amount; 
        (bool success,) = payable(receiver).call{value:amount}(""); 
        if(!success) revert TransferFailed(); 
        emit releasedGpu(receiver, block.timestamp, amount);
    }

    function setFundsHandler(address fundsHandler) public onlyOwner 
    {
        _fundsHandler = fundsHandler; 
        emit fundsHandlerSet(fundsHandler, block.timestamp);
    }
    
    function setLockStatus(bool status, uint lock) public onlyOwner
    {
        if(lock == 0)
        {
            _releaseGpu = status; 
        }
        else
        {
            revert wrongFunctionType();
        }

        emit setLockStatusAt(lock, status, block.timestamp);
    }
} 