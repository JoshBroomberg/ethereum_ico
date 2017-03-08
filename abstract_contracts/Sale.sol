contract Sale {
  // We will pay funds to the association created.
  address public beneficiary;

  // Sale parameters
  uint public fundingGoal;
  uint public deadline;
  uint public pricePerToken;
  AbstractToken public rewardToken;

  modifier afterDeadline()

  // Tracking variables
  mapping(address => uint256) public contributionOf;
  uint public amountRaised;
  bool fundingGoalReached = false;
  bool crowdsaleClosed = false;

  function Sale(
    address _beneficiary,
    uint _fundingGoalInEthers,
    uint _durationInMinutes,
    uint _etherCostPerToken,
    address _rewardTokenAddress)

  function participate() payable

  function checkGoalReached() afterDeadline

  function withdraw() afterDeadline
}

