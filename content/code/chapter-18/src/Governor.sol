// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IVotes
/// @notice Interface for voting power tracking
interface IVotes {
    function getVotes(address account) external view returns (uint256);
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);
    function delegates(address account) external view returns (address);
    function delegate(address delegatee) external;
}

/// @title Governor
/// @notice Simplified governance contract inspired by OpenZeppelin Governor
/// @dev Educational implementation demonstrating core governance mechanics
contract Governor {
    /// @notice Proposal states
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice Proposal data
    struct Proposal {
        uint256 id;
        address proposer;
        uint256 eta;                // Execution time (for timelock)
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool canceled;
        bool executed;
        mapping(address => Receipt) receipts;
    }

    /// @notice Vote receipt
    struct Receipt {
        bool hasVoted;
        uint8 support;      // 0 = against, 1 = for, 2 = abstain
        uint256 votes;
    }

    /// @notice Vote types
    uint8 public constant VOTE_AGAINST = 0;
    uint8 public constant VOTE_FOR = 1;
    uint8 public constant VOTE_ABSTAIN = 2;

    /// @notice Governance token
    IVotes public immutable token;

    /// @notice Timelock for execution delay
    address public timelock;

    /// @notice Voting delay (blocks after proposal until voting starts)
    uint256 public votingDelay;

    /// @notice Voting period (blocks)
    uint256 public votingPeriod;

    /// @notice Proposal threshold (tokens needed to create proposal)
    uint256 public proposalThreshold;

    /// @notice Quorum (minimum votes for validity)
    uint256 public quorumNumerator;
    uint256 public constant QUORUM_DENOMINATOR = 100;

    /// @notice Proposals
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    /// @notice Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );
    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        uint8 support,
        uint256 weight,
        string reason
    );
    event ProposalCanceled(uint256 indexed proposalId);
    event ProposalQueued(uint256 indexed proposalId, uint256 eta);
    event ProposalExecuted(uint256 indexed proposalId);

    /// @notice Errors
    error ProposalNotActive();
    error ProposalNotSucceeded();
    error ProposalAlreadyExecuted();
    error ProposalNotQueued();
    error TimelockNotReached();
    error BelowProposalThreshold();
    error AlreadyVoted();
    error InvalidVoteType();
    error InvalidProposal();

    constructor(
        address _token,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _proposalThreshold,
        uint256 _quorumNumerator
    ) {
        token = IVotes(_token);
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        proposalThreshold = _proposalThreshold;
        quorumNumerator = _quorumNumerator;
    }

    /// @notice Set timelock address
    function setTimelock(address _timelock) external {
        require(timelock == address(0), "Already set");
        timelock = _timelock;
    }

    /// @notice Create a new proposal
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256) {
        if (token.getVotes(msg.sender) < proposalThreshold) {
            revert BelowProposalThreshold();
        }

        if (targets.length == 0 || targets.length != values.length || targets.length != calldatas.length) {
            revert InvalidProposal();
        }

        uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        Proposal storage proposal = proposals[proposalId];
        require(proposal.startBlock == 0, "Proposal exists");

        uint256 startBlock = block.number + votingDelay;
        uint256 endBlock = startBlock + votingPeriod;

        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.targets = targets;
        proposal.values = values;
        proposal.calldatas = calldatas;
        proposal.startBlock = startBlock;
        proposal.endBlock = endBlock;

        proposalCount++;

        emit ProposalCreated(proposalId, msg.sender, targets, values, calldatas, startBlock, endBlock, description);

        return proposalId;
    }

    /// @notice Cast a vote
    function castVote(uint256 proposalId, uint8 support) external returns (uint256) {
        return _castVote(proposalId, msg.sender, support, "");
    }

    /// @notice Cast a vote with reason
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external returns (uint256) {
        return _castVote(proposalId, msg.sender, support, reason);
    }

    /// @notice Internal vote casting
    function _castVote(
        uint256 proposalId,
        address voter,
        uint8 support,
        string memory reason
    ) internal returns (uint256 weight) {
        Proposal storage proposal = proposals[proposalId];

        if (state(proposalId) != ProposalState.Active) {
            revert ProposalNotActive();
        }

        if (support > 2) revert InvalidVoteType();

        Receipt storage receipt = proposal.receipts[voter];
        if (receipt.hasVoted) revert AlreadyVoted();

        weight = token.getPastVotes(voter, proposal.startBlock);

        if (support == VOTE_AGAINST) {
            proposal.againstVotes += weight;
        } else if (support == VOTE_FOR) {
            proposal.forVotes += weight;
        } else {
            proposal.abstainVotes += weight;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = weight;

        emit VoteCast(voter, proposalId, support, weight, reason);
    }

    /// @notice Queue proposal for execution
    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        if (state(proposalId) != ProposalState.Succeeded) {
            revert ProposalNotSucceeded();
        }

        uint256 eta = block.timestamp + 2 days; // Timelock delay
        proposals[proposalId].eta = eta;

        emit ProposalQueued(proposalId, eta);

        return proposalId;
    }

    /// @notice Execute a queued proposal
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external payable returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        ProposalState currentState = state(proposalId);
        if (currentState != ProposalState.Queued) {
            revert ProposalNotQueued();
        }

        Proposal storage proposal = proposals[proposalId];
        if (block.timestamp < proposal.eta) {
            revert TimelockNotReached();
        }

        proposal.executed = true;

        // Execute all calls
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            if (!success) {
                if (returndata.length > 0) {
                    assembly {
                        revert(add(32, returndata), mload(returndata))
                    }
                }
                revert("Execution failed");
            }
        }

        emit ProposalExecuted(proposalId);

        return proposalId;
    }

    /// @notice Cancel a proposal
    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        Proposal storage proposal = proposals[proposalId];

        require(
            msg.sender == proposal.proposer ||
            token.getVotes(proposal.proposer) < proposalThreshold,
            "Cannot cancel"
        );

        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    /// @notice Get proposal state
    function state(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (proposal.startBlock == 0) {
            revert InvalidProposal();
        }

        if (block.number < proposal.startBlock) {
            return ProposalState.Pending;
        }

        if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        }

        if (_quorumReached(proposalId) && _voteSucceeded(proposalId)) {
            if (proposal.eta == 0) {
                return ProposalState.Succeeded;
            }
            if (block.timestamp >= proposal.eta + 14 days) {
                return ProposalState.Expired;
            }
            return ProposalState.Queued;
        }

        return ProposalState.Defeated;
    }

    /// @notice Check if quorum is reached
    function _quorumReached(uint256 proposalId) internal view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        uint256 totalSupply = token.getPastTotalSupply(proposal.startBlock);
        uint256 quorum = (totalSupply * quorumNumerator) / QUORUM_DENOMINATOR;
        return proposal.forVotes + proposal.abstainVotes >= quorum;
    }

    /// @notice Check if vote succeeded
    function _voteSucceeded(uint256 proposalId) internal view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        return proposal.forVotes > proposal.againstVotes;
    }

    /// @notice Hash proposal parameters
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash)));
    }

    /// @notice Get quorum for a block
    function quorum(uint256 blockNumber) external view returns (uint256) {
        return (token.getPastTotalSupply(blockNumber) * quorumNumerator) / QUORUM_DENOMINATOR;
    }

    /// @notice Get vote receipt
    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    /// @notice Check if account has voted
    function hasVoted(uint256 proposalId, address account) external view returns (bool) {
        return proposals[proposalId].receipts[account].hasVoted;
    }

    /// @notice Get proposal votes
    function proposalVotes(uint256 proposalId) external view returns (
        uint256 againstVotes,
        uint256 forVotes,
        uint256 abstainVotes
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.againstVotes, proposal.forVotes, proposal.abstainVotes);
    }
}

/// @title GovernanceToken
/// @notice ERC-20 token with voting capabilities
contract GovernanceToken is IVotes {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => address) private _delegates;

    /// @notice Checkpoints for vote tracking
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        _mint(msg.sender, _totalSupply);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        _moveVotingPower(delegates(from), delegates(to), amount);

        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
        _moveVotingPower(address(0), delegates(to), amount);

        emit Transfer(address(0), to, amount);
    }

    /// @inheritdoc IVotes
    function delegates(address account) public view override returns (address) {
        address delegate = _delegates[account];
        return delegate == address(0) ? account : delegate;
    }

    /// @inheritdoc IVotes
    function delegate(address delegatee) external override {
        address oldDelegate = delegates(msg.sender);
        _delegates[msg.sender] = delegatee;

        emit DelegateChanged(msg.sender, oldDelegate, delegatee);
        _moveVotingPower(oldDelegate, delegatee, balanceOf[msg.sender]);
    }

    /// @inheritdoc IVotes
    function getVotes(address account) public view override returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /// @inheritdoc IVotes
    function getPastVotes(address account, uint256 blockNumber) public view override returns (uint256) {
        require(blockNumber < block.number, "Block not mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /// @inheritdoc IVotes
    function getPastTotalSupply(uint256 blockNumber) public view override returns (uint256) {
        require(blockNumber < block.number, "Block not mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        uint256 length = ckpts.length;
        if (length == 0) return 0;

        if (ckpts[length - 1].fromBlock <= blockNumber) {
            return ckpts[length - 1].votes;
        }

        if (ckpts[0].fromBlock > blockNumber) {
            return 0;
        }

        // Binary search
        uint256 low = 0;
        uint256 high = length - 1;

        while (low < high) {
            uint256 mid = (low + high + 1) / 2;
            if (ckpts[mid].fromBlock <= blockNumber) {
                low = mid;
            } else {
                high = mid - 1;
            }
        }

        return ckpts[low].votes;
    }

    function _moveVotingPower(address src, address dst, uint256 amount) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _sub, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;

        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = uint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: uint32(block.number), votes: uint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _sub(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
}
