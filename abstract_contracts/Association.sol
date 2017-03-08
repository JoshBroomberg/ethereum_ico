contract owned {
  address public owner;

  function owned()

  modifier onlyOwner()

  function transferOwnership(address to) onlyOwner
}

contract Association is owned {
  // State values

  // For proposals
  Proposal[] public proposals;
  // It is hard to query the length of a dynamic array, so a length tracker
  // is used as a public convenience.
  uint256 public numProposals;

  // For voting rules
  Token public sharesToken;
  uint256 public debateTimeInMinutes;
  uint256 public minimumQuorum;

  // Structs
  struct Proposal

  struct Vote

  modifier onlyShareholders

  // Constructor
  function Association(
    address sharesAddress,
    uint256 _debateTimeInMinutes,
    uint256 _minimumSharesToPassVote)

  function changeVotingRules(
      address sharesAddress,
      uint256 _debateTimeInMinutes,
      uint256 _minimumSharesToPassVote)
    onlyOwner

  function newProposal(
      address recipient,
      uint256 amount,
      string description,
      bytes transactionByteCode)
    onlyShareholders
    returns (uint proposalID)

  function validateProposal(
      uint proposalID,
      address recipient,
      uint256 amount,
      bytes transactionByteCode)
    constant
    returns (bool valid)

  function vote(uint proposalID, bool supportsProposal)
    onlyShareholders
    returns (uint voteID)

  function finalizeProposal(uint proposalID)
    onlyShareholders
    returns (bool proposalPassed)

  function executeProposal(uint proposalID, bytes transactionByteCode)
    onlyShareholders
    returns (bool proposalExecuted)
}
