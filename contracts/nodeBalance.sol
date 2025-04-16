// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GanNodeBalance 
{
    IERC721 public _ganNode;

    mapping(address => string) public _evmToSS58; 

    event nodeBalance(
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
        emit nodeBalance(_ganNode.balanceOf(msg.sender));
    }
}
