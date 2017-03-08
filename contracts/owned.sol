pragma solidity ^0.4.6;

// Define abstract utility contracts.
contract owned {
  address public owner;

  function owned() {
    owner = msg.sender;
  }

  modifier onlyOwner(){
    if (msg.sender != owner) throw;
    _;
  }

  function transferOwnership(address to) onlyOwner {
    owner = to;
  }
}
