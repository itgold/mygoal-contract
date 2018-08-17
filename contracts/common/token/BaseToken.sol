pragma solidity ^0.4.18;

import './ERC223Interface.sol';
import "./ERC20Interface.sol";
import './ERC223ReceivingContract.sol';
import "./Pausable.sol";
import "../math/SafeMath.sol";

/**
 * @title Reference implementation of the ERC223 standard token.
 */
contract BaseToken is ERC20Interface, ERC223Interface, Pausable {

    string public name;
    string public symbol;
    uint8 public decimals;
    string public version;

    uint public totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) internal allowed;

    using SafeMath for uint;

    // Function to access total supply of tokens .
    function totalSupply() public view returns (uint _totalSupply) {
        return totalSupply;
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _amount Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _amount, bytes _data, string _custom_fallback) public whenNotPaused returns (bool success) {
        if (isContract(_to)) {
            assertAndTransfer(msg.sender, _to, _amount);

            assert(_to.call.value(0)(bytes4(keccak256(abi.encodePacked(_custom_fallback))), msg.sender, _amount, _data));
            emit Transfer(msg.sender, _to, _amount, _data);
            return true;
        } else {
            return transferToAddress(_to, _amount, _data);
        }
    }

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _amount, bytes _data) public whenNotPaused returns (bool success) {
        if (isContract(_to)) {
            return transferToContract(_to, _amount, _data);
        } else {
            return transferToAddress(_to, _amount, _data);
        }
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn't contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _amount Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint _amount) public whenNotPaused returns (bool success) {
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        bytes memory empty_;
        if (isContract(_to)) {
            return transferToContract(_to, _amount, empty_);
        } else {
            return transferToAddress(_to, _amount, empty_);
        }
    }


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _amount uint the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint _amount) public whenNotPaused returns (bool) {
        require(_amount <= allowed[_from][msg.sender]);
        assertAndTransfer(msg.sender, _to, _amount);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _amount The amount of tokens to be spent.
     */
    function approve(address _spender, uint _amount) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public whenNotPaused view returns (uint) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
        uint oldValue_ = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue_) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue_.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function balanceOf(address _holder) public view returns (uint balance) {
        return balances[_holder];
    }

    function balanceMy() public constant returns (uint balance) {
        return balances[msg.sender];
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length_;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
            length_ := extcodesize(_addr)
        }
        return (length_ > 0);
    }

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _amount, bytes _data) private returns (bool success) {
        assertAndTransfer(msg.sender, _to, _amount);

        emit Transfer(msg.sender, _to, _amount, _data);
        return true;
    }

    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _amount, bytes _data) private returns (bool success) {
        assertAndTransfer(msg.sender, _to, _amount);

        ERC223ReceivingContract receiver_ = ERC223ReceivingContract(_to);
        receiver_.tokenFallback(msg.sender, _amount, _data);
        emit Transfer(msg.sender, _to, _amount, _data);
        return true;
    }

    function assertAndTransfer(address _from, address _to, uint _amount) private {
        require(_to != address(0));
        require(_amount <= balanceOf(_from));

        balances[_from] = balanceOf(_from).sub(_amount);
        balances[_to] = balanceOf(_to).add(_amount);
    }


}
