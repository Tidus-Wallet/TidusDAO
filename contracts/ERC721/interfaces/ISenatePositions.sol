// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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

    function totalPositions() external view returns (uint256);

    ///////////////////////
    //      Errors       //
    ///////////////////////
    error TIDUS_ONLY_TIMELOCK();
    error TIDUS_INVALID_ADDRESS(address _address);
    error TIDUS_INVALID_POSITION(Position _position);
    error TIDUS_SINGLE_MINT();
    error TIDUS_POSITION_FULL(Position _position);
    error TIDUS_INVALID_TOKENID(uint256 _tokenId);
    error TIDUS_INVALID_TERM_LENGTH(uint256 _termLength);
    error TIDUS_INVALID_TRANSFER(address _to);
}
