// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";  
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IErrors.sol"; 

/**
 * @title USDTVault
 * @dev Enhanced vault contract for USDT with cross-user trading support
 * Handles deposits, locking, unlocking, withdrawals, and cross-user balance transfers
 */
contract USDTVault is OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, IErrors {

    using SafeERC20 for IERC20;
    
    IERC20 public usdtToken;

    uint120 public totalDeposited; 
    address public orderbookHandler;
    bool public _deposit; 
    bool public _withdraw;
    bool public _withdrawFor;

    mapping(address => uint120) public unlockedBalances;
    
    // Events
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Unlock(address indexed user, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 timestamp);
    event WithdrawFor(address indexed user, uint256 amount, uint256 timestamp);
    event OrderbookUpdated(address indexed oldOrderbook, address indexed newOrderbook);
    event LockedTransfer(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event setLockStatusAt(uint indexed lock,bool status,uint timestamp);

    // Modifiers
    modifier onlyOrderbook() {
        require(msg.sender == orderbookHandler, "USDTVault: Only Orderbook can call this");
        _;
    }
    
    modifier validAmount(uint256 amount) {
        require(amount > 0, "USDTVault: Amount must be greater than 0");
        _;
    }

    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function initialize(address _usdtToken, address _orderbookHandler) public initializer { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        require(_usdtToken != address(0), "USDTVault: invalid USDT token address");
        usdtToken = IERC20(_usdtToken);
        orderbookHandler = _orderbookHandler;
    }

    /**
     * @dev Deposit USDT tokens to the vault
     * @dev Pass the amount as the (decimal value * 10**6)
     * @param amount Amount of USDT to deposit
     */
    function depositUsdt(uint120 amount) external nonReentrant validAmount(amount)
    {
        if(!_deposit) revert notYetAvailable();
        if(usdtToken.allowance(msg.sender, address(this)) < amount) revert ContractIsNotApproved();
        totalDeposited += amount;
        usdtToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Unlock tokens for withdrawal (standard unlock).Amount is passed in wei
     * @param user User address to unlock funds for
     * @param amount Amount to unlock: Pass the amount as the (decimal value * 10**6)
     */
    function unlock(address user, uint120 amount) external onlyOrderbook validAmount(amount) 
    {   
        unlockedBalances[user] += amount;
        emit Unlock(user, amount, block.timestamp);
    }

    /**
     * @dev Withdraw unlocked USDT tokens
     * @param amount Amount to withdraw
     */
    function withdrawUsdt(uint120 amount) external nonReentrant validAmount(amount) 
    {
        if(!_withdraw) revert notYetAvailable();
        if(amount > unlockedBalances[msg.sender]) revert InsufficientUnlockedBalance();
        if(amount > usdtToken.balanceOf(address(this))) revert inSufficientBalanceInContract();
        unlockedBalances[msg.sender] -= amount;
        usdtToken.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, block.timestamp);
    }

    function withdrawUsdtFor(address user,uint120 amount) external nonReentrant validAmount(amount) onlyOrderbook
    {
        if(!_withdrawFor) revert notYetAvailable();
        if(amount > usdtToken.balanceOf(address(this))) revert inSufficientBalanceInContract();
        usdtToken.safeTransfer(user, amount);
        emit WithdrawFor(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Set orderbook service address (only owner can call)
     * @param _orderbook Address of the orderbook service wallet
     */
    function setOrderbook(address _orderbook) external onlyOwner {
        require(_orderbook != address(0), "USDTVault: Invalid orderbook address");
        
        address oldOrderbook = orderbookHandler;
        orderbookHandler = _orderbook;
        
        emit OrderbookUpdated(oldOrderbook, _orderbook);
    }

    function setLockStatus(bool status, uint lock) public onlyOwner
    {
        if(lock == 0)
        {
            _deposit = status; 
        }
        else if(lock == 1)
        {
            _withdraw = status; 
        }
        else if(lock == 2)
        {
            _withdrawFor = status; 
        }
        else
        {
            revert wrongFunctionType();
        }

        emit setLockStatusAt(lock, status, block.timestamp);
    }
}