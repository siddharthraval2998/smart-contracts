pragma solidity  >=0.7.0 <0.9.0;


//imports / interfaces - (IERC20, compund, aave, usdc etc.)
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "https://github.com/aave/protocol-v2/blob/master/contracts/protocol/configuration/LendingPoolAddressesProvider.sol";
import "https://github.com/aave/protocol-v2/blob/master/contracts/protocol/lendingpool/LendingPool.sol";
import "https://github.com/aave/protocol-v2/blob/master/contracts/protocol/tokenization/AToken.sol";
import "https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/IAToken.sol";


//compund genereic erc20 interface
interface CErc20 { // for generic acceptance
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function redeem(uint) external returns (uint);

    function supplyRatePerBlock() external returns (uint256);

    function redeemUnderlying(uint) external returns (uint);
}



// @devNote : programatically the mechanisms and formats for showing the interest rates of compound and aave are quite different and it might make more sense for the user to compare it himself and choose the corresponding function. 

contract interestVault {

    event MyLog(string, uint256); //helper 

    //constants - USDC, compund, aave address
    LendingPoolAddressesProvider provider;
    address erc20address; // assign required erc20 address here
    address aaveErc20address; // assign aToken address here
    LendingPool lendingPool;

    uint contract_balance = 0;
    
    
/* @devNote : 
deposit any erc20 to contract  -  use this function to add erc20 balance to this contract directly and manipulate it later (maybe   after comparing interest rates, using a simple deposit_to_highest_rate wrapper function which can call the specific deposit functions defined )

    function add_erc20_to_contract(address erc20address , uint amount) public {
        IERC20 erc20 = IERC20(erc20address);
        uint allowance = erc20.allowance(msg.sender,address(this));
        require(erc20.balanceOf(msg.sender) > amount, "insufficient funds!");
        require(allowance > amount, "You have not approved enough!");
        erc20.transferFrom(msg.sender, address(this), amount);
        

    }
*/
    
    function initializeAAVE (address _provider, address _aaveErc20address) public {  // call this function Before using aave functions
        provider = LendingPoolAddressesProvider(_provider); // enter the provider address on required network
        lendingPool = LendingPool(provider.getLendingPool() );
        aaveErc20address = _aaveErc20address;

    }
    
    
    // aave deposit and withdraw functions.
    function deposit_erc20_aave(address _erc20address, uint amount) public {    // enter the required erc20 address eg. DAI USDc etc
        lendingPool.deposit(_erc20address, amount, msg.sender, 0);
    }

    function withdraw_erc20_aave(address _erc20address, uint amount) public {
        lendingPool.withdraw(_erc20address, amount, msg.sender);
    }


    // compound deposit and redeem functions
    function supplyErc20ToCompound(address erc20address,address cErc20address,uint256 amount) public returns (uint) {

        // instance of the desired erc20 token, eg DAI, USDc 
        IERC20 erc20 = IERC20(erc20address);

        // instance of cToken contract, like cDAI
        CErc20 cToken = CErc20(cErc20address);

        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        emit MyLog("Supply Rate: (scaled up by 1e18)", supplyRateMantissa);

        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up): ", exchangeRateMantissa);
        // Amount of current exchange rate from cToken to underlying

        // Approve transfer on the ERC20 contract
        erc20.approve(cErc20address, amount);

        // Mint cTokens
        uint mintResult = cToken.mint(amount);
        return mintResult;
    }

    function redeemCErc20TokensCompound(uint256 amount,bool redeemType,address cErc20address) public returns (bool) {
        CErc20 cToken = CErc20(cErc20address);

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve cTokens
            redeemResult = cToken.redeem(amount);
        } else {
            // Retrieve underlying asset
            redeemResult = cToken.redeemUnderlying(amount);
        }
        emit MyLog("If this is not 0, there was an error", redeemResult);
        return true;
    }


}
