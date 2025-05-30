// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 

contract gpuNetAirdrops is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors 
{
    address public _updater; 

    mapping(address => uint120) public _airdrop; 

    bool public _claimAirdrops; 

    mapping(address => uint120) public _totalClaimedAirdrop;    
 
    modifier onlyUpdater 
    {
        require(msg.sender == _updater, "You are not the authorized updater");
        _; 
    }

    event claimedAirdrop
    (
        address airdropHunter,
        uint120 airdrop,
        uint claimedAirdropAt
    );

    event setAirdropAt
    (
        address airdropHunter,
        uint120 airdrop,
        uint timestamp
    );

    event setBatchAirdropAt
    (
        uint timestamp
    );

    event setClaimAirdropsStatusAt
    (
        bool status, 
        uint timestamp
    );
 
    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function initialize(address updater) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _updater = updater; 
    }

    receive() external payable {}

    function claimAirdrops() public
    {
        uint120 airdrop = _airdrop[msg.sender]; 
        if(!_claimAirdrops) revert notYetAvailable();
        if(airdrop == 0) revert NothingToClaim();
        if(address(this).balance < airdrop) revert inSufficientBalanceInContract();

        _airdrop[msg.sender] = 0; 
        _totalClaimedAirdrop[msg.sender] += airdrop; 
        (bool success,) = payable(msg.sender).call{value:airdrop}("");
        if(!success) revert TransferFailed(); 

        emit claimedAirdrop(msg.sender, airdrop, block.timestamp);
    }

    function setAirdrop(address airdropHunter, uint120 airdrop) public onlyUpdater 
    {
        _airdrop[airdropHunter] = airdrop; 
        emit setAirdropAt(msg.sender, airdrop, block.timestamp);
    }

    function setBatchAirdrop(address[] calldata airdropHunters, uint120[] calldata airdrops) public onlyUpdater 
    {
        uint totalHunters = airdropHunters.length; 
        for(uint i=0; i < totalHunters; i++)
        {
            _airdrop[airdropHunters[i]] = airdrops[i]; 
        }
        emit setBatchAirdropAt(block.timestamp);
    }

    function setClaimAirdropsStatus(bool status) public onlyUpdater
    {
        _claimAirdrops = status; 
        emit setClaimAirdropsStatusAt(status,block.timestamp);
    }
}