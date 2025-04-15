// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IErrors.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract GanNode is ERC721URIStorage,Ownable,ERC721Burnable,IErrors
{
    event batchMinted(
        uint timestamp
    );
    uint120 public _tokenID;
    mapping(address => uint120) public _totalNodesHeld; 

    constructor(address owner) ERC721("Gan-Node","GN") Ownable(owner){}

    function mintNode(address to,string memory uri) public onlyOwner
    {
        ++_tokenID;

        _safeMint(to, _tokenID);
        _setTokenURI(_tokenID,uri);

        ++_totalNodesHeld[to];
    }

    function batchNodeMint(address[] memory users, uint[] memory quantity,string memory uri) public onlyOwner
    {
        if(users.length != quantity.length) revert incorrectArraySize(); 
        uint usersLength = users.length; 
        for(uint i=0; i < usersLength; i++)
        {
            uint quantityLength = quantity[i];
            for(uint j=0; j < quantityLength; j++)
            {
                mintNode(users[i], uri);
            }
        }
        emit batchMinted(block.timestamp);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    //todo add safe transfer 
}
