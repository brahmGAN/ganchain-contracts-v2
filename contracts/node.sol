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

    /// @dev Pending nodes to be sold by a user
    mapping(address => uint120) public _nodesToBeSold; 

    /// @dev Total quantity of the sell order
    mapping(uint120 => uint120) _sellOrderQuantity; 

    /// @dev Pending nodes to be sold in a sell order
    mapping(uint120 => uint120) public _pendingNodesToBeSold; 

    mapping(uint120 => uint120) public _tierPrice; 

    uint120 public _sellOrderId; 

    /// @dev sellOrder created by 
    mapping(uint120 => address) _sellOrderBy;

    /// @dev Nodes to be sold in this tier 
    mapping(uint120 => uint120) _sellOrderTier; 

    /// @dev Used to check order status incase seller wants to withdraw the order
    mapping(uint120 => bool) _sellOrderStatus; 

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
        uint120 sellOrderId = _sellOrderId;
        _nodesToBeSold[msg.sender] += quantity; 
        _sellOrderQuantity[sellOrderId] = quantity; 
        _pendingNodesToBeSold[sellOrderId] = quantity;
        _sellOrderBy[sellOrderId] = msg.sender;  
        _sellOrderTier[sellOrderId] = tierNumber; 
        _sellOrderStatus[sellOrderId] = true;
        _sellOrderId++;  
        //Transfer these nodes to the contract 
        // transferNode(quantity, address(this), tokenIds);
        //todo: Approve
        //Approve the contract
        setApprovalForAll(address(this), true);
        emit sellOrderCreated(msg.sender, quantity, tierNumber, sellOrderId);
    }

    function buyNodes(uint120 quantity,uint120 sellOrderId, uint[] calldata tokenIds) public payable 
    {
        uint120 tierNumber = _sellOrderTier[sellOrderId]; 
        uint120 tierPrice = _tierPrice[tierNumber]; 
        uint120 amount = tierPrice * quantity; 
        address seller = _sellOrderBy[sellOrderId];
        if(msg.value != amount) revert incorrectAmount();
        _nodesToBeSold[seller] -= quantity;
        _pendingNodesToBeSold[sellOrderId] -= quantity;
        if(_pendingNodesToBeSold[sellOrderId] == 0)
        {
            _sellOrderStatus[sellOrderId] = false;
        }
        transferNode(quantity, msg.sender, tokenIds);
        (bool success,) = payable(seller).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    //todo add locks for user callable functions 
    function cancelSellOrder(uint120 sellOrderId) public 
    {
        _nodesToBeSold[msg.sender] -= _pendingNodesToBeSold[sellOrderId];
        _sellOrderStatus[sellOrderId] = false;  
    }

    function setTierPrice(uint120[] calldata tierPrice) public onlyOwner
    {
        for(uint120 i=0; i < tierPrice.length; i++)
        {
            _tierPrice[i] = tierPrice[i]; 
        } 
    }
}