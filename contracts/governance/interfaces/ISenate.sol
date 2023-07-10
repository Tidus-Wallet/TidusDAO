// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/governance/IGovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/IGovernorTimelockUpgradeable.sol";

abstract contract ISenate is IGovernorUpgradeable, IGovernorTimelockUpgradeable {
    ///////////////////////
    // Type Declarations //
    ///////////////////////

    /// @dev VetoInfo struct to store veto-related information.
    struct VetoInfo {
        uint8 consulVetoCount;
        uint8 tribuneVetoCount;
        address[] proposedCaesars;
        mapping(address => bool) consulVetoes;
        mapping(address => bool) tribuneVetoes;
    }

    enum Position {
        None,
        Consul,
        Censor,
        Tribune,
        Senator,
        Caesar
    }

    ///////////////////////
    //       Events      //
    ///////////////////////
    event ConsulVeto(address indexed account, uint256 indexed proposalId);
    event TribuneVeto(address indexed account, uint256 indexed proposalId);
    event ContractAddressUpdated(address indexed contractAddress, address indexed newAddress);

    ///////////////////////
    //       Errors      //
    ///////////////////////
    error TIDUS_ONLY_TIMELOCK();
    error TIDUS_INVALID_SUPPORT(uint8 support);
    error TIDUS_INVALID_STATE(uint256 proposalId, ProposalState state);
    error TIDUS_INVALID_POSITION(address sender, uint8 position);
    error TIDUS_NOT_SUCCESSFUL_PROPOSAL(uint256 proposal);
    error TIDUS_ALREADY_VETOED(Position _position, address _sender);
    error TIDUS_INVALID_ADDRESS(address _address);
    error TIDUS_NO_SELF_CAESAR(address _address);

    ////////////////////////////////
    //  External View Functions  //
    ///////////////////////////////
    function governanceWhitelist(address account) external virtual returns (bool);
    function quorum(uint256 blockNumber) public view virtual override returns (uint256);
    function proposalVetoes(uint256 proposalId)
        external
        view
        virtual
        returns (uint8 tribuneVetoes, uint8 consulVetoes);
    function hasTribuneVetoed(uint256 proposalId, address account) external view virtual returns (bool);
    function hasConsulVetoed(uint256 proposalId, address account) external view virtual returns (bool);

    //////////////////////////
    //  State Modification  //
    //////////////////////////
    function tribuneVeto(uint256 proposalId) external virtual;
    function consulVeto(uint256 proposalId, address proposedCaesar) external virtual returns (bool);

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256);
    function proposalThreshold() external virtual returns (uint256);
}
