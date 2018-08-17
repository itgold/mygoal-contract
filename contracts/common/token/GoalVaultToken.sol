pragma solidity ^0.4.18;

import "./BaseToken.sol";

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract GoalVaultToken is BaseToken {

    mapping(address => uint) goalVault;
    mapping(address => uint) charityVault;

    event GoalDeposited(address indexed _burner, uint _amount, uint _vaultBalance);
    event GoalRecovered(address indexed _burner, uint _amount, uint _vaultBalance);
    event GoalBurned(address indexed _burner, uint _amount, uint _vaultBalance);
    event GoalCharity(address indexed _burner, address charity, uint _amount, uint _vaultBalance);

    /**
     * @dev Reserves specific amount of tokens as a goal
     * @param _amount The amount of goal commitment tokens.
     */
    function depositGoal(uint _amount) whenNotPaused public {
        require(_amount <= balances[msg.sender]);

        address burner_ = msg.sender;
        goalVault[burner_] = goalVault[burner_].add(_amount);
        balances[burner_] = balances[burner_].sub(_amount);

        emit GoalDeposited(burner_, _amount, goalVault[burner_]);
    }

    /**
     * @dev Recovers goal vault for a given user.
     * @param _burner user's goal vault to recover.
     */
    function recoverGoal(address _burner) onlyOwner whenNotPaused public {
        //get player's balance
        uint vaultBalance_ = goalVault[_burner];

        recoverGoalAmount(_burner, vaultBalance_);
    }

    function recoverGoalAmount(address _burner, uint256 _amount) onlyOwner whenNotPaused public {
        //get player's balance
        uint vaultBalance_ = goalVault[_burner];
        require(vaultBalance_ >= _amount);

        goalVault[_burner] = goalVault[_burner].sub(_amount);
        balances[_burner] = balances[_burner].add(_amount);

        emit GoalRecovered(_burner, _amount, goalVault[_burner]);
    }

    /**
     * @dev burns user's goal vault.
     * @param _burner user which vault will be affected.
     */
    function burnGoal(address _burner) onlyOwner whenNotPaused public {
        uint burnerBalance_ = goalVault[_burner];

        burnGoalAmount(_burner, burnerBalance_);
    }

    /**
     * @dev burns given amount from user's goal vault.
     * @param _burner affected user.
     * @param _amount The amount of tokens to burn.
     */
    function burnGoalAmount(address _burner, uint256 _amount) onlyOwner whenNotPaused public {
        uint burnerBalance_ = goalVault[_burner];
        require(burnerBalance_ >= _amount);

        goalVault[_burner] = goalVault[_burner].sub(_amount);
        totalSupply = totalSupply.sub(burnerBalance_);

        emit GoalBurned(_burner, _amount, goalVault[_burner]);
    }

    function donateGoalToCharity(address _burner, uint256 _amount, address _charityAddress) whenNotPaused public {
        uint burnerVaultBalance_ = goalVault[_burner];
        require(burnerVaultBalance_ >= _amount);

        goalVault[_burner] = goalVault[_burner].sub(_amount);
        charityVault[_charityAddress] = goalVault[_charityAddress].add(_amount);

        emit GoalCharity(_burner, _charityAddress, _amount, goalVault[_burner]);
    }

    function goalBalanceOf(address _owner) public constant returns (uint userBalance) {
        return goalVault[_owner];
    }

    function goalBalanceMy() public constant returns (uint userBalance) {
        return goalVault[msg.sender];
    }
}
