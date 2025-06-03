// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract GPUNet is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    
    function initialize(uint256 initialSupply) public initializer 
    {
        __ERC20_init("GPU NET", "GPU");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        
        _mint(msg.sender, initialSupply);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function mint(address to, uint256 amount) public onlyOwner nonReentrant 
    {
        _mint(to, amount);
    }
}