pragma solidity >=0.6.0 <0.8.0;

import "./safeMath.sol";
import "./ERC20.sol";

// ----------------------------------------------------------------------------
// TRUSTED TEAM SMART ERC20 TOKEN/Bank
// Website       : https://eth.tts.best/bank
// Symbol        : TES
// Name          : TES
// Max supply    : 21000000
// Decimals      : 18
// Owner Account : 
//
// Enjoy.
//
// (c) by TRUSTED TEAM SMART 2020. MIT Licence.
// Developers Signature(MD5 Hash) : d6b0169c679a33d9fb19562f135ce6ee
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: APACHE

/**
ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers
*/
contract TESToken is ERC20{
    using SafeMath for uint256;
    
    uint256 private buyAmountLimit = 500;
    uint256 private pulseAmount = 500;
    uint256 private pulseCoef = 100035; // / 100000
    uint256 private CoefLimit = 20;
    
    uint256 public currentCoef = 5000; // /100000
    uint256 public pulseCounter;
    uint256 public currentPulse;


    event Sell(address indexed seller, uint256 TESAmount, uint256 ETHAmount, uint256 price);
    event Buy(address indexed buyer, uint256 TESAmount, uint256 ETHAmount, uint256 price);

    constructor(address mainWallet) public {
        _mainWallet = mainWallet;
    }

    //pays ETH gets TES
    function buyToken() public payable {
        uint256 price = getPrice().mul(100000 + currentCoef).div(100000);
        uint256 TESAmount = msg.value.mul(1e12).div(price);
        uint256 ETHAmount = msg.value;
        uint256 payBackETH = 0;
        if (TESAmount > buyAmountLimit) {
            uint256 payBackTES = TESAmount - buyAmountLimit;
            payBackETH = price.mul(payBackTES).div(1e12);
            TESAmount = buyAmountLimit;
        }
       
        if (_balances[address(this)] < TESAmount) {
            _product(TESAmount);
        }

        if (_balances[address(this)] < TESAmount) {
            uint256 payBackTES = TESAmount - _balances[address(this)];
            payBackETH = payBackETH.add(price.mul(payBackTES).div(1e12));
            TESAmount = _balances[address(this)];
        }

        currentPulse = currentPulse.add(TESAmount);
        if (currentPulse > pulseAmount) {
            currentPulse = currentPulse.sub(pulseAmount);
            pulseCounter++;
            if (currentCoef < CoefLimit) {
                currentCoef = currentCoef.mul(pulseCoef).div(100000);
                if (currentCoef > CoefLimit)
                    currentCoef = CoefLimit;
            }
        }

        if (payBackETH > 0) {
            msg.sender.transfer(payBackETH);
            ETHAmount = ETHAmount.sub(payBackETH);
        }

        if (TESAmount > 0) {
            _transfer(address(this), msg.sender, TESAmount);   
            emit Buy(msg.sender, TESAmount, ETHAmount, price);
        }
    }
    
    //pays TES gets tron
    function sellToken(uint256 amount) public {
        uint256 price = getPrice();
        _transfer(msg.sender, address(this), amount);
        uint256 ETHAmount = amount.mul(price).div(1e12);
        msg.sender.transfer(ETHAmount);

        emit Sell(msg.sender, amount, ETHAmount, price);
    }


    // decimals : 12
    function getPrice() public view returns(uint256 price) {
        uint256 balance = address(this).balance.mul(1e12);
        return balance.div(_totalSupply - _balances[address(this)]);
    }
}