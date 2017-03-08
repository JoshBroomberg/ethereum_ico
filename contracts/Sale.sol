pragma solidity ^0.4.6;

// From: https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts/Token.sol
contract AbstractToken {
  /* This is a slight change to the ERC20 base standard.
  function totalSupply() constant returns (uint256 supply);
  is replaced with:
  uint256 public totalSupply;
  This automatically creates a getter function for the totalSupply.
  This is moved to the base contract since public getter functions are not
  currently recognised as an implementation of the matching abstract
  function by the compiler.
  */
  /// total amount of tokens
  uint256 public totalSupply;

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant returns (uint256 balance);

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) returns (bool success);

  /* Custom Function */
  /// @notice create `_amount` of tokens and credit them to `_recipient`
  /// @param _recipient The address of the recipient
  /// @param _amount The amount of token to be created
  /// @return Whether the minting was successful or not
  function mint(address _recipient, uint256 _amount) returns (bool success);

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

  /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of tokens to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) returns (bool success);

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Sale {
  // We will pay funds to the association created.
  address public beneficiary;

  // Sale parameters
  uint public fundingGoal;
  uint public deadline;
  uint public pricePerToken;
  AbstractToken public rewardToken;

  modifier afterDeadline() {
    if (now < deadline) throw;
    _;
  }

  // Tracking variables
  mapping(address => uint256) public contributionOf; // Track contributors
  uint public amountRaised; //defaults to 0.
  bool fundingGoalReached = false;
  bool crowdsaleClosed = false;

  // Events
  event GoalReached(address beneficiary, uint amountRaised);
  event FundsReceived(address backer, uint amount);
  event FundsWithdrawal(address recipient, uint amount);

  function Sale(
    address _beneficiary,
    uint _fundingGoalInEthers,
    uint _durationInMinutes,
    uint _etherCostPerToken,
    address _rewardTokenAddress)
  {
    beneficiary = _beneficiary;
    fundingGoal = _fundingGoalInEthers * 1 ether;
    deadline = now + _durationInMinutes * 1 minutes;
    pricePerToken = _etherCostPerToken * 1 ether;
    rewardToken = AbstractToken(_rewardTokenAddress);
  }

  // This function is called when the contract is paid ether.
  function ()
    payable
  {
    // Contribution possible?
    // NOTE: what happens if contract is out of tokens?
    if (crowdsaleClosed) throw;

    uint amount = msg.value;
    contributionOf[msg.sender] = amount;
    amountRaised += amount;

    // Send correct amount of tokens to the contributor.
    rewardToken.mint(msg.sender, amount / pricePerToken);

    // Refund any ether not used to purchase whole tokens.
    msg.sender.send(amount % pricePerToken);

    FundsReceived(msg.sender, amount);
  }


  function checkGoalReached()
    afterDeadline
  {
    crowdsaleClosed = true;
    if (amountRaised >= fundingGoal){
      fundingGoalReached = true;
      GoalReached(beneficiary, amountRaised);
    }
  }

  // This function serves to functions. It allows contributors to safeWithdrawal
  // their money if the sale fails to reach its goal and it allows
  // the owner (or anyone) to transfer the funds raised to the beneficiary
  // if the sale succeedded.
  function withdraw()
    afterDeadline
  {
    // This function cannot be run before validating whether the goal was reached,
    // even if the deadline has passed.
    if (!crowdsaleClosed) throw;

    // Contributor withdrawing funds.
    if (!fundingGoalReached) {
      uint amount = contributionOf[msg.sender];

      if (amount > 0 && msg.sender.send(amount)) {
        FundsWithdrawal(msg.sender, amount);
        // NOTE: is this ok? Before, it was set to zero before the send, and then
        // reset to the original amount if the send failed.
        contributionOf[msg.sender] = 0;
      }
    }

    // NOTE: in the docs, this only runs if msg.sender is the beneficiary.
    // I don't understand this. Anyone should be able to trasnfer the full
    // funds to the association as per their expectations.
    if (fundingGoalReached) {
      if (beneficiary.send(amountRaised)) {
        FundsWithdrawal(beneficiary, amountRaised);
      } else {
        // If the send fails, unlock funders' balances
        fundingGoalReached = false;
      }
    }
  }
}
