pragma solidity >=0.5.0 < 0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "https://github.com/bcnmy/metatx-standard/blob/master/src/contracts/lib/EIP712Base.sol" ;
import "https://github.com/bcnmy/metatx-standard/blob/master/src/contracts/EIP712MetaTransaction.sol" ;

contract TLWallet {
    
    address deployer;
    
    constructor() {
      deployer = msg.sender();
    }
    
    // structure for an ethereum deposit event
    struct ethTxn {
        address sender;
        address recipient;
        uint amount;
        uint timestamp;
    }

    struct erc20Txn {
        address erc20tokenaddress;
        address sender;
        address recipient;
        uint amount;
        uint timestamp;
    }

    mapping(uint => ethTxn) ethTxns;
    mapping(uint => erc20Txn) erc20Txns;

    mapping(address => uint) ethBalances;
    mapping(address => uint) erc20Balances;
 
    mapping(uint => bool) claimedTxns;

    uint txnID = 0;
    uint public txnExpiry = 2 ; // seconds for which the funds need to be locked
    uint public contractBalance = 0;
    
    function setTxnExpiry(uint secondsToExpiry) external onlyDeployer {
        txnExpiry = secondsToExpiry;
    }
    
    function sendETH(address _to) external payable returns(uint) {
        contractBalance += msg.value;
        ethBalances[msg.sender()] += msg.value;
        txnID += 1 ;
        ethTxn memory txn = ethTxn(msg.sender(), _to, msg.value,block.timestamp);
        //ethTxnRecipients[txnID] = _to;
        ethTxns[txnID] = txn;
        return txnID; //this is used to claim the deposited funds
}


    
    function claimEth (uint _txnID) external { //takes txnID as an argument
        require(msg.sender() == ethTxns[_txnID].recipient, "you are not the intended recipient!");
        require(claimedTxns[_txnID] != true, " Transaction is already claimed!");
        require(block.timestamp > (ethTxns[_txnID].timestamp + txnExpiry), "Time Lock in place");  
        ethBalances[ethTxns[_txnID].sender] -= ethTxns[_txnID].amount;
        address payable recipient = payable(ethTxns[_txnID].recipient);
        recipient.transfer(ethTxns[_txnID].amount);
        ethBalances[ethTxns[_txnID].recipient] += ethTxns[_txnID].amount;
        contractBalance -= ethTxns[_txnID].amount;
        claimedTxns[_txnID] = true ;
        
    }    
    

    function sendERC20(address erc20address, address _to, uint amount) external returns(uint) {
        IERC20 erc20 = IERC20(erc20address);
        // approve contract first
        uint approvedAmountOfERC20Tokens = erc20.allowance(msg.sender(), address(this));
        require(approvedAmountOfERC20Tokens > amount , "Haven't approved enough tokens!");
        erc20.transferFrom(msg.sender(), address(this), amount);
        txnID += 1;
        erc20Txn memory txn = erc20Txn(erc20address, msg.sender(), _to, amount,block.timestamp);
        erc20Txns[txnID] = txn;        
        erc20Balances[msg.sender()] += amount;
        return txnID;
    }

 
    function claimERC20(uint _txnID, address erc20address) external {
        IERC20 erc20 = IERC20(erc20address);
        uint amount = erc20Txns[_txnID].amount;
        uint approvedAmountOfERC20Tokens = erc20.allowance(erc20Txns[_txnID].sender, address(this));
        require(approvedAmountOfERC20Tokens > amount , "Sender hasn't approved enough tokens!");
        require(claimedTxns[_txnID] != true, " Transaction is already claimed!");
        require(block.timestamp > (erc20Txns[_txnID].timestamp + txnExpiry), "Time Lock in place"); 
        erc20.transferFrom(address(this), msg.sender(), amount);
        claimedTxns[_txnID] = true ;
        erc20Balances[erc20Txns[_txnID].recipient] += amount;
        erc20Balances[erc20Txns[_txnID].sender] -= amount;
        }
    
    modifier onlyDeployer {
        require(msg.sender() == deployer,
        "Only the contract Deployer can call this function");
        _;
    }
}
