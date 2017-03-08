contract Token {
  // Token details 
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  address public mintController;
  
  // Tracking balances
  mapping (address => uint256) public balanceOf;

  function Token(
      string name,
      string symbol,
      uint8 decimals,
      uint256 initialSupply,
      address mintController)

  function mint(address recipient, uint256 amount)
    returns (bool success)

  function transfer(address to, uint256 amount)
    returns (bool success)
} 