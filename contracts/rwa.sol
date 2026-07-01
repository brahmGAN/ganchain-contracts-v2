// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract rwa is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors 
{
    uint public _dealAmount; 

    address public _dealExecutor; 

    address public _refundHandler; 

    bool public _deposit; 

    address[] public _liquidityProviders; 

    mapping(address => uint) public _depositAmount;  

    uint public _totalDealAmountRaised; 

    uint public _currentDealAmountRaised; 

    bool public _dealOver;  

    uint public _batchNumber; 

    using SafeERC20 for IERC20;
    IERC20 public _usdcToken; 

    event usdcDeposited
    (
        address user,
        uint amountDeposited, 
        uint timestamp 
    );

    event DealAmountReset
    (
        uint newDealAmount,
        uint timestamp
    );

    event DealClosed
    (
        uint timestamp
    );

    event DepositStatusSet
    (
        bool status,
        uint timestamp
    );

    event DealExecutorSet
    (
        address dealExecutor,
        uint timestamp
    );

    event RefundHandlerSet
    (
        address refundHandler,
        uint timestamp
    );

    modifier onlyRefundHandler  
    {
        require(msg.sender == _refundHandler, "Unauthorized refund handler");
        _;
    }
 
    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function initialize(address usdcToken, address refundHandler, address dealExecutor, uint dealAmount) public initializer { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _usdcToken = IERC20(usdcToken); 
        _refundHandler = refundHandler; 
        _dealExecutor = dealExecutor; 
        _dealAmount = dealAmount; 
        _deposit = true; 
        _batchNumber = 1;
    }

    receive() external payable {}

    function depositUsd(uint amount) public nonReentrant
    {
        if(!_deposit) revert notYetAvailable(); 
        if(amount < 1000000000) revert MinimumDeposit1k();
        if(_usdcToken.balanceOf(msg.sender) < amount) revert InsufficientBalance();
        if(_usdcToken.allowance(msg.sender, address(this)) < amount) revert ContractIsNotApproved();
        if((_currentDealAmountRaised + amount) > _dealAmount) revert ExceedesMaxDealLimit();
        if(_depositAmount[msg.sender] == 0)
        {
            _liquidityProviders.push(msg.sender);
        }
        _depositAmount[msg.sender] += amount;  
        _totalDealAmountRaised += amount;  
        _currentDealAmountRaised += amount;  
        _usdcToken.safeTransferFrom(msg.sender,_dealExecutor,amount);
        emit usdcDeposited(msg.sender, amount, block.timestamp);
    } 

    //function to reset _dealamount  
    function resetDealAmount(uint newDealAmount) public onlyOwner
    {
        _dealAmount = newDealAmount;
        _currentDealAmountRaised = 0;
        _batchNumber++;
        emit DealAmountReset(newDealAmount, block.timestamp);
    }

    //function to set the _deposit status
    function setDepositStatus(bool status) public onlyOwner
    {
        _deposit = status;
        emit DepositStatusSet(status, block.timestamp);
    }

    //function to set _dealExecutor address
    function setDealExecutor(address dealExecutor) public onlyOwner
    {
        _dealExecutor = dealExecutor;
        emit DealExecutorSet(dealExecutor, block.timestamp);
    }

    //function to set _refundHandler address
    function setRefundHandler(address refundHandler) public onlyOwner
    {
        _refundHandler = refundHandler;
        emit RefundHandlerSet(refundHandler, block.timestamp);
    }
} 