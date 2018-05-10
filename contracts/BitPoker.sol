pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Owned {

    address owner;

    function Owned() public {owner = msg.sender;}

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract BitPoker is Owned {

    using SafeMath for uint256;

    uint8 public version = 1;

    mapping(uint32 => uint256) _balances;

    mapping(address => uint256) _pre_deposit_balances;

    event PreDeposit(address src, uint256 amount);

    event Deposit(uint32 userId);

    event Withdraw(uint32 userId, address dst, uint256 amount);

    event Transfer(uint64 id, uint32 src, uint32 dst, bool status);

    function() public payable {
        deposit();
    }

    // 用户（预）充值
    function deposit() public payable {
        require(msg.value >= 0.1 ether && msg.value <= 100 ether);

        _pre_deposit_balances[msg.sender] = _pre_deposit_balances[msg.sender].add(msg.value);

        emit PreDeposit(msg.sender, msg.value);
    }

    // 系统确认充值
    function confirmDeposit(uint32 userId, address addr) public onlyOwner {
        uint v = _pre_deposit_balances[addr];
        if (v > 0) {
            _pre_deposit_balances[addr] = _pre_deposit_balances[addr].sub(v);
            _balances[userId] = _balances[userId].add(v);

            emit Deposit(userId);
        }
    }

    // 查询用户余额
    function balanceOf(uint32 userId) public view returns (uint256) {
        return _balances[userId];
    }

    // 提现到指定地址
    function withdrawTo(uint32 userId, address dst, uint256 amount) public onlyOwner {
        require(amount >= 0.01 ether);
        require(_balances[userId] >= amount);

        _balances[userId] = _balances[userId].sub(amount);

        emit Withdraw(userId, dst, amount);

        dst.transfer(amount);
    }

    // 提现全部余额到指定地址
    function withdrawAllTo(uint32 userId, address dst) public onlyOwner {
        return withdrawTo(userId, dst, _balances[userId]);
    }

    // 结算，即互相转账
    function transfer(uint64[] ids, uint32[] src, uint32[] dst, uint256[] amount) public onlyOwner {
        require(src.length > 0);
        require(src.length == dst.length && dst.length == amount.length && amount.length == ids.length);

        for (uint i = 0; i < src.length; i++) {
            if (_balances[src[i]] >= amount[i]) {
                _balances[src[i]] = _balances[src[i]].sub(amount[i]);
                _balances[dst[i]] = _balances[dst[i]].add(amount[i]);

                emit Transfer(ids[i], src[i], dst[i], true);
            } else {
                emit Transfer(ids[i], src[i], dst[i], false);
            }
        }
    }

    // 销毁合约
    function close(address dst) public onlyOwner {
        selfdestruct(dst);
    }
}