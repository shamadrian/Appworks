// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

//import erc721
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
//import erc721a
import "../lib/erc721a/contracts/ERC721A.sol";

contract NFTMintWithERC721A is ERC721A {

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    //create a mint function that mint multiple of tokens
    function batchMint(address _to, uint256 _amount) public {
        _safeMint(_to, _amount);
    }

    //create a safe transfer function with approval checking
    function transferNFT(address _from, address _to, uint256 _tokenId) public {
        //require the caller must be the owner or approved
        safeTransferFrom(_from, _to, _tokenId);
    }

}

contract NFTMintWithERC721Enumerable is ERC721Enumerable{

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    //create a mint function that mint multiple of tokens
    function batchMint(address _to, uint256 _amount) public {
        //use a for loop to mint multiple of tokens
        for(uint256 i = 0; i < _amount; ) {
            _safeMint(_to, i);
            ++i;
        }
    }

    function transferNFT(address _from, address _to, uint256 _tokenId) public {
        //require the caller must be the owner or approved
        safeTransferFrom(_from, _to, _tokenId);
    }
    
}
