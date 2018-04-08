pragma solidity ^0.4.17;


contract Owned {

    address owner;

    function Owned() public { owner = msg.sender; }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract Stop is Owned {

    bool public stopped = false;

    modifier stoppable {
        require(!stopped);
        _;
    }

    function stop() public onlyOwner {
        stopped = true;
    }
}

contract BitPoker is Owned, Stop {

    uint8 public version = 1;

    mapping (uint32 => uint256) _balances;

    event Deposit(uint32 userId, uint amount, uint256 balance);

    event Transfer(uint32 userId, address dest, uint256 amount);

    function () public stoppable payable {
       deposit();
    }

    // 用户充值
    function deposit() public stoppable payable {
        require(msg.value >= 0.1 ether);

        uint32 userId = extractUserId(msg.data);
        _balances[userId] += msg.value;

        assert(_balances[userId] <= 500 ether);

        emit Deposit(userId, msg.value, _balances[userId]);
    }

    // 查询用户余额
    function balanceOf(uint32 userId) public constant returns (uint256) {
        return _balances[userId];
    }

    // 提现到指定地址
    function transferTo(uint32 userId, address dest, uint256 amount) public onlyOwner {
        require(amount >= 0.1 ether);
        require(_balances[userId] >= amount);

        _balances[userId] -= amount;

        emit Transfer(userId, dest, amount);

        dest.transfer(amount);
    }

    // 结算
    function settle() public stoppable {
        // TODO impl
        _balances[0] = 0;
    }

    // 销毁合约
    function close(address dest) public onlyOwner {
        stop();

        selfdestruct(dest);
    }

    // 从转账信息中抽取用户ID
    function extractUserId(bytes value) private pure returns (uint32) {
        uint32 ret = 0;
        for (uint8 i = 0; i < 4 && i < value.length; i++) {
            uint8 v1 = uint8(value[i] & 0x0F);
            assert(v1 >= 0 && v1 <= 9);

            uint8 v2 = uint8(value[i] & 0xF0) / 16;
            assert(v2 >= 0 && v2 <= 9);

            ret = ret * 100 + v2 * 10 + v1;
        }

        assert(ret > 0 && ret <= 99999999);

        return ret;
    }
}