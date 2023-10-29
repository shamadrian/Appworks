// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract USDCV2 is ERC20 {
   //create a whitelist of addresses that can mint USDC
    mapping(address => bool) public whitelist;

    address public owner;
    bool isInitialized = false;

    constructor() ERC20("USD Coin", "USDC") {}

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function initialize(address _address) public {
        require(!isInitialized, "Contract already initialized");
        require(_address != address(0), "Invalid address");
        isInitialized = true;   
        owner = _address;
        whitelist[_address] = true;
    }

    function getOwner() public view returns (address) {
        return owner;
    }


    //create a whitelist of addresses that can mint USDC
    function mint(address _to, uint256 _amount) public {
        require(whitelist[msg.sender] == true, "You are not whitelisted");
        _mint(_to, _amount);
    }

    //add an address to the whitelist by owner
    function add_whitelist(address _address) public {
        require(msg.sender == owner, "You are not the owner");
        whitelist[_address] = true;
    }

    //remove an address from the whitelist by owner
    function remove_whitelist(address _address) public {
        require(msg.sender == owner, "You are not the owner");
        whitelist[_address] = false;
    }

    //only whitelist user can transfer
    function transfer(address _to, uint256 _amount) public override returns (bool) {
        require(whitelist[msg.sender] == true, "You are not whitelisted");
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    //only whitelist user can transferFrom
    function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool) {
        require(whitelist[msg.sender] == true, "You are not whitelisted");
        require(whitelist[_from] == true, "You are not whitelisted");
        _transfer(_from, _to, _amount);
        return true;
    }
}
