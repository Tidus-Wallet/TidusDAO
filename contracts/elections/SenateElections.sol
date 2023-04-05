// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../governance/Senate.sol";

contract SenateVoting {
    Senate public senate;

    constructor(Senate _senate) {
        senate = _senate;
    }

    // Voting logic for positions goes here

    // Function to be called after a successful vote
    function _updatePosition(address account, Senate.Position position) internal {
        senate.updatePosition(account, position);
    }

    // Function to be called when an address loses their position after a vote
    function _removePosition(address account) internal {
        senate.removePosition(account);
    }
}
