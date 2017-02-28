pragma solidity ^0.4.6;

contract Token {
  // Initialisation constants.
  string public standard = "Token 0.1";
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  
  // State variables.
  mapping (address => uint256) public balanceOf;

  // Events.

  event Transfer(address indexed from, address indexed to, uint256 amount);

  function Token(
      string name,
      string symbol,
      uint8 decimals,
      uint256 initialSupply
    ){
    balanceOf[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    name = name;
    symbol = symbol;
    decimals = decimals;
  }

  function transfer(address to, uint256 amount){
    // Check balance of sender.
    if(balanceOf[msg.sender] < amount) throw;

    // Check overflow.
    if(balanceOf[to] + amount < balanceOf[to]) throw;

    balanceOf[msg.sender] -= amount;
    balanceOf[to] += amount;

    Transfer(msg.sender, to, amount);
  }

  function () {
    throw;
  }

} 