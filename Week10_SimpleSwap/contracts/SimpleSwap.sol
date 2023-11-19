// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    // Implement core logic here
    address public tokenA;
    address public tokenB;

    constructor(address _tokenA, address _tokenB) ERC20("LP Token", "LP") {
        //check both _tokenA and _tokenB are ERC20
        require(isERC20(_tokenA), "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(isERC20(_tokenB), "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        require(_tokenA != _tokenB, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");
        
        (tokenA, tokenB) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
    }

    function isERC20(address token) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(token)
        }
        if (size == 0) return false;
        try ERC20(token).totalSupply() returns (uint256) {
            return true;
        } catch {
            return false;
        }
    }

    function swap (
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external override returns (uint256 amountOut){
        require (tokenIn == tokenA || tokenIn == tokenB, "SimpleSwap: INVALID_TOKEN_IN");
        require (tokenOut == tokenA || tokenOut == tokenB, "SimpleSwap: INVALID_TOKEN_OUT");
        require (tokenIn != tokenOut, "SimpleSwap: IDENTICAL_ADDRESS");
        require (amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        uint256 reserveA = ERC20(tokenA).balanceOf(address(this));
        uint256 reserveB = ERC20(tokenB).balanceOf(address(this));
        amountOut = (amountIn*reserveB) / (amountIn + reserveA);
        ERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        ERC20(tokenOut).transfer(msg.sender, amountOut);
        reserveA = ERC20(tokenA).balanceOf(address(this));
        reserveB = ERC20(tokenB).balanceOf(address(this));
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }   

    function _quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB){
        amountB = amountA * reserveB / reserveA;
    }

    function _addLiquidity(
        uint256 amountAIn, 
        uint256 amountBIn
    ) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity){
        uint256 reserveA;
        uint256 reserveB;
        reserveA = ERC20(tokenA).balanceOf(address(this));
        reserveB = ERC20(tokenB).balanceOf(address(this));
        if (reserveA == 0 && reserveB == 0) {
            amountA = amountAIn;
            amountB = amountBIn;
        } else {
            uint256 amountBOptimal = _quote(amountAIn, reserveA, reserveB);
            uint256 amountAOptimal = _quote(amountBIn, reserveB, reserveA);
            if (amountBOptimal <= amountBIn) {
                amountA = amountAIn;
                amountB = amountBOptimal;
            } else {
                amountA = amountAOptimal;
                amountB = amountBIn;
            }
        }
        liquidity = Math.sqrt(amountA * amountB);
    }

    function addLiquidity(
        uint256 amountAIn, 
        uint256 amountBIn
    ) external override returns (uint256 amountA, uint256 amountB, uint256 liquidity){
        require (amountAIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require (amountBIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        (amountA, amountB, liquidity) = _addLiquidity(amountAIn, amountBIn);
        ERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        ERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        _mint(msg.sender, liquidity);
        emit AddLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    function removeLiquidity(uint256 liquidity) external override returns (uint256 amountA, uint256 amountB){
        require (liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");
        _transfer(msg.sender, address(this), liquidity);
        uint256 reserveA = ERC20(tokenA).balanceOf(address(this));
        uint256 reserveB = ERC20(tokenB).balanceOf(address(this));
        uint256 currLiquidity = balanceOf(address(this));
        amountA = currLiquidity * reserveA / totalSupply();
        amountB = currLiquidity * reserveB / totalSupply();
        _burn(address(this), currLiquidity);
        ERC20(tokenA).transfer(msg.sender, amountA);
        ERC20(tokenB).transfer(msg.sender, amountB);
        emit RemoveLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    function getReserves() external view override returns (uint256 reserveA, uint256 reserveB){
        return (ERC20(tokenA).balanceOf(address(this)), ERC20(tokenB).balanceOf(address(this)));
    }

    function getTokenA() external view override returns (address){
        return tokenA;
    }

    function getTokenB() external view override returns (address){
        return tokenB;
    }
}