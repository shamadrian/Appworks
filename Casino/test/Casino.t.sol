// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Casino} from "../src/Casino.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/safeERC20.sol";
using SafeERC20 for IERC20;

contract CasinoTest is Test {
    Casino casino;
    address public USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    string MAINNET_RPC_URL = "https://polygon-mainnet.g.alchemy.com/v2/Wdk_4nc-Q6RgqhlwBE5H05Udj_9IX_Ho";

    function setUp() public {
        casino = new Casino();
    }

    function test_deposit_CasinoEnd() public {
        //Create user1 address
        address user1 = makeAddr("user1");
        uint256 amount = 1000;
        //fork to a block with usdt deployed
        uint256 forkId = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(forkId);

        vm.startPrank(user1);
        //Deal user1 USDT token
        deal(USDT, user1, amount);
        assertEq(IERC20(USDT).balanceOf(user1), amount);
        //approve casino contract and assert allowance update
        IERC20(USDT).safeIncreaseAllowance(address(casino), amount);
        assertEq(IERC20(USDT).allowance(user1, address(casino)), 1000);
        //user deposit USDT
        //casino.deposit(amount);
        //assertEq(IERC20(USDT).balanceOf(address(casino)), amount);
    }
}
