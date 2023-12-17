// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {
  IFlashLoanSimpleReceiver,
  IPoolAddressesProvider,
  IPool
} from "aave-v3-core/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import { CErc20Delegator } from "compound-protocol/contracts/CErc20Delegator.sol";
import { ISwapRouter } from "../lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { TransferHelper } from "../lib/v3-periphery/contracts/libraries/TransferHelper.sol";

// TODO: Inherit IFlashLoanSimpleReceiver
contract FlashLoanLiquidate {
  address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
  address constant POOL_ADDRESSES_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;

  ISwapRouter swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  struct CallBackData{
    address target;
    CErc20Delegator cTokenCollateral;
    CErc20Delegator cTokenBorrow;
  }

  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address initiator,
    bytes calldata params
  ) external returns (bool) {
    require(initiator == address(this), "FlashLoanLiquidate: initiator is not this contract");
    CallBackData memory callbackData = abi.decode(params, (CallBackData));
    address target = callbackData.target;
    {
        CErc20Delegator cTokenCollateral = callbackData.cTokenCollateral;
        CErc20Delegator cTokenBorrow = callbackData.cTokenBorrow;
        IERC20(USDC).approve(address(cTokenBorrow), amount);
        cTokenBorrow.liquidateBorrow(target, amount, cTokenCollateral);
        cTokenCollateral.redeem(cTokenCollateral.balanceOf(address(this)));
    }
    {
        ISwapRouter.ExactInputSingleParams memory swapParams = 
        ISwapRouter.ExactInputSingleParams(
            UNI,
            USDC,
            3000,
            address(this),
            block.timestamp,
            IERC20(UNI).balanceOf(address(this)),
            0,
            0
        );
        IERC20(UNI).approve(address(swapRouter), IERC20(UNI).balanceOf(address(this)));
        uint256 amountOut = swapRouter.exactInputSingle(swapParams);
    }
    IERC20(USDC).approve(msg.sender, amount+premium);
    return true;
  }

  function execute(address target, uint256 borrowAmount, CErc20Delegator cTokenCollateral, CErc20Delegator cTokenBorrow) external {
    // TODO
    IPool pool = POOL();
    CallBackData memory callbackData = CallBackData(target, cTokenCollateral, cTokenBorrow);
    bytes memory params = abi.encode(callbackData);
    pool.flashLoanSimple(address(this), USDC, borrowAmount, params, 1);
    IERC20(USDC).transfer(msg.sender, IERC20(USDC).balanceOf(address(this)));

  }

  function ADDRESSES_PROVIDER() public view returns (IPoolAddressesProvider) {
    return IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER);
  }

  function POOL() public view returns (IPool) {
    return IPool(ADDRESSES_PROVIDER().getPool());
  }
}
