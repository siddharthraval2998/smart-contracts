pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyNFT is ERC721URIStorage {
    
    string NAME = "Raval Collectibles";
    string SYMBOL = "RAC";
    uint256 private _tokenId = 1;
    
    // this marks an item as available for minting
    mapping (string => bool) public notMinted;

    constructor(string memory assetForSale) public ERC721(NAME, SYMBOL) {
        notMinted[assetForSale] = true;
    }

    function mintItem(string memory tokenURI) external returns (uint256) {
        // only "notMinted" items are up for minting
        require(notMinted[tokenURI],"NOT FOR SALE");
        notMinted[tokenURI] = false;

        _mint(msg.sender, _tokenId);

        // set tokenURI for plugging in our metadata to NFT
        _setTokenURI(_tokenId, tokenURI);

        return _tokenId;
    }
}
