pragma solidity >=0.4.24<0.6.0;

contract SimpleDAO {
    mapping (address => uint) public credit;
    constructor() public {
    }
    function donate() payable public {
        credit[msg.sender] += msg.value;
    }
    function queryCredit(address to) public view returns (uint) {
        return credit[to];
    }
    function withdraw() public {
        uint oldBal = address(this).balance; 
        uint balSender = msg.sender.balance; // translated OK
        uint amount = credit[msg.sender];
        if (amount > 0) {
            credit[msg.sender] = 0;  // FIX
            if (!msg.sender.send(amount)) { // VeriSol bug #185 (can't handle msg.sender.transfer)
               revert();
            }
        }
        uint bal = address(this).balance;
        assert(bal == oldBal || bal == (oldBal - amount));
    }
}

contract Mallory {
    SimpleDAO public dao;
    uint count;
    constructor (address daoAddr) public {
        count = 0;
        dao = SimpleDAO(daoAddr);
        require(dao.queryCredit(address(this)) == 0);
        require(address(this).balance == 1);
    }
    function () payable external {
        if (count < 2) {
            count ++;
            dao.withdraw();
        }
    }
    function donateToDao() public {        
        dao.donate.value(address(this).balance).gas(12)();  
    }
    function getJackpot() public {
        dao.withdraw();
    }
}
