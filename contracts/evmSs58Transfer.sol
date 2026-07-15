// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 

contract EvmSs58Transfer is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable, IErrors 
{

    bool public _transfer; 

    address public _fundsHandler;

    event transferToSs58
    (
        address indexed user,
        uint amount, 
        string ss58,
        uint timestamp
    );

 
    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function initialize() public initializer 
    { 
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }


    /// @notice Transfer native tokens to the funds handler and emit an event
    /// @param _ss58Address The SS58 address associated with the transfer
    function transfer(string calldata _ss58Address) external payable nonReentrant {
        if(!_transfer) revert notYetAvailable();
        if (msg.value == 0) revert incorrectAmount();
        if (bytes(_ss58Address).length != 48) revert invalidSS58Address();

        (bool success, ) = payable(_fundsHandler).call{value: msg.value}("");
        if (!success) revert TransferFailed();

        emit transferToSs58(msg.sender, msg.value, _ss58Address, block.timestamp);
    }

    /// @notice Update the funds handler address
    /// @param _newFundsHandler The new address to receive funds
    function setFundsHandler(address _newFundsHandler) external onlyOwner {
        if (_newFundsHandler == address(0)) revert invalidFundsHandlerAddress();
        _fundsHandler = _newFundsHandler;
    }

    /// @notice Update the transfer lock
    /// @param _newTransferStatus The new transfer status
    function setTransferStatus(bool _newTransferStatus) external onlyOwner {
        _transfer = _newTransferStatus;
    }
} 