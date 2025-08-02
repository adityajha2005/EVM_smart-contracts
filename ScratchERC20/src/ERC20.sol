// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

contract MyERC20 {
    string public name;
    string public symbol;
    uint8 public constant DECIMALS = 18;
    uint256 public totalSupply;
    address public owner;
    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(string memory _name, string memory _symbol,address _owner,uint256 _initialSupply){
        name=_name;
        symbol=_symbol;
        owner=_owner;
        totalSupply=_initialSupply;
        balanceOf[owner]=_initialSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function mint(address to, uint256 amount) public onlyOwner returns(bool){
        // require(msg.sender==owner,"Only owner can mint");
        balanceOf[to]+=amount;
        totalSupply+=amount;
        emit Transfer(address(0),to,amount);
        return true;
    }

    function transfer(address to,uint256 amount) public returns(bool){
        require(balanceOf[msg.sender]>=amount,"Insufficient balance");
        balanceOf[msg.sender]-=amount;
        balanceOf[to]+=amount;
        emit Transfer(msg.sender,to,amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns(bool){
        allowance[msg.sender][spender]=amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns(bool){
        require(balanceOf[from]>=amount,"Insufficient balance");
        require(allowance[from][msg.sender]>=amount,"Insufficient allowance");
        balanceOf[from]-=amount;
        balanceOf[to]+=amount;
        allowance[from][msg.sender]-=amount;
        emit Transfer(from,to,amount);
        return true;
    }

    function burn(uint256 amount) public returns(bool){
        require(balanceOf[msg.sender]>=amount,"Insufficient balance");
        balanceOf[msg.sender]-=amount;
        totalSupply-=amount;
        emit Transfer(msg.sender,address(0),amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns(bool){
        allowance[msg.sender][spender]+=addedValue;
        emit Approval(msg.sender,spender,allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool){
        uint256 currentAllowance=allowance[msg.sender][spender];
        require(currentAllowance>=subtractedValue,"Insufficient allowance");
        allowance[msg.sender][spender]=currentAllowance-subtractedValue;
        emit Approval(msg.sender,spender,allowance[msg.sender][spender]);
        return true;
    }
    
    function decimals() public pure returns(uint8){
        return DECIMALS;
    }

    function transferOwnership(address newOwner) public onlyOwner returns(bool){
        require(newOwner!=address(0),"Invalid owner address");
        owner=newOwner;
        return true;
    }
}
