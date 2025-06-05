// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GanChainBridge is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors 
{
    address[] public _gpuLockers; 

    address[] public _releaseRecipients; 

    uint120 public _lockId; 

    uint120 public _releaseId; 

    mapping(uint120 => address) public _lockedUser; 

    mapping(uint120 => uint) public _lockedAmount; 

    mapping(uint120 => address) public _releasedUser; 

    mapping(uint120 => uint) public _releasedAmount; 

    bool public _lockGpu; 

    mapping(address => bool) public _isRelayer; 

    using SafeERC20 for IERC20;
    IERC20 public _gpuToken; 

    event lockedGpu
    (
        address user,
        uint amountLocked, 
        uint120 lockId 
    );

    event releasedGpu
    (
        address user,
        uint amountReleased, 
        uint120 releaseId 
    );

    event setLockStatusAt
    (
        uint lock, 
        bool status, 
        uint timestamp
    );

    event setRelayersStatusAt
    (
        uint timestamp
    );

    modifier onlyRelayer 
    {
        require(_isRelayer[msg.sender] == true, "Unauthorized relayer");
        _;
    }
 
    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function initialize(address gpuToken) public initializer { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _gpuToken = IERC20(gpuToken); 
    }

    receive() external payable {}

    function lockGpu(uint amount) public  
    {
        if(!_lockGpu) revert notYetAvailable(); 
        uint120 lockId = _lockId; 
        _lockedUser[lockId] = msg.sender;
        _lockedAmount[lockId] = amount; 
        _lockId++; 
        _gpuLockers.push(msg.sender); 
        _gpuToken.safeTransferFrom(msg.sender,address(this),amount);
        emit lockedGpu(msg.sender, amount, lockId);
    }

    /// @notice `amount` should be passed in wei
    function releaseGpu(uint amount, address receiver) public onlyRelayer
    {
            if(_gpuToken.balanceOf(address(this)) < amount) revert inSufficientBalanceInContract();
            uint120 releaseId = _releaseId;
            _releasedUser[releaseId] = receiver; 
            _releasedAmount[releaseId] = amount;
            _releaseId++; 
            _releaseRecipients.push(receiver);
            bool success =_gpuToken.transfer(receiver, amount);
            if(!success) revert TransferFailed(); 
            emit releasedGpu(receiver, amount, releaseId);
    }

    function setRelayers(address[] calldata relayers, bool[] calldata relayerStatus) public onlyRelayer
    {
        uint totalRelayers = relayers.length;
        for(uint i=0; i < totalRelayers; i++)
        {
            _isRelayer[relayers[i]] = relayerStatus[i];
        }
        emit setRelayersStatusAt(block.timestamp);
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