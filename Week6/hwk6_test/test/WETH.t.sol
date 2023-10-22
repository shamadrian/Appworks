// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {WETH} from "../src/WETH.sol";

contract WETHTest is Test {
    WETH public weth;

    event DepositEvent(address sender, uint256 amount);
    event WithdrawalEvent(address sender, uint amount);
   
    uint256 amount;

    function setUp() public {
        weth = new WETH();
    }

    function test_DepositEqualMint() public {
        address user1 = makeAddr("user1");
        vm.startPrank(user1);
        // 1. let user1 have 1 ether
        vm.deal(user1, 1 ether);
        // 2. send 1 ether to weth
        weth.mint{value: 1 ether}();
        // 3. Assert user1 has 1 ether in balance
        amount = weth.balanceOf(user1);
        assertEq(amount, 1 ether);
        vm.stopPrank();
    }

    function test_DepositEqualETHReceive() public {
        address user1 = makeAddr("user1");
        uint256 baseAmount = address(weth).balance;

        vm.startPrank(user1);
        // 1. let user1 have 1 ether
        vm.deal(user1, 1 ether);
        // send 1 ether to weth
        weth.mint{value: 1 ether}();
        //increment baseAmount
        uint256 finalAmount = address(weth).balance;
        //assert difference between final and base amount
        assertEq (finalAmount - baseAmount, 1 ether);
        vm.stopPrank();
    }

    function test_DepositEvent() public {
        address user1 = makeAddr("user1");
        vm.startPrank(user1);
        // 1. let user1 have 1 ether
        vm.deal(user1, 1 ether);
        // send 1 ether to weth

        vm.expectEmit(true, false, false, true);
        emit DepositEvent(user1, 1 ether);

        weth.mint{value: 1 ether}();
        vm.stopPrank();
    }

    function test_WithdrawEqualBurn() public {
        address user1 = makeAddr("user1");
        vm.startPrank(user1);
        // 1. let user1 have 1 ether
        vm.deal(user1, 1 ether);
        // 2. send 1 ether to weth
        weth.mint{value: 1 ether}();

        uint256 baseAmount = weth.balanceOf(user1);
        weth.burn(1 ether);
        uint finalAmount = weth.balanceOf(user1);

        assertEq(baseAmount-finalAmount, 1 ether);

        vm.stopPrank();
    }

    function test_WithdrawEqualTokenReceived() public {
        address user1 = makeAddr("user1");
        vm.startPrank(user1);
        // 1. let user1 have 1 ether
        vm.deal(user1, 1 ether);
        // 2. send 1 ether to weth
        weth.mint{value: 1 ether}();

        uint256 baseAmount = address(weth).balance;
        weth.burn(1 ether);
        uint finalAmount = address(weth).balance;

        assertEq(baseAmount-finalAmount, 1 ether);

        vm.stopPrank();
    }

    function test_WithdrawEvent() public {
        address user1 = makeAddr("user1");
        vm.startPrank(user1);
        // 1. let user1 have 1 ether
        vm.deal(user1, 1 ether);
        // send 1 ether to weth
        weth.mint{value: 1 ether}();

        vm.expectEmit(true, false, false, true);
        emit WithdrawalEvent(user1, 1 ether);

        weth.burn(1 ether);

        vm.stopPrank();
    }

    function test_TransferFunction() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");

        vm.startPrank(user1);
        // 1. let user1 have 1 ether
        vm.deal(user1, 1 ether);
        // send 1 ether to weth
        weth.mint{value: 1 ether}();

        uint256 user1BaseAmount = weth.balanceOf(user1);
        uint256 user2BaseAmount = weth.balanceOf(user2);

        weth.transfer(user2, 1);

        uint256 user1FinalAmount = weth.balanceOf(user1);
        uint256 user2FinalAmount = weth.balanceOf(user2);

        assertEq(user1BaseAmount - user1FinalAmount, 1);
        assertEq(user2FinalAmount - user2BaseAmount, 1);

    }

    function test_ApproveEqualAllowance() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.startPrank(user1);
        weth.approve(user2, 1 ether);
        uint256 finalAllowance = weth.allowance(user1, user2);
        assertEq(finalAllowance, 1 ether);
        vm.stopPrank();
    }

    function test_TransferFromCanUseAllowance() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.startPrank(user1);

        weth.approve(address(weth), 1 ether);
        vm.deal(user1, 1 ether);

        weth.mint{value: 1 ether}();

        vm.stopPrank();
        vm.startPrank(address(weth));

        bool success = weth.transferFrom(user1, user2, 1 ether);
        
        assertEq(success, true);
        vm.stopPrank();
    }

    function test_TransferFromEqualAllowance() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.startPrank(user1);

        weth.approve(address(weth), 1 ether);
        uint256 baseAllowance = weth.allowance(user1, address(weth));

        vm.deal(user1, 1 ether);

        weth.mint{value: 1 ether}();

        vm.stopPrank();
        vm.startPrank(address(weth));

        weth.transferFrom(user1, user2, 1 ether);

        uint256 finalAllowance = weth.allowance(user1, address(weth));
        
        assertEq(baseAllowance-finalAllowance, 1 ether);
        vm.stopPrank();
    }
}