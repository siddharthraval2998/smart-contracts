pragma solidity >=0.7.0 <0.9.0;

interface cETH {
    //declaration of used functions
    function mint() external payable; // deposit to compound
    function redeem(uint redeemTokens) external returns (uint); //compund withdrawals
    // determining withdrawable amount
    
    function exchangeRateStored() external view returns(uint);
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract SmartBankAccount {
    uint total_contract_balance = 0;
    address COMPOUND_CETH_ADDRESS = 0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);
    
    function get_contract_balance() public view returns(uint){
        return total_contract_balance;
    } 
    
    mapping(address => uint) user_balances;
    mapping(address => uint) depositTimestamp;
    
    function add_Balance() public payable {
        // user_balances[msg.sender] = msg.value;
        // total_contract_balance += msg.value;
        // depositTimestamp[msg.sender] = block.timestamp;
        // // send ethers to mint()
        // ceth.mint{value: msg.value}();
        uint contract_ceth_before_mint = ceth.balanceOf(address(this));
        
        // send to mint
        ceth.mint{value: msg.value}();
        uint contract_ceth_after_mint = ceth.balanceOf(address(this)); 
        uint ceth_of_user =  contract_ceth_after_mint - contract_ceth_before_mint;
        user_balances[msg.sender] = ceth_of_user;
        
    }
    
    function getBalance(address user_address) public view returns(uint256){
        //return user_balances[user_address] * ceth.exchangeRateStored() / 1e18
        return ceth.balanceOf(user_address) / ceth.exchangeRateStored() ;
    }


    function withdraw_all() public payable {
        // address payable withdraw_to = payable(msg.sender);
        // uint amountToTransfer = getBalance(msg.sender);
        // withdraw_to.transfer(amountToTransfer);
        // total_contract_balance -= amountToTransfer;
        // user_balances[msg.sender] = 0;
        ceth.redeem(ceth.balanceOf(msg.sender));
        user_balances[msg.sender] = 0;
        
    }
    
    function add_money_to_contract() public payable {
        total_contract_balance += msg.value;
    }
    
    
}
