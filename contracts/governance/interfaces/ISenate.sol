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
        uint8 tribuneVetoes;
        uint8 consulVetoCount;
        mapping(address => bool) consulVetoes;
    }

    enum Position {
        None,
        Consul,
        Censor,
        Tribune,
        Senator,
        Dictator
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

    ////////////////////////////////
    //  External View Functions  //
    ///////////////////////////////
    function governanceWhitelist(address account) external virtual returns (bool);
    function quorum(uint256 blockNumber) public view virtual override returns (uint256);

    //////////////////////////
    //  State Modification  //
    //////////////////////////
    function tribuneVeto(uint256 proposalId) external virtual;
    function consulVeto(uint256 proposalId) external virtual;

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256);
    function proposalThreshold() external virtual returns (uint256);
}
