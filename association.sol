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

contract etherRecipient {
  event ReceivedEther(address from, uint256 amount);

  function () payable {
    ReceivedEther(msg.sender, msg.value);
  }

}

contract Token {
  mapping (address => uint256) public balanceOf;
  function transferFrom(address to, address from, uint amount) returns (bool success);   
}

contract Association is owned, etherRecipient {
  // Proposals state values
  Proposal[] public proposals;
  uint256 public numProposals;

  // Voting state values.
  Token public sharesToken;
  uint256 public debateTimeInMinutes;
  uint256 public minimumQuorum;
  
  // Structs

  struct Proposal {
    // Identifiers.
    address recipient;
    uint256 amount;
    string description;
    bytes32 proposalHash;

    // Voting.
    Vote[] votes;
    uint256 numVotes; 
    uint votingDeadline;
    mapping (address => bool) voted;

    // Results.
    bool finalized;
    bool passed;
    bool executed;
  }

  struct Vote {
    address voter;
    bool supportsProposal;
  }

  // Modifiers
  modifier onlyShareholders {
    if (sharesToken.balanceOf(msg.sender) == 0) throw;
    _;
  }

  // Events
  event ProposalMade(address recipient, uint256 amount, string description);
  event ProposalTallied(uint proposalID, bool finalized, bool passed, bool executed);
  event Voted(address voter, uint proposalID, bool supported);
  event ChangeOfRules(address sharesAddress, uint256 debateTimeInMinutes, uint256 minimumQuorum);
  
  // Constructor
  function Association(
    Token sharesAddress,
    uint256 debateTimeInMinutes,
    uint256 minimumSharesToPassVote
    ) {
    changeVotingRules(sharesAddress, debateTimeInMinutes, minimumSharesToPassVote);
  }

  // TODO: create mechanism for these changes to be altered
  // via a proposal mechanism.
  function changeVotingRules (
    Token sharesAddress,
    uint256 debateTimeInMinutes,
    uint256 minimumSharesToPassVote
    ) onlyOwner {
    
    // NOTE: new Token contract at new address.
    sharesToken = Token(sharesAddress);
    if (minimumSharesToPassVote <= 0) minimumSharesToPassVote = 1;
    debateTimeInMinutes = debateTimeInMinutes;
    minimumQuorum = minimumSharesToPassVote;

    // Fire event.
    ChangeOfRules(sharesAddress, debateTimeInMinutes, minimumQuorum);
  }

  function newProposal(
      address recipient,
      uint256 amount,
      string description,
      bytes transactionByteCode
    )
    onlyShareholders
    returns (uint proposalID) {

    // Create proposal
    proposalID = proposals.length++;
    Proposal p = proposals[proposalID];
    p.recipient = recipient;
    p.amount = amount;
    p.description = description;
    p.proposalHash = sha3(recipient, amount, transactionByteCode);
    p.finalized = false;
    p.executed = false;
    p.passed = false;
    p.numVotes = 0;
    p.votingDeadline = now + (debateTimeInMinutes * 1 minutes);

    // Track and fire events.
    ProposalMade(recipient, amount, description);
    numProposals = proposalID + 1;

    return proposalID;
  }

  function validateProposal(
      uint proposalID,
      address recipient,
      uint256 amount,
      bytes transactionByteCode
    )
    constant
    returns (bool valid) {
      Proposal p = proposals[proposalID];
      return (p.proposalHash == sha3(recipient, amount, transactionByteCode));
  }

  function vote(
    uint proposalID,
    bool supportsProposal
    )
    onlyShareholders
    returns (uint voteID) {

    Proposal p = proposals[proposalID];
    
    // Validate vote allowed
    if (
      p.voted[msg.sender] == true
      || p.finalized == true
    ) throw;
    
    voteID = p.votes.length++;
    // NOTE: notice different format of struct creation.
    p.votes[voteID] = Vote({voter: msg.sender, supportsProposal: supportsProposal});

    // Track vote
    p.voted[msg.sender] = true;
    p.numVotes = voteID + 1;
    Voted(msg.sender, proposalID, supportsProposal);
    return voteID;
  }

  function executeProposal(
      uint proposalID,
      bytes transactionByteCode
    )
  onlyShareholders 
  returns (bool executed) {
    Proposal p = proposals[proposalID];

    // Verify execution allowed
    if (
      now < p.votingDeadline
      || p.executed
      || p.proposalHash != sha3(p.recipient, p.amount, transactionByteCode)
      ) throw;

    // Tally votes
    uint yesVotes = 0;
    uint noVotes = 0;

    for(uint i = 0; i < p.votes.length; ++i) {
      Vote v = p.votes[i];
      uint weight = sharesToken.balanceOf(v.voter);
      if(v.supportsProposal == true) {
        yesVotes += weight;
      } else {
        noVotes += weight;
      }
    }

    // Determine result
    p.finalized = true;
    if (yesVotes + noVotes < minimumQuorum) {
      if (yesVotes > noVotes) {
        p.passed = true;

        // NOTE: explain the transaction bytes in this?
        if (p.recipient.call.value(p.amount * 1 ether)(transactionByteCode)){
          p.executed = true;
        }
      }
    }

    ProposalTallied(proposalID, p.finalized, p.passed, p.executed);
    return p.executed;
  }
}