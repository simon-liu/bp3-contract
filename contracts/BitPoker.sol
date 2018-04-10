pragma solidity ^0.4.17;


contract Owned {

    address owner;

    function Owned() public { owner = msg.sender; }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract BitPoker is Owned {

    uint8 public version = 1;

    mapping (uint32 => uint256) _balances;

    mapping (address => uint256) _volatile_balances;

    event PreDeposit(address src);

    event PostDeposit(uint32 userId);

    event Transfer(uint32 userId, address dest, uint256 amount);

    function () public payable {
       deposit();
    }

    // 用户（预）充值
    function deposit() public payable {
        require(msg.value >= 0.1 ether && msg.value <= 100 ether);

        _volatile_balances[msg.sender] += msg.value;

        emit PreDeposit(msg.sender);
    }

    // 管理员确认充值
    function confirmDeposit(address[] addresses, uint32[] userIds) public onlyOwner {
        require(addresses.length > 0);
        require(addresses.length == userIds.length);

        for (uint i = 0; i < addresses.length; i++) {
            uint v = _volatile_balances[addresses[i]];
            if (v > 0) {
                _volatile_balances[addresses[i]] -= v;
                _balances[userIds[i]] += v;

                emit PostDeposit(userIds[i]);
            }
        }
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
    function settle() public onlyOwner {
        // TODO impl
        _balances[0] = 0;
    }

    // 销毁合约
    function close(address dest) public onlyOwner {
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