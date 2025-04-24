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

    event nodeTransferred(
        address sender, 
        address receiver, 
        uint quantity 
    );

    event sellOrderCreated(
        address seller, 
        uint120 quantity, 
        uint120 tierNumber, 
        uint120 sellOrderId
    );

    uint120 public _tokenID;

    mapping(address => uint120) public _totalNodesHeld; 

    mapping(address => uint120) public _nodesToBeSold; 

    uint120[] public _tierPrice; 

    uint120 public _sellOrderId; 

    mapping(uint120 => address) _sellOrderBy;

    mapping(uint120 => uint120) _sellOrderQuantity; 

    mapping(uint120 => uint120) _sellOrderTier; 

    constructor(address owner) ERC721("Gan-Node","GN") Ownable(owner){}

    function mintNode(address to,string memory uri) public onlyOwner
    {
        ++_tokenID;

        _safeMint(to, _tokenID);
        _setTokenURI(_tokenID,uri);

        ++_totalNodesHeld[to];
        //todo emit
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
    
    
    function transferNode(uint quantity, address receiver,uint[] calldata tokenIds) internal 
    {
        if (quantity > balanceOf(msg.sender)) revert insufficientNodes();
        for(uint i=0; i < quantity; i++)
        {
            if (ownerOf(tokenIds[i]) != msg.sender) revert unAuthorizedOwner();
            safeTransferFrom(msg.sender, receiver, tokenIds[i]);
        }
        emit nodeTransferred(msg.sender, receiver, quantity);
    } 

    function sellNodes(uint120 quantity, uint[] calldata tokenIds,uint120 tierNumber) public 
    {
        //Transfer these nodes to the contract 
        uint120 sellOrderId = _sellOrderId;
        _nodesToBeSold[msg.sender] += quantity; 
        _sellOrderBy[sellOrderId] = msg.sender; 
        _sellOrderQuantity[sellOrderId] = quantity; 
        _sellOrderTier[sellOrderId] = tierNumber; 
        transferNode(quantity, address(this), tokenIds);
        _sellOrderId++; 
        emit sellOrderCreated(msg.sender, quantity, tierNumber, sellOrderId);
    }
}