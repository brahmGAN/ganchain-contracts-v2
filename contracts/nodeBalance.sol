// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GanNodeBalance 
{
    IERC721 public _ganNode;

    mapping(address => string) public _evmToSS58; 

    address[] public _validators; 

    event nodeBalance(
        address nodeHolder,
        uint nodeBalance 
    );

    constructor(address ganNode)
    {
        _ganNode = IERC721(ganNode);
    }

    function storeSS58(string memory ss58) public  
    {   
        require(_ganNode.balanceOf(msg.sender) > 0, "Insufficient balance");
        _evmToSS58[msg.sender] = ss58; 
        _validators.push(msg.sender);
        emit nodeBalance(msg.sender,_ganNode.balanceOf(msg.sender));
    }
}
