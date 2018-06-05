pragma solidity ^0.4.18;

import "./Tokens/B4U.sol";
import "./PricingPhases.sol";

/**
 * @title B4UCrowdsale
 */
contract B4UCrowdsale is PricingPhases {
    using SafeMath for uint256; 

    // The token being sold
    StandardToken public token;


    // address where funds are collected
    address public wallet;


    // amount of raised money in wei
    uint256 public weiRaised;

    address public tokenOwner;

    bool public checkKYC;
    mapping (address => bool) public KYCWhitelist;

    // Investor Address -> Investment 
    mapping (address => uint256) public investedAmountOf;
    mapping (address => uint256) public investedTokenOf;    

    address public APIAdminAddress;

    //######### Modifiers #########
    modifier onlyAPIAdmin() {
        require(msg.sender == APIAdminAddress);
        _;
    }

    //######### EVENTS #########

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    event Whitelisted(address addr, bool status);

    function B4UCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _token, address _tokenOwner, uint256 _tokenAvailable) public {
        require(_startTime > 0);
        require(_endTime >= _startTime);
        // require(_rate > 0);
        require(_wallet != address(0));

        token = StandardToken(_token);
        
        wallet = _wallet;
        tokenOwner = _tokenOwner;
        APIAdminAddress = msg.sender;
        startTime = _startTime;
        super.pushNewPhase(_startTime,0,0);
        super.pushNewPhase(_endTime, _rate, _tokenAvailable);
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buy();
    }

    // low level token purchase function
    function buy() public payable {
        require(msg.sender != address(0));
        if(checkKYC && !KYCWhitelist[msg.sender]) {
            throw;
        }
        uint256 weiAmount = msg.value;
        require(weiAmount > 0);
        uint8 currentPhaseIndex = getCurrentPhaseIndex();
        // calculate token amount to be created
        uint256 tokens = getTokenAmount(currentPhaseIndex, weiAmount);

        // To verify Phase sale limit
        require(tokens != 0);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        investedAmountOf[msg.sender] = investedAmountOf[msg.sender].add(weiAmount);
        investedTokenOf[msg.sender] = investedTokenOf[msg.sender].add(tokens);
        
        // add tokens to phases token sold
        phases[currentPhaseIndex].phaseTokensSold = phases[currentPhaseIndex].phaseTokensSold.add(tokens);
        
        token.transferFrom(tokenOwner, msg.sender, tokens);
        
        TokenPurchase(msg.sender, weiAmount, tokens);

        forwardFunds();
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return checkPurchaseAllowed(getCurrentPhaseIndex(), uint256(0));
    }


    
    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function setKYCCheck(bool _bSet) public onlyOwner{
        checkKYC = _bSet;
    }

    function setAPIAdmin(address _newAPIAdmin) public onlyOwner {
        require(_newAPIAdmin != address(0));
        APIAdminAddress = _newAPIAdmin;
    }

    function setInvestorKYCWhitelist(address addr, bool status) public onlyAPIAdmin {
        KYCWhitelist[addr] = status;
        Whitelisted(addr, status);
    }
}
