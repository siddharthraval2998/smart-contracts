// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract InheritanceVault is AccessControl {

    // Roles provides more flexibility than using something like OZ - Ownable
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant HEIR_ROLE = keccak256("HEIR_ROLE");

    address public owner;
    address public heir;

    uint256 public lastWithdrawalTime;
    uint256 public constant INACTIVITY_PERIOD = 30 seconds; // 30 seconds for quick testing. 

    // Consider indexing more of the event params to search through them later.  
    event HeirChanged(address oldHeir, address nextHeir);
    event Deposit(address sender, uint256 amount);
    event Withdrawal(address owner, uint256 amount);
    event InheritanceClaimed(address indexed oldOwner, address indexed newOwner, address indexed nextOwner);

    constructor(address _heir) payable {
        require(_heir != address(0) && _heir != msg.sender, "There must ALWAYS be an Heir to the throne!");

        // Grant default admin and owner roles to the deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);
        
        owner = msg.sender;
        heir = _heir;

        // Grant the HEIR_ROLE to the specified heir
        _grantRole(HEIR_ROLE, _heir);

        // Make the OWNER_ROLE the admin of HEIR_ROLE, so the owner can change heirs
        _setRoleAdmin(HEIR_ROLE, OWNER_ROLE);

        lastWithdrawalTime = block.timestamp;
    }

    // Ensure ability to recieve funds 
    receive() external payable {}
    fallback() external payable {}

    function deposit() external payable onlyRole(OWNER_ROLE) {
            require(msg.value > 0, "0 Value deposit. Please send a lot more.");
            emit Deposit(msg.sender, msg.value);
    }

    // Allows the owner to withdraw funds. Withdrawing 0 resets the timer without transferring ETH.
    // Notice - granular withdrawals instead of emptying contract (more realistic)
    function withdraw(uint256 amount) external onlyRole(OWNER_ROLE) {
        require(amount <= address(this).balance, "Insufficient balance");

        // Reset timer
        lastWithdrawalTime = block.timestamp;

        // Using send function instead of transfer to have more error info.  
        if (amount > 0) {
            bool success = payable(owner).send(amount);
            require(success, "Transfer failed");
        }

        emit Withdrawal(owner, amount);
    }


    // Allows the heir to claim inheritance if no withdrawals are made for INACTIVITY_PERIOD.
    // Notice Claiming the inheritance, you must also name an heir and it CANNOT be yourself. 
    function claimInheritance(address nextHeir) external onlyRole(HEIR_ROLE) {
        require(block.timestamp > lastWithdrawalTime + INACTIVITY_PERIOD, "Owner still active");
        require(nextHeir != address(0) && nextHeir != msg.sender, "There must ALWAYS be an Heir to the throne!");
        address oldOwner = owner;

        // Revoke OWNER_ROLE from oldOwner and grant it to msg.sender (the heir)
        _revokeRole(OWNER_ROLE, oldOwner);
        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(HEIR_ROLE, nextHeir);

        owner = msg.sender;

        emit InheritanceClaimed(oldOwner, msg.sender, nextHeir);
        emit HeirChanged(msg.sender, nextHeir);
    }


    // Provides a mechanism for changing heirs apart from claims (in case your heir pissed you off).
    function changeHeir(address nextHeir) external onlyRole(OWNER_ROLE) {
        require(nextHeir != address(0) && nextHeir != msg.sender, "There must ALWAYS be an Heir to the throne!");

        address oldHeir = heir;

        // Revoke the old heir's role and grant HEIR_ROLE to the new heir
        _revokeRole(HEIR_ROLE, oldHeir);
        _grantRole(HEIR_ROLE, nextHeir);

        heir = nextHeir;
        
        emit HeirChanged(oldHeir, nextHeir);
    }


    // Returns the time (in seconds) left for the timeout.
    function timeUntilHeirCanClaim() external view returns (uint256) {
        if (block.timestamp >= lastWithdrawalTime + INACTIVITY_PERIOD) {
            return 0;
        } else {
            return (lastWithdrawalTime + INACTIVITY_PERIOD) - block.timestamp;
        }
    }

    // Returns the balance of the contract.
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }
}
