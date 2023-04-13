// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../ERC721/SenatePositions.sol";

contract MockSenatePositions is SenatePositions {

    constructor(
        address _senateContract,
        string[] memory _metadatas,
        uint256[] memory _termLengths
    ) SenatePositions(_senateContract, _metadatas, _termLengths) {
    }

    /**
     * @notice Exposed function to mint a new Senators token to the given address for testing purposes.
     * @param _position The position to mint the token for.
     * @param _to The address to mint the token to.
     */
    function mintForTesting(Positions _position, address _to) public {
        mint(_position, _to);
    }

    /**
     * @notice Exposed function to burn a Senators token with the given token ID for testing purposes.
     * @param _tokenId The token ID of the Senators token to burn.
     */
    function burnForTesting(uint256 _tokenId) public {
        burn(_tokenId);
    }

    /**
     * @notice Exposed function to update the metadata URI for a position for testing purposes.
     * @param _position The position to update the metadata URI for.
     * @param _updatedMetadata The updated metadata URI as a string.
     */
    function updateMetadataForTesting(Positions _position, string calldata _updatedMetadata) public {
        updateMetadata(_position, _updatedMetadata);
    }

    /**
     * @notice Exposed function to update the Senate Voting Contract address for testing purposes.
     * @param _updatedSenateAddress The updated Senate Voting Contract address.
     */
    function updateSenateAddressForTesting(address _updatedSenateAddress) public {
        updateSenateAddress(_updatedSenateAddress);
    }
}
