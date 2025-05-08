//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26; 

import "./interfaces/IErrors.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Monad is  ERC721URIStorage,ERC721Burnable,IErrors,Ownable
{

    uint120 public _tokenID;

    address public _fundsHandler;

    constructor(address owner, address fundsHandler) ERC721("GPUNET-Monad-Quest","MQ") Ownable(owner)
    {
        _fundsHandler = fundsHandler;
    }

    function mintMonadNft(string memory uri) public payable
    {
        if(msg.value != 6 ether) revert incorrectAmount(); 

        ++_tokenID;
        _safeMint(msg.sender, _tokenID);
        _setTokenURI(_tokenID,uri);
        (bool success,) = payable(_fundsHandler).call{value:msg.value}("");
        if(!success) revert TransferFailed(); 
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
}