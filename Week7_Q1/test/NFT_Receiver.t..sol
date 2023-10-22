// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {HW_Token} from "../src/NFT_Receiver.sol";
import {NFTReceiver} from "../src/NFT_Receiver.sol";
import {NoUseful} from "../src/NFT_Receiver.sol";

contract CounterTest is Test {
    HW_Token public hwToken;
    NFTReceiver public nftReceiver;
    NoUseful public noUseful;

    function setUp() public {
        hwToken = new HW_Token();
        nftReceiver = new NFTReceiver(address(hwToken));
        noUseful = new NoUseful();
    }

    function test_receive() public {
        address user1 = makeAddr("user1");
        vm.startPrank(user1);

        //Mint nouseful NFT to user1 with tokenID = 0
        noUseful.mint(user1, 0);
        noUseful.approve(address(noUseful), 0);
        noUseful.transferToReceiver(address(nftReceiver), 0);

        assertEq(hwToken.balanceOf(user1), 1);
        vm.stopPrank();
    }
}
