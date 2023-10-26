// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


contract Casino {
    IERC20 public USDT;

    constructor() {
        //contract address of USDT token 
        //https://polygonscan.com/address/0xc2132d05d31c914a87c6611c10748aeb04b58e8f
        USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    }

    //Initialize mappings for User and Game Revenue
    mapping (address => uint256) public userBalances;
    mapping (address => uint256) public gameRevenue;

    //Initialize Events
    event DepositEvent(address indexed user, uint256 value);
    event WithdrawalEvent (address indexed user, uint256 value);

    //Purely an interface for reference for the "create state channel" event
    event CreateStateChannelEvent(
        address indexed user,
        bytes userPublicKey,
        bytes gamePublicKey,
        bytes32 indexed channelID,
        uint256 balance
    );

    function deposit(uint256 _amount) external payable {
        //Requirements for amount user deposit 
        //Here we can set, for example, minimum deposit amount 
        require(_amount > 0, "Amount to deposit must be greater than zero!"); 
        
        //Use transferFrom() to transfer USDT from user to this contract
        //When user triggers the "deposit" action, front-end should initiate an "approve" transaction
        //Front-end waits for approval confrimation before they send deposit transaction
        require(
            USDT.transferFrom(msg.sender, address(this), _amount),
            "Deposit Failed"
        );

        //Update balance in mapping
        userBalances[msg.sender] += _amount;

        emit DepositEvent(msg.sender, _amount);
    } 

    function checkBalances() external view returns (uint256){
        return(userBalances[msg.sender]);
    }

    function withdraw(uint256 _amount) external {
        //Requirements for amount user deposit 
        //Here we can set, for example, minimum withdrawal amount
        require(_amount > 0, "Amount to withdraw must be greater than 0");
        //Withdrawal amount must be less than or equal to User's Balance
        require(userBalances[msg.sender] >= _amount);

        //Update balance first before transferring USDT
        userBalances[msg.sender] -= _amount;

        //transfer USDT
        require(
            USDT.transfer(msg.sender, _amount),
            "Withdrawal Failed"
        );

        emit WithdrawalEvent(msg.sender, _amount);
    }

    //Purely an interface for reference for the "exit state channel" function.
    function createStateChannel(
        address _user,
        bytes memory _userPublicKey,
        bytes memory _gamePublicKey,
        bytes32 _channelID,
        uint256 _balance
    ) external {
        //Lock Balance
        emit CreateStateChannelEvent(_user, _userPublicKey, _gamePublicKey, _channelID, _balance);
        //and any other necessary actions
    }

    function exitStateChannel(
        uint256 finalNonce,
        uint256 finalUserBalance,
        uint256 finalGameRevenue,
        bytes memory userSignature,
        bytes memory gameProviderSignature
    ) public {
        //Verify Results
        //Unlock Balance
        //Distribute token
        //Update gameRevenueMap
    }
}
