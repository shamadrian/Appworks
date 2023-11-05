// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {NFTMintWithERC721A} from "../src/ERC721Compare.sol";
import {NFTMintWithERC721Enumerable} from "../src/ERC721Compare.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../lib/erc721a/contracts/ERC721A.sol";

contract ERC721CompareTest is Test {
    NFTMintWithERC721A public erc721a;
    NFTMintWithERC721Enumerable public erc721Enumerable;

    function setUp() public {
        erc721a = new NFTMintWithERC721A("TestA", "TA");
        erc721Enumerable = new NFTMintWithERC721Enumerable("Testt2", "TB");
    }

    function test_erc721A() public {
        //setup addresses
        address user1 = makeAddr("user1");
        address operator = makeAddr("operator");
        address user2 = makeAddr("user2");

        //user1 mints 10 tokens
        vm.startPrank(user1);
        erc721a.batchMint(user1, 10);
        uint256 balance = erc721a.balanceOf(user1);
        assertTrue(balance == 10, "balance should be 10");

        //user 1 approves operator to transfer all tokens
        erc721a.setApprovalForAll(operator, true);
        assertTrue(erc721a.isApprovedForAll(user1, operator), "operator should be approved");

        //user 1 transfers 1 token to user 2
        erc721a.transferNFT(user1, user2, 0);
        balance = erc721a.balanceOf(user1);
        assertTrue(balance == 9, "balance should be 9");
        balance = erc721a.balanceOf(user2);
        assertTrue(balance == 1, "balance should be 1");

    }

    function test_erc721Enumerable() public {
        //Setup addresses
        address user1 = makeAddr("user1");
        address operator = makeAddr("operator");
        address user2 = makeAddr("user2");

        //user1 mints 10 tokens
        vm.startPrank(user1);
        erc721Enumerable.batchMint(user1, 10);
        uint256 balance = erc721Enumerable.balanceOf(user1);
        assertTrue(balance == 10, "balance should be 10");

        //user 1 approves operator to transfer all tokens
        erc721Enumerable.setApprovalForAll(operator, true);
        assertTrue(erc721Enumerable.isApprovedForAll(user1, operator), "operator should be approved");

        //user 1 transfers 1 token to user 2
        erc721Enumerable.transferNFT(user1, user2, 0);
        balance = erc721Enumerable.balanceOf(user1);
        assertTrue(balance == 9, "balance should be 9");
        balance = erc721Enumerable.balanceOf(user2);
        assertTrue(balance == 1, "balance should be 1");
    }
}
