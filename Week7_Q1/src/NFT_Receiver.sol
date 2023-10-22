// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol" ;
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract NoUseful is ERC721 {
    address initialOwner;
    constructor() ERC721 ("Random", "RND") {
        initialOwner = msg.sender;
    }

    function mint(address to, uint tokenId) external {
        _safeMint(to, tokenId);
    }

    function transferToReceiver (address _address, uint _tokenId) public {
        safeTransferFrom(msg.sender, _address, _tokenId);
    }
}

contract HW_Token is ERC721URIStorage{
    address initialOwner;
    string baseURI = "https://ipfs.io/ipfs/QmUSnLRtU1Xk78pYpexBJ4zSjHCRfBiHwg9a4YKi1z47U4";

    constructor() ERC721 (unicode"Don’t send NFT to me", "NONFT") {
        initialOwner = msg.sender;
    }

    function mintToken(address to, uint tokenId) external {
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override virtual returns (string memory){
        return baseURI;
    }
}

contract NFTReceiver is IERC721Receiver {

    address public specificNFTContract;

    constructor(address _specificNFTContract) {
        specificNFTContract = _specificNFTContract;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external returns (bytes4) {
        if (msg.sender == specificNFTContract) {
            //NOTHING
        }
        else{
           (bool success, ) = msg.sender.call(
                abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), from, tokenId)
            );
            require(success, "Transfer failed");

            HW_Token(specificNFTContract).mintToken(from, 0);
        }
        return this.onERC721Received.selector;
    }
}
