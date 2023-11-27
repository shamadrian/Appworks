// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Pair } from "v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Callee } from "v2-core/interfaces/IUniswapV2Callee.sol";

// This is a practice contract for flash swap arbitrage
contract Arbitrage is IUniswapV2Callee, Ownable {

    struct CallbackData{
        address higherPricePool;
        address lowerPricePool;
        uint256 usdcRepayAmount;
        uint256 borrowETH;
    }

    //
    // EXTERNAL NON-VIEW ONLY OWNER
    //

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Withdraw failed");
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(msg.sender, amount), "Withdraw failed");
    }

    //
    // EXTERNAL NON-VIEW
    //

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external override {
        require(sender == address(this), "Unauthorized sender");
        CallbackData memory callbackData = abi.decode(data, (CallbackData));
        address lowerPricePool = callbackData.lowerPricePool;
        IUniswapV2Pair lowerPool = IUniswapV2Pair(lowerPricePool);
        require(msg.sender == lowerPricePool, "Unauthorized sender");

        address higherPricePool = callbackData.higherPricePool;
        IUniswapV2Pair higherPool = IUniswapV2Pair(higherPricePool);
        
        uint256 usdcRepayAmount = callbackData.usdcRepayAmount;
        uint256 borrowETH = callbackData.borrowETH;
        
        (uint256 reserve0, uint256 reserve1, ) = higherPool.getReserves();
        uint256 usdcAmountOut = _getAmountOut(borrowETH, reserve0, reserve1);
        //trasnfer 5 eth to higher pool
        IERC20(higherPool.token0()).transfer(higherPricePool, borrowETH);   
        //swap 5 eth to usdc
        higherPool.swap(0, usdcAmountOut, address(this), "");
        //transfer usdc to lower pool
        IERC20(lowerPool.token1()).transfer(lowerPricePool, usdcRepayAmount);
    }

    // Method 1 is
    //  - borrow WETH from lower price pool
    //  - swap WETH for USDC in higher price pool
    //  - repay USDC to lower pool
    // Method 2 is
    //  - borrow USDC from higher price pool
    //  - swap USDC for WETH in lower pool

    //  - repay WETH to higher pool
    // for testing convenient, we implement the method 1 here
    function arbitrage(address priceLowerPool, address priceHigherPool, uint256 borrowETH) external {
        require(borrowETH > 0, "Borrow amount must be greater than 0");
        IUniswapV2Pair lowerPool = IUniswapV2Pair(priceLowerPool);

        // get reserves
        (uint256 reserve0, uint256 reserve1, ) = lowerPool.getReserves();
        uint256 usdcRepayAmount = _getAmountIn(borrowETH, reserve1, reserve0);
        //get callback data
        CallbackData memory callbackData = CallbackData({
            higherPricePool: priceHigherPool,
            lowerPricePool: priceLowerPool,
            usdcRepayAmount: usdcRepayAmount,
            borrowETH: borrowETH
        });
        bytes memory data = abi.encode(callbackData);
        lowerPool.swap(borrowETH, 0, address(this), data);

    }

    //
    // INTERNAL PURE
    //

    // copy from UniswapV2Library
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    // copy from UniswapV2Library
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
