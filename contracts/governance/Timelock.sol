//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { TimelockControllerUpgradeable } from "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";

contract Timelock is TimelockControllerUpgradeable {

    function initialize(uint256 minDelay, address[] memory proposers, address[] memory executors) public initializer {
        __TimelockController_init(minDelay, proposers, executors, msg.sender);
    }

    /**
     * @dev returns the address of the 'Proposer' role for the timelock
     */
    function hasProposalRole(address _address) public view returns (bool) {
       bytes32 proposalRole = keccak256("PROPOSER_ROLE");
       return hasRole(proposalRole, _address); 
    }

    /**
     * @dev returns the address of the 'Executor' role for the timelock
     */
    function hasExecutionRole(address _address) public view returns (bool) {
       bytes32 executionRole = keccak256("EXECUTOR_ROLE");
       return hasRole(executionRole, _address);
    }
}