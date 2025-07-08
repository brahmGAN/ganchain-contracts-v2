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
    mapping(address => uint256) public lockedBalances; 
    mapping(address => uint256) public unlockedBalances;
    uint256 public totalDeposited; 

    // Authorized orderbook service address
    address public orderbookAddress;

    
    // Events
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Unlock(address indexed user, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 timestamp);
    event OrderbookUpdated(address indexed oldOrderbook, address indexed newOrderbook);
    event LockedTransfer(address indexed from, address indexed to, uint256 amount, uint256 timestamp);

    // Modifiers
    modifier onlyOrderbook() {
        require(msg.sender == orderbookAddress, "GPUVault: Only Orderbook can call this");
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
        orderbookAddress = orderBook; 
    }

    function deposit(uint quantity,uint120[] memory tokenId) external nonReentrant validAmount(quantity)
    {
        if(quantity != tokenId.length) revert incorrectArraySize();
        if(!_ganNode.isApprovedForAll(msg.sender, address(this))) revert contractNotApproved();
        lockedBalances[msg.sender] += quantity;
        totalDeposited += quantity;
        for(uint i=0; i < quantity; i++) 
        {
            if(_ganNode.ownerOf(tokenId[i]) != msg.sender) revert NotTheTokenOwner();
            _tokenId.push(tokenId[i]);
            _ganNode.safeTransferFrom(msg.sender, address(this), tokenId[i]);
        }

        emit Deposit(msg.sender, quantity, block.timestamp);
    }

    function unlock(address user, uint256 amount) external onlyOrderbook validAmount(amount) 
    {
        require(lockedBalances[user] >= amount, "GAN-Node Vault: Insufficient locked balance");
        
        lockedBalances[user] -= amount;
        unlockedBalances[user] += amount;
        emit Unlock(user, amount, block.timestamp);
    }

    /**
     * @dev Transfer locked balance from one user to another (for cross-chain trading)
     * This enables User A's deposit to be withdrawn by User B after a trade
     * @param from User who is trading away their tokens
     * @param to User who is receiving the tokens  
     * @param amount Amount to transfer
     */
    function transferLocked(address from, address to, uint256 amount) external onlyOrderbook validAmount(amount) 
    {
        require(from != to, "GAN-Node Vault: Cannot transfer to self");
        require(lockedBalances[from] >= amount, "GAN-Node Vault: Insufficient locked balance");
        
        // Move locked balance from one user to another
        lockedBalances[from] -= amount;
        lockedBalances[to] += amount;
        
        emit LockedTransfer(from, to, amount, block.timestamp);
    }

    /**
     * @dev Combined transfer and unlock in one transaction (gas optimization)
     * Transfers locked balance from one user to another and immediately unlocks it
     * @param from User who is trading away their tokens
     * @param to User who will receive unlocked tokens
     * @param amount Amount to transfer and unlock
     */
    function transferAndUnlock(address from, address to, uint256 amount) external onlyOrderbook validAmount(amount) 
    {
        require(from != to, "GAN-Node Vault: Cannot transfer to self");
        require(lockedBalances[from] >= amount, "GPUVault: Insufficient locked balance");
        
        // Move locked balance from sender to receiver's unlocked balance
        lockedBalances[from] -= amount;
        unlockedBalances[to] += amount;
        
        emit LockedTransfer(from, to, amount, block.timestamp);
        emit Unlock(to, amount, block.timestamp);
    }

    //todo
    /**
     * @dev Withdraw unlocked native GPU tokens
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant validAmount(amount) 
    {
        require(unlockedBalances[msg.sender] >= amount, "GAN-Node Vault: Insufficient unlocked balance");
        if(_ganNode.balanceOf(address(this)) < amount) revert inSufficientBalanceInContract();

        unlockedBalances[msg.sender] -= amount;
        
        for(uint i = _tokenId.length-1; i >= amount; i--)
        {
            _ganNode.safeTransferFrom(address(this), msg.sender, _tokenId[i]);
        }
        
        emit Withdraw(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Set orderbook service address (only owner can call)
     * @param _orderbook Address of the orderbook service wallet
     */
    function setOrderbook(address _orderbook) external onlyOwner 
    {
        require(_orderbook != address(0), "GPUVault: Invalid orderbook address");
        
        address oldOrderbook = orderbookAddress;
        orderbookAddress = _orderbook;
        
        emit OrderbookUpdated(oldOrderbook, _orderbook);
    }
}