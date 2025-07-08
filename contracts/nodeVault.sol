// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GANNodeVault is OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, IErrors
{

    IERC721 public _ganNode; 

    uint120[] public _tokenId; 

    // User balances
    mapping(address => uint256) public unlockedBalances;
    uint256 public totalDeposited; 

    // Authorized orderbook service address
    address public orderbookHandler;

    bool public deposit; 

    bool  public withdraw; 
    
    // Events
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Unlock(address indexed user, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 timestamp);
    event OrderbookUpdated(address indexed oldOrderbook, address indexed newOrderbook);
    event LockedTransfer(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event setLockStatusAt(uint indexed lock,bool status,uint timestamp);

    // Modifiers
    modifier onlyOrderbookHandler() {
        require(msg.sender == orderbookHandler, "GPUVault: Only Orderbook handler can call this");
        _;
    } 
    
    modifier validAmount(uint256 amount) {
        require(amount > 0, "GPUVault: Amount must be greater than 0");
        _;
    }

    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function initialize(address ganNode, address orderBook) public initializer { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _ganNode = IERC721(ganNode);
        orderbookHandler = orderBook; 
    }

    function depositNode(uint quantity,uint120[] memory tokenId) external nonReentrant validAmount(quantity)
    {
        if(!deposit) revert notYetAvailable();
        if(quantity != tokenId.length) revert incorrectArraySize();
        if(!_ganNode.isApprovedForAll(msg.sender, address(this))) revert contractNotApproved();
        totalDeposited += quantity;
        for(uint i=0; i < quantity; i++) 
        {
            if(_ganNode.ownerOf(tokenId[i]) != msg.sender) revert NotTheTokenOwner();
            _tokenId.push(tokenId[i]);
            _ganNode.safeTransferFrom(msg.sender, address(this), tokenId[i]);
        }

        emit Deposit(msg.sender, quantity, block.timestamp);
    }

    function unlock(address user, uint256 amount) external onlyOrderbookHandler validAmount(amount) 
    {
        unlockedBalances[user] += amount;
        emit Unlock(user, amount, block.timestamp);
    }

    /**
     * @dev Withdraw unlocked native GPU tokens
     * @param amount Amount to withdraw
     */
    function withdrawNode(uint amount) external nonReentrant validAmount(amount) 
    {
        if(!withdraw) revert notYetAvailable();
        if(amount > unlockedBalances[msg.sender]) revert InsufficientUnlockedBalance();
        if(amount > _ganNode.balanceOf(address(this)) || amount > _tokenId.length) revert inSufficientBalanceInContract();

        unlockedBalances[msg.sender] -= amount;
        
        for(uint i = 0; i < amount; i++)
        {
            uint tokenIndex = _tokenId.length - 1;
            _ganNode.safeTransferFrom(address(this), msg.sender, _tokenId[tokenIndex]);
            _tokenId.pop(); 
        }
        
        emit Withdraw(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Set orderbook service address (only owner can call)
     * @param _orderbookHandler Address of the orderbook service wallet
     */
    function setOrderbook(address _orderbookHandler) external onlyOwner 
    {
        require(_orderbookHandler != address(0), "GPUVault: Invalid orderbook address");
        
        address oldOrderbook = orderbookHandler;
        orderbookHandler = _orderbookHandler;
        
        emit OrderbookUpdated(oldOrderbook, _orderbookHandler);
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