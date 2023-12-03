// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {

    constructor() public ERC20("TestToken", "TT") {
        //ensure decimals is 18
        decimals();
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}
