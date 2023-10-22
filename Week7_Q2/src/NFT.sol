// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract BlindBox is ERC721 {
    address public initialOwner;
    uint256 private tokenIdCounter = 0;
    uint16 private totalSupplyMax = 500;
    bool isRevealed = false;
    string public baseURI = "ipfs://QmQqGC8HEio27SJBoaL3fAbby8rvUMJ4NqCqyyTHG6yuYb/";
    string public revealURI = "ipfs://QmcT3AR8RrDpUV3VGFEXXqTUQiXzLSWmWJwEF6WguTMr8t/";

    constructor() ERC721 ("BlindBox", "BBX") {
        initialOwner = msg.sender;
    }

    function mint(address to) external {
        require(tokenIdCounter < totalSupplyMax, "Maximum number of NFT minted!");
        _safeMint(to, tokenIdCounter);
        tokenIdCounter ++; 
    }

    function tokenURI(uint256 tokenId) public view override virtual returns (string memory){
        if (isRevealed){
            return revealURI;
        }
        else {
            return baseURI;
        }
    }

    function revealBox() public {
        require(msg.sender == initialOwner, "You are not the OWNER!");
        isRevealed = true;
    }
}