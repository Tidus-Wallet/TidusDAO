// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/governance/IGovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/IGovernorTimelockUpgradeable.sol";

interface ISenate is IGovernorUpgradeable, IGovernorTimelockUpgradeable {

    function vetoes(uint256 proposalId) external view returns (uint256 tribuneVetoes, uint256 consulVetoCount);
    function positions(address account) external view returns (Position);
    function governanceWhitelist(address account) external view returns (bool);
    function senateVotingContract() external view returns (address);

    function updatePosition(address account, Position position) external;
    function removePosition(address account) external;
    function quorum(uint256 blockNumber) external pure returns (uint256);
    function tribuneVeto(uint256 proposalId) external;
    function consulVeto(uint256 proposalId) external;
    function setPosition(address account, Position position) external;

    function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description) external returns (uint256);
    function proposalThreshold() external view returns (uint256);
}
