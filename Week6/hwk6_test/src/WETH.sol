// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20{
    constructor() ERC20("Wrapped Ether", "WETH") {}

    event DepositEvent(address sender, uint256 amount);
    event WithdrawalEvent(address sender, uint amount);

    function mint() external payable {
        emit DepositEvent(msg.sender, msg.value);
        _mint(msg.sender, msg.value);

    }

    function burn(uint _amount) external{
        require(balanceOf(msg.sender) >= _amount, "Insufficient Funds");
        _burn(msg.sender,_amount);
        (bool withdrawSucces,) = msg.sender.call{value: _amount}("Success");
        require( withdrawSucces, "Failed to Complete");
        emit WithdrawalEvent(msg.sender, _amount);
    }
}