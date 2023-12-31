// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import { EIP20Interface } from "compound-protocol/contracts/EIP20Interface.sol";
import { CErc20Delegate } from "compound-protocol/contracts/CErc20Delegate.sol";
import { CErc20Delegator } from "compound-protocol/contracts/CErc20Delegator.sol";
import { Comptroller } from "compound-protocol/contracts/Comptroller.sol";
import { ComptrollerInterface } from "compound-protocol/contracts/ComptrollerInterface.sol";
import { Unitroller } from "compound-protocol/contracts/Unitroller.sol";
import { TestToken } from "../src/TestToken.sol";
import { ZeroInterestRateModel } from "../src/ZeroInterestRateModel.sol";
import { SimplePriceOracle } from "compound-protocol/contracts/SimplePriceOracle.sol";

contract DeployerScript is Script {
    address payable initialAdmin;
    Comptroller comptroller;
    Unitroller unitroller;
    SimplePriceOracle simplePriceOracle;
    TestToken testToken;
    ZeroInterestRateModel zeroInterestRateModel;
    CErc20Delegate cErc20Delegate;
    CErc20Delegator cErc20Delegator;

    function run() external {
        //Deploy all contracts
        vm.startBroadcast();
        //Deploy comptroller
        comptroller = new Comptroller();
        //Deploy unitroller
        unitroller = new Unitroller();
        //Set comptroller as implementation
        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller);

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
        testToken = new TestToken();
        //Deploy ZeroInterestRateModel
        zeroInterestRateModel = new ZeroInterestRateModel(0,0);
        //Deploy CErc20Delegate
        cErc20Delegate = new CErc20Delegate();
        //Deploy CErc20Delegator
        cErc20Delegator = new CErc20Delegator(
            address(testToken),                 // underlying
            Comptroller(address(unitroller)),  // comptroller
            zeroInterestRateModel,              // interestRateModel
            1,                                  // initialExchangeRateMantissa
            "CompoundTestToken",                // name
            "cTT",                              // symbol
            18,                                 // decimals
            initialAdmin,                       // admin
            address(cErc20Delegate),            // implementation
            ""                                  // becomeImplementationData
        );
    }
}

