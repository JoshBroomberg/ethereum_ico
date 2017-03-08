pragma solidity ^0.4.6;
import "./owned.sol";

contract Token is owned {
  // Token details
  string public name = "Etherion Share";
  string public symbol = "ETS";
  uint8 public decimals = 0;
  uint256 public totalSupply;
  address public mintController;

  // Tracking balances
  mapping (address => uint256) public balanceOf;

  // Events.
  event Mint(address indexed recipient, uint256 amount);
  event Transfer(address indexed from, address indexed to, uint256 amount);

  function Token(
      uint256 initialSupply)
  {
    balanceOf[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    Mint(msg.sender, initialSupply);
  }

  function mint(address recipient, uint256 amount) returns (bool success) {
    // Check overflow.
    if(balanceOf[recipient] + amount < balanceOf[recipient]) throw;

    balanceOf[recipient] += amount; // In case decimals == 8

    Mint(recipient, amount);
    return true;
  }

  function changeMinter(address newMinter) onlyOwner {
    mintController = newMinter;
  }

  function transfer(address to, uint256 amount) returns (bool success)
  {
    // Check balance of sender.
    if(balanceOf[msg.sender] < amount) throw;

    // Check overflow.
    if(balanceOf[to] + amount < balanceOf[to]) throw;

    balanceOf[msg.sender] -= amount;
    balanceOf[to] += amount;

    Transfer(msg.sender, to, amount);
    return true;
  }

  // This contract does not accept ether payments.
  function () {
    throw;
  }
}
