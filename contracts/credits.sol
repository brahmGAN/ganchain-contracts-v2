// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 

contract credits is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors 
{
    address public _fundsHandler;

    mapping(string => uint120) public _idStatus;

    bool public _buyCredits;

    event creditsPurchased
    (
        address user,
        uint120 amount,
        string id,
        uint  timestamp
    );

    event setLockStatusAt
    (
        uint lock, 
        bool status, 
        uint timestamp 
    );

    event fundsHandlerSet 
    (
        address indexed fundsHandler, 
        uint indexed timestamp
    );
 
    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function initialize(address fundsHandler) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _fundsHandler = fundsHandler; 
    }

    //receive() external payable {}

    function buyCredits(uint120 amount,string memory id) public payable nonReentrant 
    {
        if(!_buyCredits) revert notYetAvailable();
        if(amount < 1 || uint120(msg.value) != amount) revert incorrectAmount();
        if(_idStatus[id] > 0) revert IdAlreadyUsed();
        _idStatus[id] = uint120(msg.value); 
        (bool success,) = payable(_fundsHandler).call{value:msg.value}("");
        if(!success) revert TransferFailed();
        emit creditsPurchased(msg.sender, uint120(msg.value), id, block.timestamp);
    }

    function setFundsHandler(address fundsHandler) public onlyOwner 
    {
        _fundsHandler = fundsHandler; 
        emit fundsHandlerSet(fundsHandler, block.timestamp);
    }

    function setLockStatus(bool status,uint lock) public onlyOwner 
    {
        if(lock == 1)
        {
            _buyCredits = status; 
        }
        else 
        {
            revert wrongFunctionType();
        }
        emit setLockStatusAt(lock, status, block.timestamp);
    }
}