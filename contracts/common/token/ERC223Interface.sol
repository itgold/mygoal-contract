pragma solidity ^0.4.18;

contract ERC223Interface {

    function transfer(address _to, uint _amount, bytes _data) public returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint _amount, bytes _data);
}
