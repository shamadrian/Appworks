// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import { EIP20Interface } from "compound-protocol/contracts/EIP20Interface.sol";
import { CErc20Delegate } from "compound-protocol/contracts/CErc20Delegate.sol";
import { CErc20Delegator } from "compound-protocol/contracts/CErc20Delegator.sol";
import { Comptroller } from "compound-protocol/contracts/Comptroller.sol";
import { ComptrollerInterface } from "compound-protocol/contracts/ComptrollerInterface.sol";
import { Unitroller } from "compound-protocol/contracts/Unitroller.sol";
import { TestToken } from "../src/TestToken.sol";
import { ZeroInterestRateModel } from "../src/ZeroInterestRateModel.sol";
import { SimplePriceOracle } from "compound-protocol/contracts/SimplePriceOracle.sol";
import { CToken } from "compound-protocol/contracts/CToken.sol";

contract DeployTest is Test {
    address payable initialAdmin;
    Comptroller comptroller;
    Unitroller unitroller;
    Comptroller unitrollerInterface;
    SimplePriceOracle simplePriceOracle;
    TestToken testTokenA;
    TestToken testTokenB;
    ZeroInterestRateModel zeroInterestRateModel;
    CErc20Delegate cErc20DelegateA;
    CErc20Delegate cErc20DelegateB;
    CErc20Delegator cErc20DelegatorA;
    CErc20Delegator cErc20DelegatorB;

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    uint256 constant baseAmount = 100 * 10 ** 18;

    function setUp() public {
        //Deploy all contracts
        vm.startPrank(initialAdmin);
        //Deploy comptroller
        comptroller = new Comptroller();
        //Deploy unitroller
        unitroller = new Unitroller();
        //Set comptroller as implementation
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);

        unitrollerInterface = Comptroller(address(unitroller));

        //Deploy SimplePriceOracle
        simplePriceOracle = new SimplePriceOracle();
        //set price oracle by calling function through unitroller
        address(unitroller).call(
            abi.encodeWithSignature(
                "_setPriceOracle(address)",
                address(simplePriceOracle)
            )
        );

        //Deploy underlying token
        testTokenA = new TestToken();
        //Deploy ZeroInterestRateModel
        zeroInterestRateModel = new ZeroInterestRateModel(0,0);
        //Deploy CErc20Delegate
        cErc20DelegateA = new CErc20Delegate();
        //Deploy CErc20Delegator
        cErc20DelegatorA = new CErc20Delegator(
            address(testTokenA),                // underlying
            Comptroller(address(unitroller)),   // comptroller
            zeroInterestRateModel,              // interestRateModel
            1 * 10 ** 18,                       // initialExchangeRateMantissa
            "CompoundTestTokenA",               // name
            "cTTA",                             // symbol
            18,                                 // decimals
            initialAdmin,                       // admin
            address(cErc20DelegateA),           // implementation
            ""                                  // becomeImplementationData
        );

        //Deploy underlying token
        testTokenB = new TestToken();
        //Deploy CErc20Delegate
        cErc20DelegateB = new CErc20Delegate();
        //Deploy CErc20Delegator
        cErc20DelegatorB = new CErc20Delegator(
            address(testTokenB),                // underlying
            Comptroller(address(unitroller)),   // comptroller
            zeroInterestRateModel,              // interestRateModel
            1 * 10 ** 18,                       // initialExchangeRateMantissa
            "CompoundTestTokenB",               // name
            "cTTB",                             // symbol
            18,                                 // decimals
            initialAdmin,                       // admin
            address(cErc20DelegateB),           // implementation
            ""                                  // becomeImplementationData
        );

        //set cErc20Delegator as cToken in comptroller
        unitrollerInterface._supportMarket(CToken(address(cErc20DelegatorA)));
        unitrollerInterface._supportMarket(CToken(address(cErc20DelegatorB)));

        //deal user 1 and 2 testTokens
        deal(address(testTokenA), user1, baseAmount);
        deal(address(testTokenB), user1, baseAmount);
        deal(address(testTokenA), user2, baseAmount);
        deal(address(testTokenB), user2, baseAmount);
    }

    function test_mint() public {
        vm.startPrank(user1);
        testTokenA.approve(address(cErc20DelegatorA), baseAmount);
        cErc20DelegatorA.mint(baseAmount);
        assertEq(cErc20DelegatorA.balanceOf(user1), baseAmount);
        testTokenB.approve(address(cErc20DelegatorB), baseAmount);
        cErc20DelegatorB.mint(baseAmount);
        assertEq(cErc20DelegatorB.balanceOf(user1), baseAmount);
        vm.stopPrank();
    }

    function test_borrow() public {
        vm.startPrank(initialAdmin);
        //Set price of tokenA to 1
        simplePriceOracle.setUnderlyingPrice(CToken(address(cErc20DelegatorA)), 1 * 10 ** 18);
        //Set price of tokenB to 100
        simplePriceOracle.setUnderlyingPrice(CToken(address(cErc20DelegatorB)), 100 * 10 ** 18);
        //set collateral factor of tokenB to 0.5
        unitrollerInterface._setCollateralFactor(CToken(address(cErc20DelegatorB)), 0.5 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(user1);
        testTokenB.approve(address(cErc20DelegatorB), 1*10**18);
        cErc20DelegatorB.mint(1*10**18);
        //enter market for tokenB
        {
            address[] memory cTokens = new address[](1);
            cTokens[0] = address(cErc20DelegatorB);
            unitrollerInterface.enterMarkets(cTokens);
        }
        vm.stopPrank();

        //Provide liquidity for tokenA
        vm.startPrank(user2);
        testTokenA.approve(address(cErc20DelegatorA), baseAmount);
        cErc20DelegatorA.mint(baseAmount);
        //enter market for tokenA
        {
            address[] memory cTokens = new address[](1);
            cTokens[0] = address(cErc20DelegatorB);
            unitrollerInterface.enterMarkets(cTokens);
        }
        vm.stopPrank();

        //borrow tokenA
        vm.startPrank(user1);
        cErc20DelegatorA.borrow(50*10**18);
        assertEq(cErc20DelegatorA.borrowBalanceStored(user1), 50*10**18);
        assertEq(cErc20DelegatorB.balanceOf(user1), 1*10**18);
        assertEq(testTokenA.balanceOf(user1), baseAmount + 50*10**18);
        assertEq(testTokenB.balanceOf(user1), baseAmount - 1*10**18);
    }

    function test_collateralFactor_liquidate() public {
        vm.startPrank(initialAdmin);
        //Set price of tokenA to 1
        simplePriceOracle.setUnderlyingPrice(CToken(address(cErc20DelegatorA)), 1 * 10 ** 18);
        //Set price of tokenB to 100
        simplePriceOracle.setUnderlyingPrice(CToken(address(cErc20DelegatorB)), 100 * 10 ** 18);
        //set collateral factor of tokenB to 0.5
        unitrollerInterface._setCollateralFactor(CToken(address(cErc20DelegatorB)), 0.5 * 10 ** 18);
        unitrollerInterface._setCloseFactor(0.5 * 10 ** 18);
        unitrollerInterface._setLiquidationIncentive(1.1 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(user1);
        testTokenB.approve(address(cErc20DelegatorB), 1*10**18);
        cErc20DelegatorB.mint(1*10**18);
        //enter market for tokenB
        {
            address[] memory cTokens = new address[](1);
            cTokens[0] = address(cErc20DelegatorB);
            unitrollerInterface.enterMarkets(cTokens);
        }
        vm.stopPrank();

        //Provide liquidity for tokenA
        vm.startPrank(user2);
        testTokenA.approve(address(cErc20DelegatorA), baseAmount);
        cErc20DelegatorA.mint(baseAmount);
        //enter market for tokenA
        {
            address[] memory cTokens = new address[](1);
            cTokens[0] = address(cErc20DelegatorB);
            unitrollerInterface.enterMarkets(cTokens);
        }
        vm.stopPrank();

        //borrow tokenA
        vm.startPrank(user1);
        cErc20DelegatorA.borrow(50*10**18);

        //set collateral factor of tokenB to 0.4
        vm.startPrank(initialAdmin);
        unitrollerInterface._setCollateralFactor(CToken(address(cErc20DelegatorB)), 0.4 * 10 ** 18);
        vm.stopPrank();

        //Liquidate user 1 by user 2
        deal(address(testTokenA), user2, 25*10**18);
        vm.startPrank(user2);
        testTokenA.approve(address(cErc20DelegatorA), 25*10**18);
        console2.log("BEFORE:");
        console2.log("user1 balance of tokenA: %d", testTokenA.balanceOf(user1));
        console2.log("user1 balance of tokenB: %d", (testTokenB.balanceOf(user1)));
        console2.log("user1 balance of cErc20DelegatorA: %d", (cErc20DelegatorA.balanceOf(user1)));
        console2.log("user1 balance of cErc20DelegatorB: %d", (cErc20DelegatorB.balanceOf(user1)));
        console2.log("user2 balance of tokenA: %d", testTokenA.balanceOf(user2));
        console2.log("user2 balance of tokenB: %d", (testTokenB.balanceOf(user2)));
        console2.log("user2 balance of cErc20DelegatorA: %d", (cErc20DelegatorA.balanceOf(user2)));
        console2.log("user2 balance of cErc20DelegatorB: %d", (cErc20DelegatorB.balanceOf(user2)));


        cErc20DelegatorA.liquidateBorrow(user1, 25*10**18, cErc20DelegatorB);


        console2.log("AFTER:");
        console2.log("user1 balance of tokenA: %d", (testTokenA.balanceOf(user1)));
        console2.log("user1 balance of tokenB: %d", (testTokenB.balanceOf(user1)));
        console2.log("user1 balance of cErc20DelegatorA: %d", (cErc20DelegatorA.balanceOf(user1)));
        console2.log("user1 balance of cErc20DelegatorB: %d", (cErc20DelegatorB.balanceOf(user1)));
        console2.log("user2 balance of tokenA: %d", (testTokenA.balanceOf(user2)));
        console2.log("user2 balance of tokenB: %d", (testTokenB.balanceOf(user2)));
        console2.log("user2 balance of cErc20DelegatorA: %d", (cErc20DelegatorA.balanceOf(user2)));
        console2.log("user2 balance of cErc20DelegatorB: %d", (cErc20DelegatorB.balanceOf(user2)));
        assertEq(cErc20DelegatorA.borrowBalanceStored(user1), 25*10**18);
        uint256 liquidatedAmount = 0.25*1.1*10**18;
        assertEq(cErc20DelegatorB.balanceOf(user1), (1*10**18) - liquidatedAmount);
        assertEq(testTokenA.balanceOf(user2), 0);
    }

    function test_priceOracle_liquidate() public {
        vm.startPrank(initialAdmin);
        //Set price of tokenA to 1
        simplePriceOracle.setUnderlyingPrice(CToken(address(cErc20DelegatorA)), 1 * 10 ** 18);
        //Set price of tokenB to 100
        simplePriceOracle.setUnderlyingPrice(CToken(address(cErc20DelegatorB)), 100 * 10 ** 18);
        //set collateral factor of tokenB to 0.5
        unitrollerInterface._setCollateralFactor(CToken(address(cErc20DelegatorB)), 0.5 * 10 ** 18);
        unitrollerInterface._setCloseFactor(0.5 * 10 ** 18);
        unitrollerInterface._setLiquidationIncentive(1.1 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(user1);
        testTokenB.approve(address(cErc20DelegatorB), 1*10**18);
        cErc20DelegatorB.mint(1*10**18);
        //enter market for tokenB
        {
            address[] memory cTokens = new address[](1);
            cTokens[0] = address(cErc20DelegatorB);
            unitrollerInterface.enterMarkets(cTokens);
        }
        vm.stopPrank();

        //Provide liquidity for tokenA
        vm.startPrank(user2);
        testTokenA.approve(address(cErc20DelegatorA), baseAmount);
        cErc20DelegatorA.mint(baseAmount);
        //enter market for tokenA
        {
            address[] memory cTokens = new address[](1);
            cTokens[0] = address(cErc20DelegatorB);
            unitrollerInterface.enterMarkets(cTokens);
        }
        vm.stopPrank();

        //borrow tokenA
        vm.startPrank(user1);
        cErc20DelegatorA.borrow(50*10**18);

        //set price of tokenB to 40
        vm.startPrank(initialAdmin);
        simplePriceOracle.setUnderlyingPrice(CToken(address(cErc20DelegatorB)), 40 * 10 ** 18);
        vm.stopPrank();

        //Liquidate user 1 by user 2
        deal(address(testTokenA), user2, 25*10**18);
        vm.startPrank(user2);
        testTokenA.approve(address(cErc20DelegatorA), 25*10**18);
        console2.log("BEFORE:");
        console2.log("user1 balance of tokenA: %d", testTokenA.balanceOf(user1));
        console2.log("user1 balance of tokenB: %d", (testTokenB.balanceOf(user1)));
        console2.log("user1 balance of cErc20DelegatorA: %d", (cErc20DelegatorA.balanceOf(user1)));
        console2.log("user1 balance of cErc20DelegatorB: %d", (cErc20DelegatorB.balanceOf(user1)));
        console2.log("user2 balance of tokenA: %d", testTokenA.balanceOf(user2));
        console2.log("user2 balance of tokenB: %d", (testTokenB.balanceOf(user2)));
        console2.log("user2 balance of cErc20DelegatorA: %d", (cErc20DelegatorA.balanceOf(user2)));
        console2.log("user2 balance of cErc20DelegatorB: %d", (cErc20DelegatorB.balanceOf(user2)));


        cErc20DelegatorA.liquidateBorrow(user1, 25*10**18, cErc20DelegatorB);


        console2.log("AFTER:");
        console2.log("user1 balance of tokenA: %d", (testTokenA.balanceOf(user1)));
        console2.log("user1 balance of tokenB: %d", (testTokenB.balanceOf(user1)));
        console2.log("user1 balance of cErc20DelegatorA: %d", (cErc20DelegatorA.balanceOf(user1)));
        console2.log("user1 balance of cErc20DelegatorB: %d", (cErc20DelegatorB.balanceOf(user1)));
        console2.log("user2 balance of tokenA: %d", (testTokenA.balanceOf(user2)));
        console2.log("user2 balance of tokenB: %d", (testTokenB.balanceOf(user2)));
        console2.log("user2 balance of cErc20DelegatorA: %d", (cErc20DelegatorA.balanceOf(user2)));
        console2.log("user2 balance of cErc20DelegatorB: %d", (cErc20DelegatorB.balanceOf(user2)));
        assertEq(cErc20DelegatorA.borrowBalanceStored(user1), 25*10**18);
        uint256 liquidatedAmount = (1-0.3125)*10**18;
        assertEq(cErc20DelegatorB.balanceOf(user1), (1*10**18) - liquidatedAmount);
        assertEq(testTokenA.balanceOf(user2), 0);
    }
}
