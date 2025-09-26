// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IErrors.sol"; 

contract GANNode is ERC721URIStorage, ERC721Enumerable, Ownable, IErrors
{
    event ganNodeMinted(
        address to,
        uint timestamp,
        uint120 tokenId  
    );

    event batchGanNodeMinted(
        uint timestamp
    );

    uint120 public _tokenID;

    constructor() ERC721("GAN-Node","GN") Ownable(msg.sender) {}

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721,ERC721Enumerable) returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721,ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721,ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721URIStorage) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev GN Series Node image on ipfs
    //https://emerald-abundant-wildfowl-967.mypinata.cloud/ipfs/bafkreia2ocdcqqjpzmnynrbhmhne3ztyw4rkb6anidsfp5ntldeeorawsu
    
    function mintNode(address to,string memory uri) public onlyOwner
    {
        ++_tokenID;
        _safeMint(to, _tokenID);
        _setTokenURI(_tokenID,uri);
        emit ganNodeMinted(to, block.timestamp, _tokenID);
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
        emit batchGanNodeMinted(block.timestamp);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) 
    {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) 
        {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokens;
    }
}