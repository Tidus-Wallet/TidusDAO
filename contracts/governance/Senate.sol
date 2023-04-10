// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorTimelockControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @notice Import Positional NFTs
import "../ERC721/Censors.sol";
import "../ERC721/Consuls.sol";
import "../ERC721/Dictators.sol";
import "../ERC721/Senators.sol";
import "../ERC721/Tribunes.sol";

/**
 * @title Senate Smart Contract
 * @notice The Senate contract is a governance contract for TidusDAO, a Roman Republic inspired project.
 * @dev This contract includes various positions, veto powers, and a governance whitelist.
 * @custom:security-contact sekaieth@proton.me
 */
contract Senate is Initializable, GovernorUpgradeable, GovernorSettingsUpgradeable, GovernorCountingSimpleUpgradeable, GovernorVotesUpgradeable, GovernorTimelockControlUpgradeable, OwnableUpgradeable, UUPSUpgradeable {

    /// @dev Position enum to store the position of each address.
    enum Position {
        None,
        Censor,
        Consul,
        Dictator,
        Senator,
        Tribune
    }

    /// @dev VetoInfo struct to store veto-related information.
    struct VetoInfo {
        uint256 tribuneVetoes;
        uint256 consulVetoCount;
        mapping(address => bool) consulVetoes;
    }

    /// @dev Mapping to store the veto information for each proposal.
    mapping(uint256 => VetoInfo) public vetoes;

    /// @dev Mapping to store the governance whitelist status of each address.
    mapping(address => bool) public governanceWhitelist;

    /// @dev Address of the Timelock contract
    address public timelockContract;

    /// @dev The address of the SenateVoting contract.
    address public senateVotingContract;

    /// @dev The address of the Censors contract.
    address public censorsContract;

    /// @dev The address of the Consuls contract.
    address public consulsContract;

    /// @dev The address of the Dictators contract.
    address public dictatorsContract;

    /// @dev The address of the Senators contract.
    address public senatorsContract;

    /// @dev The address of the Tribunes contract.
    address public tribunesContract;

    /// @dev Quorum value for the Senate.
    uint16 public quorum;

    /// @dev Custom initializer modifier to disable standard initializers.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the Senate contract.
     * @param _token The voting token for the GovernorVotesUpgradeable.
     * @param _timelock The timelock controller for the GovernorTimelockControlUpgradeable.
     * @param _governanceWhitelist An array of addresses to be added to the governance whitelist.
     */
    function initialize(
        IVotesUpgradeable _token, 
        TimelockControllerUpgradeable _timelock,
        address[] memory _governanceWhitelist)
        initializer public
    {
        __Governor_init("Senate");
        __GovernorSettings_init(1 /* 1 block */, 21600 /* 3 days */, 0);
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);
        __GovernorTimelockControl_init(_timelock);
        __Ownable_init();
        __UUPSUpgradeable_init();
        timelockContract = address(_timelock);
        censorsContract = _governanceWhitelist[0];
        consulsContract = _governanceWhitelist[1];
        dictatorsContract = _governanceWhitelist[2];
        senatorsContract = _governanceWhitelist[3];
        tribunesContract = _governanceWhitelist[4];

    }


    /**
     * @notice Returns the required quorum for proposals.
     * @return The required quorum value.
     */
    function updateQuorum(uint16 _quorumValue) public pure returns (uint256) {
        quorum = _quorumValue; 
    }

    /**
     * @notice Authorizes an upgrade to the contract implementation.
     * @param newImplementation The address of the new contract implementation.
     * @dev This function can only be called by the contract owner.
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.
    /**
     * @notice Vote on a proposal with the specified support.
     * @dev Allows only users with a Senate position to vote on a proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support The type of support to give to the proposal (0 for "against", 1 for "for", 2 for "abstain").
     */
    function castVote(uint256 proposalId, uint8 support) public override(GovernorUpgradeable, IGovernorUpgradeable) returns (uint256) {
        // Check if the support value is valid (0 for "against", 1 for "for", or 2 for "abstain")
        require(support <= 2, "Senate: invalid support value");

        // Check if the proposal is currently in the Active state
        require(state(proposalId) == ProposalState.Active, "Senate: vote not currently active");

        // Check if the user has a valid Senate position
        require(getPosition(msg.sender) != Position.None, "Senate: Only senate positions can vote");

        // Cast the vote using the `_vote` function from the `GovernorUpgradeable` contract
        return _castVote(proposalId, msg.sender, support, "");
    }

    /**
     * @notice Returns the voting delay.
     * @return The voting delay value.
     */
    function votingDelay()
        public
        view
        override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingDelay();
    }


    /**
     * @notice Returns the voting period.
     * @return The voting period value.
     */
    function votingPeriod()
        public
        view
        override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingPeriod();
    }



    /**
     * @notice Allows a Tribune to veto a proposal that is in the Succeeded state.
     * @param proposalId The ID of the proposal to veto.
     * @dev This function requires that the caller is a Tribune and the proposal has not already been vetoed by a Tribune.
     */
    function tribuneVeto(uint256 proposalId) public {
        require(getPosition(msg.sender) == Position.Tribune, "Senate: Only Tribunes can use the tribune veto");
        ProposalState currentState = state(proposalId);
        require(currentState == ProposalState.Succeeded, "Senate: Proposal must be in the Succeeded state for a tribune veto");
        require(vetoes[proposalId].tribuneVetoes == 0, "Senate: Tribune veto already used for this proposal");

        vetoes[proposalId].tribuneVetoes += 1;
    }

    /**
     * @notice Allows a Consul to veto a proposal that is in the Succeeded or Defeated state.
     * @param proposalId The ID of the proposal to veto.
     * @dev This function requires that the caller is a Consul and the proposal has not already been vetoed twice by Consuls.
     */
    function consulVeto(uint256 proposalId) public {
        require(getPosition(msg.sender) == Position.Consul, "Senate: Only Consuls can use the consul veto");
        ProposalState currentState = state(proposalId);
        require(vetoes[proposalId].consulVetoes[msg.sender] == false, "Senate: Consul veto already used for this proposal");
        require(vetoes[proposalId].consulVetoCount < 2, "Senate: Both Consuls have already Vetoed");
        require(currentState == ProposalState.Succeeded || currentState == ProposalState.Defeated, "Senate: Proposal must be in the Succeeded or Defeated state for a consul veto");

        vetoes[proposalId].consulVetoCount += 1;
        vetoes[proposalId].consulVetoes[msg.sender] = true;
    }

    /**
     * @notice Checks all Positional contracts for a user's position.
     * @param user The address of the user to check.
     * @return The user's position.
     */
    function getPosition(address user) public view returns (Position) {
        if (Censors(censorsContract).isCensor(user)) {
            return Position.Censor;
        } else if (Consuls(consulsContract).isConsul(user)) {
            return Position.Consul;
        } else if (Dictators(dictatorsContract).isDictator(user)) {
            return Position.Dictator;
        } else if (Senators(senatorsContract).isSenator(user)) {
            return Position.Senator;
        } else if (Tribunes(tribunesContract).isTribune(user)) {
            return Position.Tribune;
        } else {
            return Position.None;
        }
    }

    /**
     * @notice Returns the state of a proposal, taking into account veto actions.
     * @param proposalId The ID of the proposal to query.
     * @return The current state of the proposal.
     * @dev This function overrides the state() function to include veto actions in the proposal state.
     */
    function state(uint256 proposalId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (ProposalState)
    {
        ProposalState currentState = super.state(proposalId);

        // If the proposal is not in the Succeeded or Defeated state, return the current state
        if (currentState != ProposalState.Succeeded && currentState != ProposalState.Defeated) {
            return currentState;
        }

        VetoInfo storage vetoInfo = vetoes[proposalId];

        // If there's a Tribune veto, the proposal is considered Defeated
        if (vetoInfo.tribuneVetoes > 0) {
            currentState = ProposalState.Defeated;
        }

        // If there's an odd number of Consul vetoes, the proposal state is reversed
        if (vetoInfo.consulVetoCount % 2 == 1) {
            return currentState == ProposalState.Succeeded ? ProposalState.Defeated : ProposalState.Succeeded;
        }

        return currentState;
    }

    /**
     * @dev Creates a proposal with the given targets, values, calldatas and description, if the sender has a valid position.
     * @param targets The contract addresses to call.
     * @param values The amounts of ETH to send with each call.
     * @param calldatas The calldata to send with each call.
     * @param description The description of the proposal.
     * @return The ID of the created proposal.
     * Reverts if the sender's position is not valid.
     */
    function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)
        public
        override(GovernorUpgradeable, IGovernorUpgradeable)
        returns (uint256)
    {
        require(getPosition(msg.sender) != Position.None, "Senate: Only valid positions can create proposals");
        return super.propose(targets, values, calldatas, description);
    }

    /**
     * @dev Gets the proposal threshold for the sender's position.
     * @return The proposal threshold.
     * Reverts if the sender's position is not valid.
     */
    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        Position position = getPosition(msg.sender);
        if (position == Position.Consul || position == Position.Dictator) {
            return 1;
        } else if (position == Position.Censor || position == Position.Tribune) {
            return 2;
        } else if (position == Position.Senator) {
            return 3;
        } else {
            return type(uint256).max; // Non-valid positions cannot create proposals
        }
    }

    /**
     * @dev Executes a proposal with the given ID, targets, values, calldatas and description hash.
     * Only the GovernorTimelockController can call this function.
     */
    function _execute(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    /**
     * @dev Cancels a proposal with the given targets, values, calldatas and description hash.
     * Only the GovernorTimelockController can call this function.
     * @return The ID of the cancelled proposal.
     */
    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    /**
     * @dev Returns the executor address for the timelock controller.
     * Only the GovernorTimelockController can call this function.
     * @return The executor address.
     */
    function _executor()
        internal
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (address)
    {
        return super._executor();
    }

    /**
     * @dev Checks whether the contract supports a given interface ID.
     * @param interfaceId The interface ID to check for support.
     * @return True if the contract supports the given interface ID, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Update the address of a given contract.
     * @param _contractAddress The address of the contract to update.
     * @param _newAddress The new address of the contract.
     * @notice Only a Senate proposal can update the address of a contract.
     */
    function updateContractAddress(address _contractAddress, address _newAddress) public {
        require(msg.sender == timelockContract, "Senate: Only a Senate proposal can update the address of a contract");
        require(_contractAddress != address(0), "Senate: Cannot update the address of the zero address");
        require(_newAddress != address(0), "Senate: Cannot update a contract to the zero address");

        if (_contractAddress == censorsContract) {
            censorsContract = _newAddress;
        } else if (_contractAddress == consulsContract) {
            consulsContract = _newAddress;
        } else if (_contractAddress == dictatorsContract) {
            dictatorsContract = _newAddress;
        } else if (_contractAddress == senatorsContract) {
            senatorsContract = _newAddress;
        } else if (_contractAddress == tribunesContract) {
            tribunesContract = _newAddress;
        } else {
            revert("Senate: Invalid contract address");
        }
    }

}
