import "./owned.sol";

contract Association is owned {
  // Proposals
  Proposal[] public proposals;
  uint256 public numProposals;

  // Voting
  address public sharesToken;
  uint256 public debateTimeInMinutes;
  uint256 public minimumQuorum;

  // Structs
  struct Proposal

  struct Vote

  // Modifiers
  modifier onlyShareholders

  // Constructor
  function Association(
    address sharesAddress,
    uint256 _debateTimeInMinutes,
    uint256 _minimumSharesToPassVote)

  function newProposal(
      address recipient,
      uint256 amount,
      string description,
      bytes transactionByteCode)
    onlyShareholders
    returns (uint proposalID)

  function vote(uint proposalID, bool supportsProposal)
    onlyShareholders
    returns (uint voteID)

  function finalizeProposal(uint proposalID)
    onlyShareholders
    returns (bool proposalPassed)

  function executeProposal(uint proposalID, bytes transactionByteCode)
    onlyShareholders
    returns (bool proposalExecuted)

  function () payable
}
