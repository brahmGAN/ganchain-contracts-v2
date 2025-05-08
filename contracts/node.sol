// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IErrors.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract GanNode is ERC721URIStorage,Ownable,ERC721Burnable,IErrors
{
    event nodeMinted(
        address to,
        uint timestamp,
        uint120 tokenId  
    );

    event batchMinted(
        uint timestamp
    );

    event nodesTransferred(
        address seller, 
        address buyer, 
        uint quantity, 
        uint[] tokenIds 
    );

    event sellOrderCreated(
        address seller, 
        uint120 quantity, 
        uint120 tierNumber, 
        uint120 sellOrderId
    ); 

    event cancelledOrder
    (
        address seller, 
        uint timestamp, 
        uint120 sellOrderId 
    );

    event setTierPRiceAt 
    (
        uint timestamp 
    );

    uint120 public _tokenID;

    /// @dev Pending nodes to be sold by a user
    mapping(address => uint120) public _nodesToBeSold; 

    /// @dev Total quantity of the sell order
    mapping(uint120 => uint120) _sellOrderQuantity; 

    /// @dev Pending nodes to be sold in a sell order
    mapping(uint120 => uint120) public _pendingNodesInOrder; 

    mapping(uint120 => uint120) public _tierPrice; 

    uint120 public _sellOrderId; 

    /// @dev sellOrder created by 
    mapping(uint120 => address) _sellOrderBy;

    /// @dev Nodes to be sold in this tier 
    mapping(uint120 => uint120) _sellOrderTier; 

    /// @dev Used to check order status incase seller wants to withdraw the order
    mapping(uint120 => bool) _sellOrderStatus; 

    mapping(address => uint120) _nodesSold; 

    /// @dev locks for user callable functions 
    bool public _sellNodes;

    bool public _buyNodes; 

    bool public _cancelSellOrder; 

    constructor(address owner) ERC721("Gan-Node","GN") Ownable(owner){}

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
    
    function mintNode(address to,string memory uri) public onlyOwner
    {
        ++_tokenID;
        _safeMint(to, _tokenID);
        _setTokenURI(_tokenID,uri);
        emit nodeMinted(to, block.timestamp, _tokenID);
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
    
    function transferNode(uint quantity, address seller, address buyer,uint[] calldata tokenIds) internal 
    {
        if (quantity > balanceOf(seller)) revert insufficientNodes();
        for(uint i=0; i < quantity; i++)
        {
            if (ownerOf(tokenIds[i]) != seller) revert unAuthorizedOwner();
            safeTransferFrom(seller, buyer, tokenIds[i]);
        }
    } 

    function sellNodes(uint120 quantity, uint[] calldata tokenIds,uint120 tierNumber) public 
    {
        if(!_sellNodes) revert sellNodesNotYetAvailable();
        uint120 sellOrderId = _sellOrderId;
        _nodesToBeSold[msg.sender] += quantity; 
        _sellOrderQuantity[sellOrderId] = quantity; 
        _pendingNodesInOrder[sellOrderId] = quantity;
        _sellOrderBy[sellOrderId] = msg.sender;  
        _sellOrderTier[sellOrderId] = tierNumber; 
        _sellOrderStatus[sellOrderId] = true;
        _sellOrderId++;   
        //Transfer these nodes to the contract 
        // transferNode(quantity, msg.sender, address(this), tokenIds[]);
        //todo: Approve
        //Approve the contract
        setApprovalForAll(address(this), true);
        emit sellOrderCreated(msg.sender, quantity, tierNumber, sellOrderId);
    }

    function buyNodes(uint120 quantity,uint120 sellOrderId, uint[] calldata tokenIds) public payable 
    {
        if(!_buyNodes) revert buyNodesNotYetAvailable(); 
        uint120 tierNumber = _sellOrderTier[sellOrderId]; 
        uint120 tierPrice = _tierPrice[tierNumber]; 
        uint120 amount = tierPrice * quantity; 
        address seller = _sellOrderBy[sellOrderId];
        if(msg.value != amount) revert incorrectAmount();
        _nodesToBeSold[seller] -= quantity;
        _pendingNodesInOrder[sellOrderId] -= quantity;
        _nodesSold[seller] += quantity; 
        if(_pendingNodesInOrder[sellOrderId] == 0)
        {
            _sellOrderStatus[sellOrderId] = false;
        }
        transferNode(quantity, _sellOrderBy[sellOrderId], msg.sender, tokenIds);
        (bool success,) = payable(seller).call{value: amount}("");
        if (!success) revert TransferFailed();
        emit nodesTransferred(seller,msg.sender,quantity,tokenIds);
    }

    function cancelSellOrder(uint120 sellOrderId) public 
    {
        if(!_cancelSellOrder) revert cancelSellOrderNotYetAvailable(); 
        _nodesToBeSold[msg.sender] -= _pendingNodesInOrder[sellOrderId];
        _sellOrderStatus[sellOrderId] = false;  
        emit cancelledOrder(msg.sender, block.timestamp, sellOrderId);
    }

    function setTierPrice(uint120[] calldata tierPrice) public onlyOwner
    {
        for(uint120 i=0; i < tierPrice.length; i++)
        {
            _tierPrice[i] = tierPrice[i]; 
        }

        emit setTierPRiceAt(block.timestamp);
    }

    function setLockStatus(uint functionType, bool status) public onlyOwner 
    {
        if(functionType == 0) 
        {
            _sellNodes = status; 
        }
        else if(functionType == 1)
        {
            _buyNodes = status; 
        }
        else if(functionType == 2)
        {
            _cancelSellOrder = status; 
        }
        else 
        {
            revert wrongFunctionType(); 
        }
    }
}