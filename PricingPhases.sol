pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract PricingPhases is Ownable {
    using SafeMath for uint256;

    // Start time for default phase.
    uint256 public startTime;
    
    struct Phase {
        /** UNIX timestamp when this phase ends */
        uint256 endTime;
        uint256 rate;
        /** Available count of tokens for this phase */
        uint256 phaseTokensAvailable;
        uint256 phaseTokensSold;
    }

    /** Phase 0 is always (0, 0) */
    Phase[] public phases;

    //###### EVENTS ######
    event PhaseAdded(uint index, uint256 endTime, uint256 rate, uint256 phaseTokensAvailable);
    event PhaseUpdated(uint256 endTime, uint256 rate, uint256 phaseTokensAvailable);


    /**
     * @dev Get index of current phase or fallback to zero
     */
    function getCurrentPhaseIndex() public constant returns (uint8 phaseIndex) {
        phaseIndex = 0;
        uint8 i;

        for (i = 0; i < phases.length; i++) {
            if (now <= phases[i].endTime) {
                phaseIndex = i;
                return;
            }
        }
    }

    /** Public methods for external callers and unit tests */

    /**
     * @dev Return current phase attributes to external caller
     * @return Array of current phase properties
     */
    function getCurrentPhaseAttributes() public constant returns (uint256, uint256, uint256, uint256) {
        return getPhaseAttributes(getCurrentPhaseIndex());
    }

    /**
     * @dev Get selected phase attributes
     * @return Array of current phase properties
     */
    function getPhaseAttributes(uint _phaseIndex) public constant returns (uint256, uint256, uint256, uint256) {
        require(_phaseIndex < phases.length);

        return (
        phases[_phaseIndex].endTime,
        phases[_phaseIndex].rate,
        phases[_phaseIndex].phaseTokensAvailable,
        phases[_phaseIndex].phaseTokensSold
        );
    }

    /**
     * Add New Phase
     */
	function addNewPhase(uint256 endTime, uint256 rate, uint256 phaseTokensAvailable) public onlyOwner returns(bool) {
        return pushNewPhase(endTime, rate, phaseTokensAvailable);
	}

    function pushNewPhase(uint256 endTime, uint256 _rate, uint256 availableToken) internal returns (bool) {
        require(endTime>now);
        // Validate the Phase endTime - only allowing incremental phases
        uint lastPhaseIndex = phases.length; 
        if(lastPhaseIndex > 0){
            require(endTime>phases[lastPhaseIndex-1].endTime);
        }
        phases.push(Phase({endTime: endTime, rate:_rate, phaseTokensAvailable: availableToken, phaseTokensSold: 0}));
        PhaseAdded(phases.length, _rate, endTime, availableToken);
        return true;
    }


    /**
     * Update Phase
     */
    function updatePhase(uint index, uint256 endTime, uint256 rate,  uint256 phaseTokensAvailable) public onlyOwner returns(bool) {
        require(index < phases.length);
        require(index >= getCurrentPhaseIndex());
        require(phases[index].phaseTokensSold <= phaseTokensAvailable);
        phases[index].endTime = endTime;
        phases[index].rate = rate;
        phases[index].phaseTokensAvailable = phaseTokensAvailable;
        PhaseUpdated(endTime, rate, phaseTokensAvailable);
        return true;
	}

    /**
     * Get Phase Count
     */
	function getPhaseCount() public view returns(uint) {
		return phases.length;
	}

    // Override this method to have a way to add business logic to your crowdsale when buying
    function getTokenAmount(uint8 phaseIndex, uint256 weiAmount) public view returns(uint256 tokens) {
        tokens = 0;
        if(weiAmount > 0){
            tokens = weiAmount.mul(phases[phaseIndex].rate);
            if(!checkPurchaseAllowed(phaseIndex, tokens)){
                tokens = 0;
            }
        }
        return;
    }

    /**
     * Check Purchase Allowed
     */
	function checkPurchaseAllowed(uint8 phaseIndex, uint256 purchaseTokenAmount) internal view returns(bool) {
        uint256 sold = phases[phaseIndex].phaseTokensSold;
        uint256 limit = phases[phaseIndex].phaseTokensAvailable;

        return (now<phases[phaseIndex].endTime) && (sold.add(purchaseTokenAmount) <= limit);
	}
}
