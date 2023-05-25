// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ISenatePositions } from "../ERC721/interfaces/ISenatePositions.sol";
import { ISenate } from "../governance/interfaces/ISenate.sol";
contract MockTimelock {

    ISenatePositions private senatePositions;
    ISenate private senate;

    constructor(address _senatePositions, address _senate) {
        senatePositions = ISenatePositions(_senatePositions);
        senate = ISenate(_senate);
    }

    function mintConsul(address _consul) external {
        senatePositions.mint(ISenatePositions.Position.Consul, _consul);
    }

    function mintCensor(address _censor) external {
        senatePositions.mint(ISenatePositions.Position.Censor, _censor);
    }

    function mintTribune(address _tribune) external {
        senatePositions.mint(ISenatePositions.Position.Tribune, _tribune);
    }

    function mintSenator(address _senator) external {
        senatePositions.mint(ISenatePositions.Position.Senator, _senator);
    }

    function mintCaesar(address _caesar) external {
        senatePositions.mint(ISenatePositions.Position.Caesar, _caesar);
    }

    function burn(uint256 _tokenId) external {
        senatePositions.burn(_tokenId);
    }

    function updateMetadata(ISenatePositions.Position _position, string calldata _updatedMetadata) external {
        senatePositions.updateMetadata(_position, _updatedMetadata);
    }

    function updateSenateAddress(address _updatedSenateAddress) external {
        senatePositions.updateSenateAddress(_updatedSenateAddress);
    }

    function updateSenateContract(address _updatedSenateContract) external {
        senatePositions.updateSenateAddress(_updatedSenateContract);
    }

    function updateConsulTermLength(uint256 _updatedConsulTermLength) external {
        senatePositions.updateTermLength(ISenatePositions.Position.Consul, _updatedConsulTermLength);
    }
}
