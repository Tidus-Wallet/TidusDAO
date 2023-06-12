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
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../../lib/forge-std/src/console.sol";
import { ISenate } from "./interfaces";
import {ISenatePositions} from "../ERC721/interfaces/ISenatePositions.sol";

/**
 * @title Senate Smart Contract
 * @notice The Senate contract is a governance contract for TidusDAO, a Roman Republic inspired project.
 * @notice This contract includes various positions, veto powers, and a governance whitelist.
 * @custom:security-contact sekaieth@proton.me
 */

contract Senate is
    Initializable,
    GovernorUpgradeable,
    GovernorSettingsUpgradeable,
    GovernorCountingSimpleUpgradeable,
    GovernorVotesUpgradeable,
    GovernorTimelockControlUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ISenate
{
    /**
     * @notice Positions available to the Senate members.  See ISenatePositions for the enum definitions.
     * @notice None - No position.  Should not be valid for any voting, minting, or burning operations
     * @notice Consul - There should only ever be 2 consuls at any point in time.  Consuls are senators with veto power.
     * @notice Consul(cont'd) - Consuls can veto proposals that are Succeeded, they can veto each other, and they can veto tribunes
     * @notice Censor - Censors are not actually implemented in the TidusDAO, but others may use them
     * @notice Tribune - Tribunes represent the plebians and take House proposals and put them on the Senate floor with a proposal. 
     * @notice Senator - Senators are the main voting body of the DAO.  They can vote on proposals and elect Consuls.
     * @notice Senator - There is no limit to the number of Senators, but they must be elected by other Senators via proposals.
     * @notice Caesar - There should only ever be 1 Caesar at any point in time.  The Caesar should be a short time interval
     * @notice Caesar(cont'd) - They wield ultimate power within the DAO temporarily to resolve disputes.  If a Consul vetoes the other,
     * @notice Caesar(cont'd) - There should be an election for a Caesar to resolve the dispute.
     */  


    ///////////////////////
    // Type Declarations //
    ///////////////////////
    /// @dev VetoInfo struct to store veto-related information.
    struct VetoInfo {
        uint8 tribuneVetoes;
        uint256 consulVetoCount;
        mapping(address => bool) consulVetoes;
    }

    ///////////////////////
    //    Global State   //
    ///////////////////////
    /// @dev Mapping to store the veto information for each proposal.
    mapping(uint256 => VetoInfo) public vetoes;

    /// @dev Mapping to store the governance whitelist status of each address.
    mapping(address => bool) public governanceWhitelist;

    /// @dev Address of the Timelock contract
    address public timelockContract;

    /// @dev Address of the SenatePositions contract
    ISenatePositions public senatePositionsContract;

    /// @dev Quorum value for the Senate.
    uint16 public quorumPct;


    ///////////////////////
    //    Modifiers      //
    ///////////////////////
    modifier onlyTimelock() {
        if(msg.sender != address(timelockContract)) revert TIDUS_ONLY_TIMELOCK();
        _;
    }
    modifier onlyValidSupport(uint8 support) {
       if (support <= 2) revert TIDUS_INVALID_SUPPORT(support); 
       _;
    }
    modifier onlyActiveState(uint256 proposalId) {
        ProposalState state = state(proposalId); 
        if (state != ProposalState.Active) revert TIDUS_INVALID_STATE(proposalId);
        _;
    }
    modifier onlySuccessfulProposal(uint256 proposalId) {
        ProposalState state = state(proposalId);
        ProposalState expectedState = ProposalState.Succeeded;
        if (state != expectedState) revert TIDUS_INVALID_STATE(proposalId, state);
        _;
    }
    modifier onlySuccessfulOrDefeatedProposal(uint256 proposalId) {
        ProposalState state = state(proposalId);
        ProposalState expectedState = ProposalState.Succeeded || ProposalState.Defeated;
        if (state != expectedState) revert TIDUS_INVALID_STATE(proposalId, state, expectedState);
        _;
    }
    modifier onlyValidPosition() {
        if (!validatePosition(msg.sender)) revert TIDUS_INVALID_POSITION(msg.sender);
        _;
    }

    modifier onlyTribune() {
        Position expectedPosition = Position.Tribune;
        Position senderPosition = senatePositionsContract.getPosition(msg.sender);
        if(!senatePositionsContract.isTribune(msg.sender)) revert TIDUS_INVALID_POSITION(msg.sender, senderPosition, expectedPosition);
        _;
    }
    modifier noPreviousTribuneVeto(uint256 proposalId) {
        uint8 tribuneVetoes = vetoes[proposalId].tribuneVetoes;
        if (tribuneVetoes >= 1) revert TIDUS_TRIBUNE_ALREADY_VETOED();
        _;
    }
    modifier onlyConsul() {
        if(!senatePositionsContract.isConsul(msg.sender)) revert TIDUS_INVALID_POSITION(msg.sender)
    }

    // /// @dev Custom initializer modifier to disable standard initializers.
    // /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //     _disableInitializers();
    // }

    /**
     * @notice Initializes the Senate contract.
     * @param _timelock The timelock controller for the GovernorTimelockControlUpgradeable.
     * @param _senatePositionsContract The address of the SenatePositions contract.
     */
    function initialize(address _timelock, address _senatePositionsContract, uint16 _quorumValue) public initializer {
        __Governor_init("Senate");
        __GovernorSettings_init(1, /* 1 block */ 21600, /* 3 days */ 0 /* Zero votes */ );
        __GovernorCountingSimple_init();
        __GovernorVotes_init(IVotesUpgradeable(_senatePositionsContract));
        __GovernorTimelockControl_init(TimelockControllerUpgradeable(payable(_timelock)));
        __Ownable_init();
        __UUPSUpgradeable_init();
        timelockContract = address(_timelock);
        senatePositionsContract = ISenatePositions(_senatePositionsContract);
        quorumPct = _quorumValue;
    }

    /**
     * @notice Returns the required quorum for proposals.
     * @return The required quorum value.
     */
    function updateQuorum(uint16 _quorumValue) public returns (uint256) onlyTimelock {
        quorumPct = _quorumValue;
        return quorumPct;
    }

    /**
     * @notice Authorizes an upgrade to the contract implementation.
     * @param newImplementation The address of the new contract implementation.
     * @dev This function can only be called by the contract owner.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // The following functions are overrides required by Solidity.
    /**
     * @notice Vote on a proposal with the specified support.
     * @dev Allows only users with a Senate position to vote on a proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support The type of support to give to the proposal (0 for "against", 1 for "for", 2 for "abstain").
     */
    function castVote(uint256 proposalId, uint8 support)
        public
        override(GovernorUpgradeable, IGovernorUpgradeable)
        onlyValidPosition
        onlyValidSupport(support)
        onlyActiveState(proposalId)
        returns (uint256)
    {
        // Cast the vote using the `_vote` function from the `GovernorUpgradeable` contract
        return _castVote(proposalId, msg.sender, support, "");
    }

    /**
     * @notice Vote on a proposal with the specified support using an EIP-712 signature.
     * @dev Allows only users with a Senate position to vote on a proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support The type of support to give to the proposal (0 for "against", 1 for "for", 2 for "abstain").
     * @param v The recovery byte of the signature.
     * @param r Half of the ECDSA signature pair.
     * @param s Half of the ECDSA signature pair.
     */
    function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s)
        public
        override(GovernorUpgradeable, IGovernorUpgradeable)
        onlyValidSupport(support)
        onlyActiveState
        onlyValidPosition
        returns (uint256)
    {
        address voter =
            ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support))), v, r, s);

        // Cast the vote using the `_vote` function from the `GovernorUpgradeable` contract
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @notice Returns the voting delay.
     * @return The voting delay value.
     */
    function votingDelay() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingDelay();
    }

    /**
     * @notice Returns the voting period.
     * @return The voting period value.
     */
    function votingPeriod() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingPeriod();
    }

    /**
     * @notice Allows a Tribune to veto a proposal that is in the Succeeded state.
     * @param proposalId The ID of the proposal to veto.
     * @dev This function requires that the caller is a Tribune and the proposal has not already been vetoed by a Tribune.
     */
    function tribuneVeto(uint256 proposalId) public onlySuccessfulProposal onlyTribune noPreviousTribuneVeto {
        vetoes[proposalId].tribuneVetoes += 1;
        emit TribuneVeto(msg.sender, proposalId);
    }

    /**
     * @notice Allows a Consul to veto a proposal that is in the Succeeded or Defeated state.
     * @param proposalId The ID of the proposal to veto.
     * @dev This function requires that the caller is a Consul and the proposal has not already been vetoed twice by Consuls.
     */
    function consulVeto(uint256 proposalId) public 
        onlyValidState
        onlyConsul
        consulHasNotVetoed
        onlyTwoConsulVetoes
    {
        require(senatePositionsContract.isConsul(msg.sender), "Senate: Only Consuls can use the consul veto");
        require(
            vetoes[proposalId].consulVetoes[msg.sender] == false, "Senate: Consul veto already used for this proposal"
        );
        require(vetoes[proposalId].consulVetoCount < 2, "Senate: Both Consuls have already Vetoed");
        vetoes[proposalId].consulVetoCount += 1;
        vetoes[proposalId].consulVetoes[msg.sender] = true;
        emit ConsulVeto(msg.sender, proposalId);
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
        if (currentState == ProposalState.Succeeded && vetoInfo.tribuneVetoes > 0) {
            currentState = ProposalState.Defeated;
        }

        // If the proposal is in the Succeeded state and there's an odd number of Consul vetoes, the proposal state is reversed
        if (currentState == ProposalState.Succeeded && vetoInfo.consulVetoCount % 2 == 1) {
            currentState = ProposalState.Defeated;
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
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(GovernorUpgradeable, IGovernorUpgradeable) returns (uint256) {
        require(validatePosition(msg.sender), "Senate: Only valid positions can create proposals");
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
        if (validatePosition(msg.sender)) {
            return 0;
        } else {
            return type(uint256).max; // Non-valid positions cannot create proposals
        }
    }

    /**
     * @dev Executes a proposal with the given ID, targets, values, calldatas and description hash.
     * Only the GovernorTimelockController can call this function.
     */
    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    /**
     * @dev Cancels a proposal with the given targets, values, calldatas and description hash.
     * Only the GovernorTimelockController can call this function.
     * @return The ID of the cancelled proposal.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) returns (uint256) {
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
     * @notice Check the SenatePositionsContract for the validity of a given address.
     * @param _address The address to check.
     * @return True if the address is valid, false otherwise.
     */
    function validatePosition(address _address) public view returns (bool) {
        if (
            senatePositionsContract.isConsul(_address) 
            || senatePositionsContract.isCensor(_address)
            || senatePositionsContract.isTribune(_address)
            || senatePositionsContract.isSenator(_address)
            || senatePositionsContract.isCaesar(_address) 
        ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Update the address of a given contract.
     * @param _contractAddress The address of the contract to update.
     * @param _newAddress The new address of the contract.
     * @notice Only a Senate proposal can update the address of a contract.
     */
    function updateSenatePositionsContract(address _contractAddress, address _newAddress) public {
        require(
            msg.sender == timelockContract || msg.sender == owner(),
            "Senate: Only a Senate proposal can update the address of a contract"
        );
        require(_newAddress != address(0), "Senate: Cannot update a contract to the zero address");
        require(_contractAddress != address(0), "Senate: Cannot update the zero address");
        require(_contractAddress != _newAddress, "Senate: Cannot update a contract to the same address");
        require(
            _contractAddress == address(senatePositionsContract),
            "Senate: Cannot update a contract that is not the SenatePositions contract"
        );

        senatePositionsContract = ISenatePositions(_newAddress);
    }

    /**
     * @notice Returns the required quorum for proposals.
     * @param proposalId The ID of the proposal to check the quorum for.
     * @return The required quorum value.
     */
    function quorum(uint256 proposalId) public view override(IGovernorUpgradeable) returns (uint256) {
        return quorum(proposalId);
    }
}
