pragma solidity ^0.4.18;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Interface {

    event Transfer(address indexed _from, address indexed _to, uint _amount);
    event Approval(address indexed _tokenOwner, address indexed _spender, uint _amount);

    function balanceOf(address _tokenOwner) public view returns (uint);

    function totalSupply() public view returns (uint);

    function allowance(address _tokenOwner, address spender) public view returns (uint);

    function approve(address _spender, uint _amount) public returns (bool);

    function transfer(address _to, uint _amount) public returns (bool);

    function transferFrom(address _from, address _to, uint _amount) public returns (bool);
}