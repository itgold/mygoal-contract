pragma solidity ^0.4.18;

import "./common/token/GoalVaultToken.sol";

contract MyGoalToken is GoalVaultToken {

    constructor() public {
        name = "Goal Token";
        symbol = "GOAL";
        decimals = 18;
        version = 'GOAL-1.0';

        totalSupply = 15000000000 * 1000000000000000000;
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    /**
     * Don't expect to just send in money and get tokens.
     */
    function() public payable {
        revert();
    }

}
