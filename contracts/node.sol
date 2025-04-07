// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GanNode is ERC721URIStorage,Ownable
{
    uint120 tokenID;

    constructor(address owner) ERC721("Gan-Node","GN") Ownable(owner){}

    function mint(address to,string memory _uri) public onlyOwner
    {
        ++tokenID;

        _safeMint(to, tokenID);
        _setTokenURI(tokenID,_uri);
        //emit
    }
}
