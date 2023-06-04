// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/governance/IGovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/IGovernorTimelockUpgradeable.sol";

abstract contract ISenate is IGovernorUpgradeable, IGovernorTimelockUpgradeable {
    enum Position {
        None,
        Consul,
        Censor,
        Tribune,
        Senator,
        Dictator
    }

    function vetoes(uint256 proposalId) external virtual returns (uint256 tribuneVetoes, uint256 consulVetoCount);
    function positions(address account) external virtual returns (Position);
    function governanceWhitelist(address account) external virtual returns (bool);

    function quorum(uint256 blockNumber) public pure virtual override returns (uint256);
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
