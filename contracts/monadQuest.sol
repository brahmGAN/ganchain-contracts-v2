//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26; 

import "./interfaces/IErrors.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 
{
    function balanceOf(address owner) external view returns (uint256 balance);
}


contract Monad is  ERC721URIStorage,ERC721Burnable,IErrors,Ownable
{

    uint120 public _tokenID;

    address public _fundsHandler; 

    uint120 public _mintPrice; 

    uint120 public _paidUserMintPrice;

    IERC721 constant _oldContract = IERC721(0x0B41968c55145CCa1ad8f82cCA996Bf0BCbB58B8); 

    event MonadNftMinted
    (
        address user,
        uint256 mintPrice,
        uint120 tokenID 
    );

    constructor(address owner, address fundsHandler, uint120 mintPrice, uint120 paidUserMintPrice) ERC721("GPUNET-Monad-Quest","MQ") Ownable(owner)
    {
        _fundsHandler = fundsHandler;
        _mintPrice = mintPrice; 
        _paidUserMintPrice = paidUserMintPrice;
    }

    /// @dev The uri to be passed while minting 
    // https://emerald-abundant-wildfowl-967.mypinata.cloud/ipfs/bafkreig64vpxozqu436mc2of7fecasdxllif64l4omxl2usp6h6rokzfpu
    function mintMonadNft(string memory uri) public payable
    {
        uint120 mintPrice;
        if(_oldContract.balanceOf(msg.sender) > 0 )
        {
            // 5.9 ETH
            mintPrice = _paidUserMintPrice; 
        }
        else
        {
            // 6 eth
            mintPrice = _mintPrice; 
        } 

        if(msg.value != uint256(mintPrice)) revert incorrectAmount(); 

        ++_tokenID;
        _safeMint(msg.sender, _tokenID);
        _setTokenURI(_tokenID,uri);
        (bool success,) = payable(_fundsHandler).call{value:msg.value}("");
        if(!success) revert TransferFailed(); 
        emit MonadNftMinted(msg.sender, msg.value,_tokenID);
    }

    function setMintPrice(uint120 mintPrice) public onlyOwner 
    {
        _mintPrice = mintPrice; 
    }

    function setMintPriceForPaidUsers(uint120 mintPrice) public onlyOwner 
    {
        _mintPrice = mintPrice; 
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