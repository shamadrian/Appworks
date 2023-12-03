// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import { InterestRateModel } from "../lib/compound-protocol/contracts/InterestRateModel.sol";

contract ZeroInterestRateModel is InterestRateModel {
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view override returns (uint) {
        return 0;
    }

    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view override returns (uint) {
        return 0;
    }
}