pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";


/**
 * @title B4U
 * @dev Standard ERC20 Token, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract B4U is StandardToken {

	string public constant NAME = "BRICKS4US";
	string public constant SYMBOL = "B4U";
	uint8 public constant DECIMALS = 18;

	uint256 public constant INITIAL_SUPPLY = 100000000 * 10 ** 18;

	/**
	 * @dev Constructor that gives msg.sender all of existing tokens.
	 */
	function B4U() public {
		totalSupply_ = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
	}
}