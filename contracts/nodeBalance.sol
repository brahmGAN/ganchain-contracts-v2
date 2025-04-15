// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GanNode is IERC721
{
    IERC721 public _ganNode;

    mapping(address => string) public _evmToSS58; 

    event nodeBalance(
        uint nodeBalance 
    );

    constructor(address owner, address ganNode)
    {
        _ganNode = IERC721(ganNode);
    }

    function storeSS58(string calldata ss58) public  
    {   
        if(_ganNode.balanceOf(msg.sender) > 0)
        {
            _evmToSS58 = ss58; 
            emit nodeBalance(_ganNode.balanceOf(msg.sender));
        }
    }
}
