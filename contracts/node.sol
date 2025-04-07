// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IErrors.sol"; 

contract GanNode is ERC721URIStorage,Ownable
{
    uint120 _tokenID;
    mapping(address => uint120) _totalNodesHeld; 

    constructor(address owner) ERC721("Gan-Node","GN") Ownable(owner){}

    function mint(address to,string memory uri) public onlyOwner
    {
        ++_tokenID;

        _safeMint(to, _tokenID);
        _setTokenURI(_tokenID,uri);

        ++_totalNodesHeld[to];
        //emit
    }
}
