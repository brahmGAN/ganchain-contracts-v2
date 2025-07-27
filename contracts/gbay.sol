// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol"; 
import "./interfaces/IErrors.sol"; 

contract GBayEscrow is OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, IErrors, ERC721HolderUpgradeable
{
    event orderCreated
    (
        address indexed seller, 
        uint120 indexed orderId, 
        uint120 indexed amount
    );

    event orderEscrowed 
    (
        address indexed buyer, 
        uint120 indexed amount, 
        uint indexed totalOrders
    );

    event orderCancelled 
    (
        address indexed buyer, 
        uint120 indexed orderId, 
        uint120 indexed amount
    );

    event orderCompleted 
    (
        address indexed seller, 
        address indexed buyer, 
        uint120 indexed orderId, 
        uint120 amount 
    );

    event escrowHandlerSet 
    (
        address indexed escrowHandler, 
        uint indexed timestamp 
    );

    event setLockStatusAt
    (
        uint indexed lock,
        bool status,
        uint timestamp
    );

    enum orderStatus 
    {
        orderCreated, 
        orderInProgress, 
        orderCompleted 
    }

    uint120 public _orderId; 
    address public _escrowHandler; 
    mapping(uint120 => uint120) public _orderAmount; 
    mapping(uint120 => address) public _seller; 
    mapping(uint120 => address) public _buyer; 
    mapping(uint120 => orderStatus) public _orderStatus; 
    bool public _createOrder;
    bool public _buyerDepositToEscrow; 
    bool public _cancelBuyOrder;
    bool public _buyerConfirmedAndRelease;

    modifier onlyEscrowHandler 
    {
        if(msg.sender != _escrowHandler) revert UnauthorizedEscrowHandler();
        _;
    }

    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function initialize(address escrowHandler) public initializer 
    { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        _escrowHandler = escrowHandler; 
    }

    receive() external payable {}

    /// @dev amount must be passed in wei
    function createOrder(uint120 amount) public 
    {
        uint120 orderId = _orderId; 
        _orderAmount[orderId] = amount; 
        _seller[orderId] = msg.sender; 
        _orderStatus[orderId] = orderStatus.orderCreated; 
        _orderId++; 
        emit orderCreated(msg.sender, orderId, amount);
    }

    ///@dev ensure the frontend doesn't let users buy products which already has a buyer lined up
    function buyerDepositToEscrow(uint120[] memory orderId,uint120[] memory amount) public payable 
    {
        uint totalAmount; 
        uint orderIdLength = orderId.length; 
        for(uint i=0; i < orderIdLength; i++)
        {
            if(_orderAmount[orderId[i]] != amount[i]) revert incorrectAmount(); 
            if(_orderStatus[orderId[i]] != orderStatus.orderCreated) revert BuyerPresentOrOrderCompleted();
            _buyer[orderId[i]] = msg.sender; 
            _orderStatus[orderId[i]] = orderStatus.orderInProgress; 
            totalAmount += amount[i]; 
        }
        if(msg.value != totalAmount) revert incorrectAmount();
        emit orderEscrowed(msg.sender, uint120(msg.value), orderIdLength);
    }

    function cancelBuyOrder(uint120 orderId) public 
    {
        if(_buyer[orderId] != msg.sender) revert NotTheBuyer(); 
        if(_orderStatus[orderId] != orderStatus.orderInProgress) revert OrderNotInProgess();
        uint120 amount = _orderAmount[orderId];
        _buyer[orderId] = address(0);
        _orderStatus[orderId] = orderStatus.orderCreated; 
        if(amount > address(this).balance) revert inSufficientBalanceInContract(); 
        (bool success,) = payable(msg.sender).call{value:amount}("");
        if(!success) revert TransferFailed(); 
        emit orderCancelled(msg.sender, orderId, amount);
    }

    function buyerConfirmedAndRelease(uint120 orderId) public 
    {
        if(_orderStatus[orderId] != orderStatus.orderInProgress) revert OrderNotInProgess(); 
        if(_buyer[orderId] != msg.sender) revert NotTheBuyer(); 
        uint120 amount = _orderAmount[orderId];
        address seller = _seller[orderId]; 
        if(amount > address(this).balance) revert inSufficientBalanceInContract(); 
        _orderStatus[orderId] = orderStatus.orderCompleted; 
        (bool success,) = payable(seller).call{value:amount}(""); 
        if(!success) revert TransferFailed();
        emit orderCompleted(seller, _buyer[orderId], orderId, amount);
    }

    function authorizedReleaseAmount(uint120 orderId) public onlyEscrowHandler
    {
        if(_orderStatus[orderId] != orderStatus.orderInProgress) revert OrderNotInProgess(); 
        uint120 amount = _orderAmount[orderId];
        address seller = _seller[orderId]; 
        if(amount > address(this).balance) revert inSufficientBalanceInContract(); 
        _orderStatus[orderId] = orderStatus.orderCompleted; 
        (bool success,) = payable(seller).call{value:amount}(""); 
        if(!success) revert TransferFailed();
        emit orderCompleted(seller, _buyer[orderId], orderId, amount);
    }

    function setEscrowHandler(address escrowHandler) public
    {
        _escrowHandler = escrowHandler; 
        emit escrowHandlerSet(escrowHandler, block.timestamp);
    }

    function setLockStatus(bool status, uint lock) public onlyOwner
    {
        if(lock == 0)
        {
             _createOrder = status; 
        }
        else if(lock == 1)
        {
             _buyerDepositToEscrow = status; 
        }
        else if(lock == 2)
        {
             _cancelBuyOrder = status; 
        }
        else if(lock == 3)
        {
             _buyerConfirmedAndRelease = status; 
        }
        else
        {
            revert wrongFunctionType();
        }

        emit setLockStatusAt(lock, status, block.timestamp);
    }
}