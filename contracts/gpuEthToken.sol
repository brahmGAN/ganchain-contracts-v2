// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract GpuTokenEth is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable
{
    
    uint120 public constant MAX_SUPPLY = 5000000000000000000000000; // 5 million tokens
    
    error exceedesMaxLimit();
    
    function initialize(uint120 initialAmount) public initializer 
    {
        __ERC20_init("GPUnet", "GPU");
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        
        if(initialAmount > MAX_SUPPLY) revert exceedesMaxLimit();
        // Mint initial amount to owner
        _mint(msg.sender, initialAmount);
    }
    
    // Override transfer functions to respect pause state
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) 
    {
        return super.transfer(to, amount);
    }
    
    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) 
    {
        return super.transferFrom(from, to, amount);
    }
    
    // Owner functions to control transfers
    function pauseTransfers() public onlyOwner 
    {
        _pause();
    }
    
    function unpauseTransfers() public onlyOwner 
    {
        _unpause();
    }
    
    // Emergency transfer function (only owner can use when paused)
    function emergencyTransfer(address from, address to, uint256 amount) public onlyOwner whenPaused 
    {
        _transfer(from, to, amount);
    }
    
    function mint(address to, uint256 amount) public onlyOwner nonReentrant 
    {
        if(totalSupply() + amount > MAX_SUPPLY) revert exceedesMaxLimit();
        _mint(to, amount);
    }
    
    function burn(uint256 amount) public whenNotPaused 
    {
        _burn(msg.sender, amount);
    }
    
    function burnFrom(address account, uint256 amount) public whenNotPaused 
    {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}