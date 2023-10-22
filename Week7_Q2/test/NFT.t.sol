// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {BlindBox} from "../src/NFT.sol";

contract NFTTest is Test {
    BlindBox public blindBox;

    function setUp() public {
        blindBox = new BlindBox();
    }

    function test_mint() public {
        address user1 = makeAddr("user1");
        blindBox.mint(user1);

        uint256 user1Count = blindBox.balanceOf(user1);
        assertEq(user1Count,1);

        address _owner = blindBox.ownerOf(0);
        assertEq(user1,_owner);
    }

    function test_500mint() public {
        address user1 = makeAddr("user1");

        for (int i=0; i<500; i++){
            blindBox.mint(user1);
        }

        uint256 user1Count = blindBox.balanceOf(user1);
        assertEq(user1Count, 500);
    }

    function test_URI() public {
        address user1 = makeAddr("user1");
        blindBox.mint(user1);

        string memory currBaseURI = blindBox.tokenURI(0);
        assertEq(currBaseURI, blindBox.baseURI());

        blindBox.revealBox();

        string memory revealURI = blindBox.tokenURI(0);
        assertEq(revealURI, blindBox.revealURI());

    }

}
