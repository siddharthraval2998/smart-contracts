pragma solidity >=0.7.0 <0.9.0;


contract SmartBankAccount {
    uint total_contract_balance = 0;
    
    function get_contract_balance() public returns(uint){
        return total_contract_balance;
    } 

    mapping(address => uint) user_balances;
    mapping(address => uint) depositTimestamp;
    function add_Balance() public payable {
        user_balances[msg.sender] = msg.value;
        total_contract_balance += msg.value;
        depositTimestamp[msg.sender] = block.timestamp;
    } 

    function get_user_balance(address user_address) public view returns(uint) {
        uint principal = user_balances[user_address];
        uint time_elapsed = block.timestamp - depositTimestamp[user_address]; // in seconds
        return principal + uint((principal * 7 * time_elapsed) / (100 * 365 * 24 * 60 * 60)) + 1; // .07% SI (no decimals)
    }
    
    function withdraw_all() public payable {
        address payable withdraw_to = payable(msg.sender);
        uint amountToTransfer = get_user_balance(msg.sender);
        withdraw_to.transfer(amountToTransfer);
        total_contract_balance -= amountToTransfer;
        user_balances[msg.sender] = 0;
    }
    
    function add_money_to_contract() public payable {
        total_contract_balance += msg.value;
    }  
    
}
