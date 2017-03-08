import "./owned.sol";

contract Token is owned {
  // Token details
  string public name = "EtherionLab Share";
  string public symbol = "ETS";
  uint8 public decimals = 0;
  uint256 public totalSupply;
  address public mintController;

  // Tracking balances
  mapping (address => uint256) public balanceOf;

  function Token(uint256 initialSupply)

  function mint(address recipient, uint256 amount)
    returns (bool success)

  function changeMinter(address newMinter) onlyOwner

  function transfer(address to, uint256 amount)
    returns (bool success)
}