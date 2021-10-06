// To accept any erc20 token

pragma solidity  >=0.7.0 <0.9.0;

interface cETH {
    //declaration of used functions
    function mint() external payable; // deposit to compound
    function redeem(uint redeemTokens) external returns(uint); //compund withdrawals
    // determining withdrawable amount
    
    function exchangeRateStored() external view returns(uint);
    function balanceOf(address owner) external view returns(uint256 balance);
}

// IERC20 interface

interface IERC20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external view returns(bool);
    function approve(address spender, uint256 amount) external view returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external view returns(bool);
}

// uniswap - another contract to exchange erc20 tokens to and from eth
interface UniswapRouter {
    function WETH() external pure returns (address);
    
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract SmartBankAccount {
    uint total_contract_balance = 0;
    address COMPOUND_CETH_ADDRESS = 0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);
    // erc20address = 0xad6d458402f60fd3bd25163575031acdce07538d; // DAI smart contract address on ropsten
    
    address UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    UniswapRouter uniswap = UniswapRouter(UNISWAP_ROUTER_ADDRESS);
    
    function get_contract_balance() public view returns(uint){
        return total_contract_balance;
    } 
    
    mapping(address => uint) user_balances;
    mapping(address => uint) depositTimestamp;
    
    function add_Balance() public payable {
        uint contract_ceth_before_mint = ceth.balanceOf(address(this));
        // send to mint
        ceth.mint{value: msg.value}();
        uint contract_ceth_after_mint = ceth.balanceOf(address(this)); 
        uint ceth_of_user =  contract_ceth_after_mint - contract_ceth_before_mint;
        user_balances[msg.sender] = ceth_of_user;
        
    }
    
    function getBalance(address user_address) public view returns(uint256){
        return ceth.balanceOf(user_address) / ceth.exchangeRateStored() ;
    }
    
    //  getting the number of tokens approved by the user for the function's usage
    // erc20.transferFrom(msg.sender, address(this), approved_erc20_tokens); //transferring approved tokens to the smart contract
    
    //check erc20 balance of contract
    function get_erc20_allowance(address erc20address) public view returns(uint) {
        IERC20 erc20 = IERC20(erc20address);
        return erc20.allowance(msg.sender, address(this));
    }
    
    // add erc20 balance
    function addBalanceERC20(address erc20address) public  {
        IERC20 erc20 = IERC20(erc20address);
        uint approvedAmountOfERC20Tokens = erc20.allowance(msg.sender, address(this));
        address token = erc20address;
        uint amountETHMin = 0; 
        address to = address(this);
        uint deadline = block.timestamp + (24 * 60 * 60);
        erc20.transferFrom(msg.sender, address(this), approvedAmountOfERC20Tokens);
        erc20.approve(UNISWAP_ROUTER_ADDRESS, approvedAmountOfERC20Tokens);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswap.WETH();
        uniswap.swapExactTokensForETH(approvedAmountOfERC20Tokens, amountETHMin, path, to, deadline);
        // transfer all those tokens that had been approved by user (msg.sender) to the smart contract (address(this))
    }

// need to approve tokens  for smart contract use - https://questb.uk/quest/a-bank-for-all-crypto-currencies-fc83




    function withdraw_all() public payable {
        ceth.redeem(ceth.balanceOf(msg.sender));
        user_balances[msg.sender] = 0;
        
    }
    
    function add_money_to_contract() public payable {
        total_contract_balance += msg.value;
    }
    
    
}

// transfer erc20 token to smart contract
// contract converts to ETH
// deposit eth to compund
