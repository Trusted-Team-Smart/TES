pragma solidity >=0.6.0 <0.8.0;

import "./safeMath.sol";
import "./IERC20.sol";
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
Contract function to receive approval and execute function in one call
*/
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external ;
}

/**
ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers
*/
contract ERC20 is IERC20{
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private CAPLIMIT;
    uint256 public startTime;
    uint256 private INFLATIONPERCENT = 3;
    uint256 private MONTHLY_INFLATION = 90;
    uint256 private FEE_PERCENT = 1;
    address internal _mainWallet;
    uint256 private lastTime;
    uint256 private _cap;
    bool private isFirstInflation;
    // ------------------------------------------------------------------------
    // Constructor
    // initSupply = 10TES
    // ------------------------------------------------------------------------
    constructor() internal {
        _symbol = "TES";
        _name = "Trusted Team Smart";
        _decimals = 18;
        _totalSupply = 10 * 10**18;
        CAPLIMIT = 21 * 10**24;
        _cap = 21 * 10**23;
        _balances[msg.sender] = _totalSupply;
        startTime = block.timestamp;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

 
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender, 
            _allowances[msg.sender][spender].sub(subtractedValue,
            "ERC20: decreased allowance below zero")
        );
        return true;
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        ApproveAndCallFallBack spender = ApproveAndCallFallBack(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _product(uint256 amount) internal {
        if (block.timestamp - startTime > 638751 days) {
            if (block.timestamp - lastTime > 356 days || !isFirstInflation) {
                if (!isFirstInflation) {
                    if (CAPLIMIT > _totalSupply)
                        amount = CAPLIMIT.sub(_totalSupply);
                    _cap = CAPLIMIT;
                    isFirstInflation = true;
                }
                _cap = _cap.mul(100 + INFLATIONPERCENT).div(100);
                lastTime = block.timestamp;
            }
        } else {
            if (block.timestamp - lastTime > 30 days) {
                _cap = _cap.mul(100 + MONTHLY_INFLATION).div(100);
                lastTime = block.timestamp;
            }  
        }

        if (_totalSupply.add(amount) > _cap)
            amount = _cap.sub(_totalSupply);
        if (amount == 0)
            return;

        _balances[_mainWallet] = _balances[_mainWallet].add(amount.mul(FEE_PERCENT).div(100));
        _totalSupply = _totalSupply.add(amount);
        _balances[address(this)] = _balances[address(this)].add(amount);
        
        emit Transfer(address(0), address(this), amount);
        emit Transfer(address(0), _mainWallet, amount.mul(FEE_PERCENT).div(100));
    }


    function burn(uint256 amount) external {
        require(msg.sender != address(0), "ERC20: burn from the zero address");

        _balances[msg.sender] = _balances[msg.sender].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}