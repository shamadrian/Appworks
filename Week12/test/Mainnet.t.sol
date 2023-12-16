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
import {
  IFlashLoanSimpleReceiver,
  IPoolAddressesProvider,
  IPool
} from "aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import {FlashLoanLiquidate} from "../src/FlashLoanLiquidate.sol";

contract MainnetTest is Test {
    //Initilalize compound contracts
    address payable initialAdmin = payable(makeAddr("initialAdmin"));
    Comptroller comptroller;
    Unitroller unitroller;
    Comptroller unitrollerInterface;
    SimplePriceOracle simplePriceOracle;
    ZeroInterestRateModel zeroInterestRateModel;
    CErc20Delegate cErc20DelegateUSDC;
    CErc20Delegate cErc20DelegateUNI;
    CErc20Delegator cErc20DelegatorUSDC;
    CErc20Delegator cErc20DelegatorUNI;
    FlashLoanLiquidate flashLoanLiquidate;


    //Copy from Mainnet token addresses
    address USDCAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address UNIAddress = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    EIP20Interface USDC = EIP20Interface(USDCAddress);
    EIP20Interface UNI = EIP20Interface(UNIAddress);

    //Make user addresses
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        string memory rpc = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(rpc, 17465000);

        //Deploy compound contracts
        vm.startPrank(initialAdmin);
        comptroller = new Comptroller();
        unitroller = new Unitroller();
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);
        unitrollerInterface = Comptroller(address(unitroller));

        //Set price oracles
        simplePriceOracle = new SimplePriceOracle();
        unitrollerInterface._setPriceOracle(simplePriceOracle);
        zeroInterestRateModel = new ZeroInterestRateModel(0,0);

        //Set CToken pools for USDC and UNI
        cErc20DelegateUSDC = new CErc20Delegate();
        cErc20DelegatorUSDC = new CErc20Delegator(
            USDCAddress, 
            Comptroller(address(unitroller)), 
            zeroInterestRateModel, 
            0.000000000001*10**18,
            "Compound USDC", 
            "cUSDC", 
            18, 
            initialAdmin,
            address(cErc20DelegateUSDC),
            ""
        );
        cErc20DelegateUNI = new CErc20Delegate();
        cErc20DelegatorUNI = new CErc20Delegator(
            UNIAddress, 
            Comptroller(address(unitroller)), 
            zeroInterestRateModel, 
            1*10**18,
            "Compound UNI", 
            "cUNI", 
            18, 
            initialAdmin,
            address(cErc20DelegateUNI),
            ""
        );

        //Configure compound markets
        unitrollerInterface._supportMarket(CToken(address(cErc20DelegatorUSDC)));
        unitrollerInterface._supportMarket(CToken(address(cErc20DelegatorUNI)));
        //set underlying prices
        simplePriceOracle.setUnderlyingPrice(CToken(address(cErc20DelegatorUSDC)), 1000000000000 * 10 ** 18);
        simplePriceOracle.setUnderlyingPrice(CToken(address(cErc20DelegatorUNI)), 5 * 10 ** 18);
        //set collateral factors
        unitrollerInterface._setCollateralFactor(CToken(address(cErc20DelegatorUNI)), 0.5*10**18);
        unitrollerInterface._setCollateralFactor(CToken(address(cErc20DelegatorUSDC)), 0.5*10**18);
        unitrollerInterface._setCloseFactor(0.5 * 10 ** 18);
        unitrollerInterface._setLiquidationIncentive(1.08 * 10 ** 18);

        vm.stopPrank();

        //deal tokens to users
        deal(UNIAddress, user1, 1000 * 10 ** 18);
        deal(USDCAddress, user1, 5000 * 10 ** 6);
        deal(UNIAddress, user2, 1000 * 10 ** 18);
        deal(USDCAddress, user2, 5000 * 10 ** 6);

        //deploy flashloan contract
        flashLoanLiquidate = new FlashLoanLiquidate();
    }

    function test_liquidation() public {
        //user 1 deposits 1000 UNI as collateral
        vm.startPrank(user1);
        UNI.approve(address(cErc20DelegatorUNI), 1000 * 10 ** 18);
        cErc20DelegatorUNI.mint(1000 * 10 ** 18);
        //Enter Market for USDC
        {
            address[] memory cTokens = new address[](1);
            cTokens[0] = address(cErc20DelegatorUNI);
            unitrollerInterface.enterMarkets(cTokens);
        }
        vm.stopPrank();

        //user 2 deposits 5000 USDC as collateral (provide liquidity)
        vm.startPrank(user2);
        USDC.approve(address(cErc20DelegatorUSDC), 5000 * 10 ** 6);
        cErc20DelegatorUSDC.mint(5000 * 10 ** 6);
        //Enter Market for UNI
        {
            address[] memory cTokens = new address[](1);
            cTokens[0] = address(cErc20DelegatorUSDC);
            unitrollerInterface.enterMarkets(cTokens);
        }
        vm.stopPrank();

        //user 1 borrows 2500 USDC
        vm.startPrank(user1);
        cErc20DelegatorUSDC.borrow(2500 * 10 ** 6);
        vm.stopPrank();

        //Set price of uni to $4
        vm.startPrank(initialAdmin);
        simplePriceOracle.setUnderlyingPrice(CToken(address(cErc20DelegatorUNI)), 4 * 10 ** 18);
        vm.stopPrank();

        //user 2 use flashloanliquidate contract
        vm.startPrank(user2);
        flashLoanLiquidate.execute(address(user1), 1250 * 10 ** 6, cErc20DelegatorUNI, cErc20DelegatorUSDC);
        console2.log("user2 USDC balance: ", USDC.balanceOf(user2));
    }
}