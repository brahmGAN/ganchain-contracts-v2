// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol"; 
import "./interfaces/IErrors.sol"; 

/**
 * @title GPUVault
 * @dev Enhanced vault contract for native GPU tokens with cross-user trading support
 * Handles deposits, locking, unlocking, withdrawals, and cross-user balance transfers
 */
contract GPUVault is OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, IErrors 
{
    // User balances
    mapping(address => uint120) public unlockedBalances;

    uint120 public totalDeposited; 

    // Authorized orderbook service address
    address public orderbookHandler;

    bool public deposit; 

    bool public withdraw;

    // Events
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Unlock(address indexed user, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 timestamp);
    event OrderbookUpdated(address indexed oldOrderbook, address indexed newOrderbook);
    event LockedTransfer(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event setLockStatusAt(uint indexed lock,bool status,uint timestamp);

    // Modifiers
    modifier onlyOrderbook() {
        require(msg.sender == orderbookHandler, "GPUVault: Only Orderbook can call this");
        _;
    }
    
    modifier validAmount(uint256 amount) {
        require(amount > 0, "GPUVault: Amount must be greater than 0");
        _;
    }

    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function initialize(address _orderbookHandler) public initializer 
    { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        orderbookHandler = _orderbookHandler;
    }

    /**
     * @dev Fallback function to receive native tokens
     * Note: Direct sends will not credit user balances - use deposit() function
     */
    receive() external payable {
        // Allow contract to receive native tokens but don't credit to any user
        // Users must use deposit() function to get credited balances
    }

    /**
     * @dev Deposit native GPU tokens to the vault
     * Amount is sent as msg.value
     */
    function depositGpu() external payable nonReentrant validAmount(msg.value)
    {
        if(!deposit) revert notYetAvailable();
        totalDeposited += uint120(msg.value);

        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev Unlock tokens for withdrawal (standard unlock)
     * @param user User address to unlock funds for
     * @param amount Amount to unlock
     */
    function unlock(address user, uint256 amount) external onlyOrderbook validAmount(amount) 
    {
        unlockedBalances[user] += uint120(amount);
        emit Unlock(user, amount, block.timestamp);
    }

    /**
     * @dev Withdraw unlocked native GPU tokens
     * @param amount Amount to withdraw in wei
     */
    function withdrawGpu(uint120 amount) external nonReentrant validAmount(amount) 
    {
        if(!withdraw) revert notYetAvailable();
        if(amount > unlockedBalances[msg.sender]) revert InsufficientUnlockedBalance();
        if(amount > address(this).balance) revert inSufficientBalanceInContract();
        unlockedBalances[msg.sender] -= amount;
        
        // Transfer native tokens back to user
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if(!success) revert TransferFailed();
        
        emit Withdraw(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Set orderbook service address (only owner can call)
     * @param _orderbookHandler Address of the orderbook service wallet
     */
    function setOrderbookHandler(address _orderbookHandler) external onlyOwner 
    {
        require(_orderbookHandler != address(0), "GPUVault: Invalid orderbook address");
        
        address oldOrderbookHandler = orderbookHandler;
        orderbookHandler = _orderbookHandler;
        
        emit OrderbookUpdated(oldOrderbookHandler, _orderbookHandler);
    }

    function setLockStatus(bool status, uint lock) public onlyOwner
    {
        if(lock == 0)
        {
            deposit = status; 
        }
        else if(lock == 1)
        {
            withdraw = status; 
        }
        else
        {
            revert wrongFunctionType();
        }

        emit setLockStatusAt(lock, status, block.timestamp);
    }
}