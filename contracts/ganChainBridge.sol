// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 

contract GanChainBridge is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors 
{
    address[] public _gpuLockers; 

    address[] public _releaseRecipients; 

    uint120 public _lockId; 

    uint120 public _releaseId; 

    mapping(uint120 => address) public _lockedUser; 

    mapping(address => uint120) public _totalLockedAmount; 

    mapping(uint120 => address) public _releasedUser; 

    mapping(address => uint120) public _totalReleasedAmount; 

    bool public _lockGpu; 

    bool public _lockGpuSolana; 

    mapping(address => bool) public _isRelayer; 

    mapping(uint120 => string) public _solAddress; 

    mapping(uint120 => uint120) public _lockedAmount; 

    event lockedGpu
    (
        address user,
        uint amountLocked, 
        uint120 lockId, 
        uint timestamp,
        uint chain 
    );

    event lockedGpuSolana
    (
        address user,
        uint amountLocked, 
        uint120 lockId, 
        uint timestamp,
        string solAddress
    );

    event releasedGpu
    (
        address user,
        uint amountReleased, 
        uint120 releaseId, 
        uint timestamp 
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
    
    function initialize(address initialRelayer) public initializer 
    { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _isRelayer[initialRelayer] = true; 
    }

    receive() external payable {}

    function lockGpu(uint amount, uint chainId) public payable nonReentrant
    {
        if(!_lockGpu) revert notYetAvailable(); 
        if(msg.value != amount) revert incorrectAmount();
        uint120 lockId = _lockId; 
        _lockedUser[lockId] = msg.sender;
        _totalLockedAmount[msg.sender] += uint120(msg.value); 
        _lockedAmount[lockId] = uint120(msg.value);
        _lockId++; 
        _gpuLockers.push(msg.sender); 
        emit lockedGpu(msg.sender, msg.value, lockId, block.timestamp, chainId);
    }

    function lockGpuSolana(uint amount, string memory solAddress) public payable nonReentrant
    {
        if(!_lockGpuSolana) revert notYetAvailable(); 
        if(msg.value != amount) revert incorrectAmount();
        if(bytes(solAddress).length < 32 || bytes(solAddress).length > 44) revert invalidSolAddress();
        uint120 lockId = _lockId; 
        _lockedUser[lockId] = msg.sender;
        _totalLockedAmount[msg.sender] += uint120(msg.value); 
        _solAddress[lockId] = solAddress; 
        _lockedAmount[lockId] = uint120(msg.value);
        _lockId++; 
        _gpuLockers.push(msg.sender); 
        emit lockedGpuSolana(msg.sender, msg.value, lockId, block.timestamp, solAddress);
    }

    /// @notice `amount` should be passed in wei
    function releaseGpu(uint120 amount, address receiver) public onlyRelayer
    {
            if(address(this).balance < amount) revert inSufficientBalanceInContract();
            uint120 releaseId = _releaseId;
            _releasedUser[releaseId] = receiver; 
            _totalReleasedAmount[receiver] += amount;
            _releaseId++; 
            _releaseRecipients.push(receiver);
            (bool success,) = payable(receiver).call{value:amount}("");
            if(!success) revert TransferFailed(); 
            emit releasedGpu(receiver, amount, releaseId, block.timestamp);
    }

    function setRelayers(address[] calldata relayers, bool[] calldata relayerStatus) public onlyOwner
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