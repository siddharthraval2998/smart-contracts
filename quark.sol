pragma solidity >=0.7.0 <0.9.0;

contract MyErc20 {
    
    string NAME = "Quark";
    string SYMBOL = "QRK";
    address deployer;
    
    mapping(address => uint) balances;
    mapping(uint => bool) blockMined; // mapping of mined blocks
    uint total_coins_minted = 69000000 * 1e8; //1M that has been minted to the deployer in constructor()
    
    //ERC20 specification mandates.
    //It requires that events be triggered for allowance and transfers.
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor(){
        deployer = msg.sender;
        balances[deployer] = 69000000;
    }
    
    function name() public view returns (string memory){ //memory keyword tells Solidity that after returning the variable, it can erase it from the memory stack.
        return NAME;
    }
    
    function symbol() public view returns (string memory) {
        return SYMBOL;
    }
    
    function decimals() public view returns (uint8) {
        return 8;
    }
    
    function totalSupply() public view returns (uint256) {
        return 69696969;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        assert(balances[msg.sender] > _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //require(balances[_from] > _value);
        //require(allowances[_from][msg.sender] > _value);
        if(balances[_from] < _value)
            return false;
        if(allowances[_from][msg.sender]< _value)
            return false;
        
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
        
    }
    
    //approval mechanisms
    mapping(address => mapping(address => uint)) allowances;
    //allowances[user1][user2] = 10; implies user1 has approved user2 to spend 10 coins
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
    
    
    function mine(address miner, uint reward) public returns (bool success){
        if(blockMined[block.number]){
            return false; // reward already collected, function terminated
        }
        if(block.number % 10 != 0){
            return false; // not a 10th block
        }
        balances[msg.sender] += 10*1e8;
        total_coins_minted += 10*1e8;
        return true;
    } 
    
    function get_current_block() public view returns(uint){
        return block.number;
    }
    
    function is_mined(uint block_number) public view returns (bool mined){
        return blockMined[block_number];
        
    }   
    
}
