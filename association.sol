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

contract Association is owned {
  // State values

  // For proposals
  Proposal[] public proposals;
  // It is hard to query the length of a dynamic array, so a length tracker
  // is used as a public convenience.
  uint256 public numProposals;

  // For voting rules
  AbstractToken public sharesToken;
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
  event ProposalTallied(uint proposalID, bool finalized, bool passed);
  event ProposalExecuted(uint proposalID, bool passed, bool executed);
  event Voted(address voter, uint proposalID, bool supported);
  event ChangeOfRules(address sharesAddress, uint256 debateTimeInMinutes, uint256 minimumQuorum);
  event ReceivedEther(address from, uint256 amount);
  
  // Constructor
  function Association(
    AbstractToken sharesAddress,
    uint256 debateTimeInMinutes,
    uint256 minimumSharesToPassVote)
  {
    changeVotingRules(sharesAddress, debateTimeInMinutes, minimumSharesToPassVote);
  }

  // TODO: create mechanism for these changes to be altered
  // via a proposal mechanism instead of relying on owner.
  // This function will still be used, but the contract's owner will change.
  // This is how ethereum can be made dynamic.
  function changeVotingRules(
      AbstractToken sharesAddress,
      uint256 debateTimeInMinutes,
      uint256 minimumSharesToPassVote)
    onlyOwner
  { 
    // A contract instance is created using the AbstractToken's ABI (Application Binary Interface)
    // Calls to this object go to the contract at the address provided.
    sharesToken = AbstractToken(sharesAddress);
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
      bytes transactionByteCode)
    onlyShareholders
    returns (uint proposalID)
  {

    // Create proposal
    proposalID = proposals.length++;
    Proposal p = proposals[proposalID];
    p.recipient = recipient;
    p.amount = amount;
    p.description = description;

    // Transaction byte code is not stored, rather a hash is created and then
    // the code is resupplied and validated at proposal execution time.
    // This saves on storage.
    p.proposalHash = sha3(recipient, amount, transactionByteCode);
    
    // Technically, these are not necessary because the default is false.
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
      bytes transactionByteCode)
    // The constant modifier guarentees you are not changing the state of the blockchain.
    // All functions designed to be called externally should include this.
    constant
    returns (bool valid)
  {
      Proposal p = proposals[proposalID];
      return (p.proposalHash == sha3(recipient, amount, transactionByteCode));
  }

  function vote(uint proposalID, bool supportsProposal)
    onlyShareholders
    returns (uint voteID)
  {

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

  function finalizeProposal(uint proposalID)
    onlyShareholders
    returns (bool proposalPassed)
  {
    Proposal p = proposals[proposalID];

    // Verify finalization allowed
    if (now < p.votingDeadline || p.executed) throw;
    p.finalized = true;

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

    // Determine result.
    if ((yesVotes + noVotes >= minimumQuorum) && (yesVotes > noVotes)) {
      p.passed = true;
    }

    ProposalTallied(proposalID, p.finalized, p.passed);
    return p.passed;
  }

  function executeProposal(uint proposalID, bytes transactionByteCode)
    onlyShareholders
    returns (bool proposalExecuted)
  {
    Proposal p = proposals[proposalID];
    
    if (!(p.finalized && p.passed)) throw;
    
    // This is a confusing line of code. Call is used to call another function via its byte-encoded signature.
    // call.value returns the call function, but, when used, it will send ether with the call.
    // We then supply the byte code to be executed.

    // To execute, the function called will have to be payable. If we want to just pay, we would use bytecode: 0x
    // to call the default function of the recipient.

    // Call will mean that this contract is the message sender. The function called must be accessible to 
    // this contract.
    if (p.recipient.call.value(p.amount * 1 ether)(transactionByteCode)){
      p.executed = true;
    }
    
    ProposalExecuted(proposalID, p.passed, p.executed);
    return p.executed;
  }

  function ()
    payable
  {
    ReceivedEther(msg.sender, msg.value);
  }
}