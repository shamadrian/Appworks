// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {USDCV2} from "../src/USDCV2.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract USDCV2_Test is Test {
    address owner = 0xFcb19e6a322b27c06842A71e8c725399f049AE3a;
    address admin = 0x807a96288A1A408dBC13DE2b1d087d10356395d2;
    string MAINNET_RPC_URL = "https://eth-mainnet.g.alchemy.com/v2/4WBPgBhRQ974kL4R95dBUTPvXygfki-j";
    USDCV2 public usdcv2;

    address public USDCProxy = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;


    function setUp() public {
        uint256 forkId = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(forkId);
        usdcv2 = new USDCV2();
        //initialize the new implementation address
        
    }

    function test_upgrade() public {
        vm.startPrank(admin);
        //upgrade proxy implementation address and use return value of low-level call to check if it is successful
        (bool success, ) = USDCProxy.call(
            abi.encodeWithSignature("upgradeTo(address)", address(usdcv2))
        );
        require(success, "upgrade failed");
        vm.stopPrank();
        vm.startPrank(owner);
        //use low-level call to initialize the new implementation address and use return value of low-level call to check if it is successful
        (bool success1, ) = USDCProxy.call(
            abi.encodeWithSignature("initialize(address)", owner)
        );
        require(success1, "initialize failed");
        vm.stopPrank();

        vm.startPrank(admin);
        //use low-level call to check if the implementation address is upgraded and also check if it is successful
        (bool success2, bytes memory data) = USDCProxy.call(
            abi.encodeWithSignature("implementation()")
        );
        require(success2, "implementation failed");
        //convert data to address
        address upgradedImplementation = abi.decode(data, (address));
        vm.stopPrank();

        vm.startPrank(owner);
        //use low-level call to check if the owner is upgraded and also check if it is successful
        (bool success3, bytes memory data2) = USDCProxy.call(
            abi.encodeWithSignature("getOwner()")
        );
        require(success3, "owner failed");
        vm.stopPrank();
        //convert data to address
        address upgradedOwner = abi.decode(data2, (address));

        assertEq(upgradedImplementation, address(usdcv2));
        assertEq(upgradedOwner, owner);
    }

    function test_mint() public {
        address user1 = makeAddr("user1");
        vm.startPrank(admin);
        //upgrade proxy implementation address and use return value of low-level call to check if it is successful
        (bool success, ) = USDCProxy.call(
            abi.encodeWithSignature("upgradeTo(address)", address(usdcv2))
        );
        require(success, "upgrade failed");
        vm.stopPrank();
        vm.startPrank(owner);
        //use low-level call to initialize the new implementation address and use return value of low-level call to check if it is successful
        (bool success1, ) = USDCProxy.call(
            abi.encodeWithSignature("initialize(address)", owner)
        );
        require(success1, "initialize failed");
        vm.stopPrank();

        //user1 mint 100 USDC and expect revert
        vm.startPrank(user1);
        vm.expectRevert(bytes("error message"));
        (bool success2, ) = USDCProxy.call(
            abi.encodeWithSignature("mint(address,uint256)", user1, 100)
        );
        assertTrue(!success2, "expectRevert: call did not revert");
        vm.stopPrank();

        vm.startPrank(owner);
        //add user1 to whitelist then mint 100 USDC and expect success
        (bool success3, ) = USDCProxy.call(
            abi.encodeWithSignature("add_whitelist(address)", user1)
        );
        require(success3, "add whitelist failed");
        vm.stopPrank();

        vm.startPrank(user1);
        (bool success4, ) = USDCProxy.call(
            abi.encodeWithSignature("mint(address,uint256)", user1, 100)
        );
        require(success4, "mint2 failed");
        vm.stopPrank();

        //use low-level call to check user1 balance is 100
        (bool success5, bytes memory data) = USDCProxy.call(
            abi.encodeWithSignature("balanceOf(address)", user1)
        );
        require(success5, "balanceOf failed");
        uint256 balance = abi.decode(data, (uint256));
        assertEq(balance, 100);
    }

    function test_transfer() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.startPrank(admin);
        //upgrade proxy implementation address and use return value of low-level call to check if it is successful
        (bool success, ) = USDCProxy.call(
            abi.encodeWithSignature("upgradeTo(address)", address(usdcv2))
        );
        require(success, "upgrade failed");
        vm.stopPrank();
        vm.startPrank(owner);
        //use low-level call to initialize the new implementation address and use return value of low-level call to check if it is successful
        (bool success1, ) = USDCProxy.call(
            abi.encodeWithSignature("initialize(address)", owner)
        );
        require(success1, "initialize failed");

        //add user1 to whitelist then mint 100 USDC and expect success
        (bool success3, ) = USDCProxy.call(
            abi.encodeWithSignature("add_whitelist(address)", user1)
        );
        require(success3, "add whitelist failed");
        vm.stopPrank();

        vm.startPrank(user1);
        (bool success4, ) = USDCProxy.call(
            abi.encodeWithSignature("mint(address,uint256)", user1, 100)
        );
        require(success4, "mint2 failed");
        //use low-level call to transfer 100 USDC from user1 to user2 and expect success
        (bool success5, ) = USDCProxy.call(
            abi.encodeWithSignature("transfer(address,uint256)", user2, 100)
        );
        require(success5, "transfer failed");
        vm.stopPrank();

        vm.startPrank(user2);
        //use low-level call to transfer 100 USDC from user2 to user1 and expect revert
        vm.expectRevert(bytes("error message"));
        (bool success6, ) = USDCProxy.call(
            abi.encodeWithSignature("transfer(address,uint256)", user1, 100)
        );
        assertTrue(!success6, "expectRevert: call did not revert");
        vm.stopPrank();

        vm.startPrank(owner);
        //add user2 to whitelist then mint 100 USDC and expect success
        (bool success7, ) = USDCProxy.call(
            abi.encodeWithSignature("add_whitelist(address)", user2)
        );
        require(success7, "add whitelist failed");
        vm.stopPrank();

        vm.startPrank(user2);
        //use low-level call to transfer 100 USDC from user2 to user1 and expect success
        (bool success8, ) = USDCProxy.call(
            abi.encodeWithSignature("transfer(address,uint256)", user1, 100)
        );
        require(success8, "transfer2 failed");
        vm.stopPrank();

        //use low-level call to get the balance of both user1 and user2
        (bool success9, bytes memory data) = USDCProxy.call(
            abi.encodeWithSignature("balanceOf(address)", user1)
        );
        require(success9, "balanceOf failed");
        uint256 balance1 = abi.decode(data, (uint256));

        (bool success10, bytes memory data2) = USDCProxy.call(
            abi.encodeWithSignature("balanceOf(address)", user2)
        );
        require(success10, "balanceOf2 failed");
        uint256 balance2 = abi.decode(data2, (uint256));

        assertEq(balance1, 100);
        assertEq(balance2, 0);
    }
}
