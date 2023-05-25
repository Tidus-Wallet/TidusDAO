// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Interface for the SenatePositions contract
interface ISenatePositions is IERC721 {
    enum Position {
        None,
        Consul,
        Censor,
        Tribune,
        Senator,
        Caesar
    }

    function mint(Position _position, address _to) external;

    function burn(uint256 _tokenId) external;

    function tokenURI(uint256 _tokenId) external view returns (string memory uri);

    function getPosition(address _address) external view returns (Position);

    function isConsul(address _address) external view returns (bool);

    function isSenator(address _address) external view returns (bool);

    function isCensor(address _address) external view returns (bool);

    function isTribune(address _address) external view returns (bool);

    function isCaesar(address _address) external view returns (bool);

    function updateMetadata(Position _position, string calldata _updatedMetadata) external;

    function updateSenateAddress(address _updatedSenateAddress) external;

    function updateTermLength(Position _position, uint256 _newTermLength) external; 
}
