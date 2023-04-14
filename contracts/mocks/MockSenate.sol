// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../governance/interfaces/ISenate.sol";
import "../ERC721/SenatePositions.sol";
import "../governance/interfaces/ITimelock.sol";

contract MockSenate is ISenate {
    SenatePositions private senatePositions;
    ITimelock private timelock;
    
    constructor(address _senatePositions, address _timelock) {
        senatePositions = SenatePositions(_senatePositions);
        timelock = ITimelock(_timelock);
    }

    /**
     * @notice Check the SenatePositionsContract for the validity of a given address.
     * @param _address The address to check.
     * @return True if the address is valid, false otherwise.
     */
    function validatePosition(address _address) public view returns (bool) {
        if (
            senatePositions.isConsul(_address) ||
            senatePositions.isCensor(_address) ||
            senatePositions.isDictator(_address) ||
            senatePositions.isSenator(_address) ||
            senatePositions.isTribune(_address)
        ) {
            return true;
        } else {
            return false;
        }
    }
    
    function electConsul(address _consul) external {
        require(msg.sender == address(timelock), "Not the timelock contract");
        // Implement consul election lo

    }
    
    function electCensor(address _censor) external {
        require(senatePositions.isConsul(msg.sender), "Not a consul");
        // Implement censor election logic here
    }
    
    function electTribune(address _tribune) external {
        require(senatePositions.isCensor(msg.sender), "Not a censor");
        // Implement tribune election logic here
    }
    
    // Add any other functions you want to test with the SenatePositions contract
}
