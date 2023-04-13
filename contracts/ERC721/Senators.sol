//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Votes } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ISenate } from "../governance/interfaces/ISenate.sol";

/// @custom:security-contact sekaieth@proton.me
contract Senators is ERC721, ERC721Votes, ERC721Enumerable, Ownable {

    struct Senator {
        address senator;
        uint256 startTime;
        uint256 endTime;
    }

    /// @notice The metadata URI for the Dictator NFT.
    string metadata;

    /// @notice The address of the Senate Voting Contract.
    address public senateVotingContract;

    /// @notice The max amount of Senators allowed to be minted at a time
    uint256 public maxSenators;

    /// @notice Track the number of Senators minted
    uint256 public senatorCount;

    /// @notice Track minted Senators tokenId
    mapping (uint256 => Senator) public senators;

    /// @notice Array of current Senators
    address[] public activeSenators;

    /// @notice The length of time a Senator is allowed to hold the position
    uint256 public senatorTermLength;

    /**
     * @notice Constructor for the Senators NFT contract.
     * @param _senatorsNFTMetadata The metadata URI for the Senators NFT.
     * @param _senateVotingContract The address of the Senate Voting Contract.
     */
    constructor(
        string memory _senatorsNFTMetadata,
        uint256 _senatorTermLength,
        address _senateVotingContract,
        uint256 _maxSenators
    ) ERC721("Senators", "SENATORS") EIP712("SENATORS", "1") {
        metadata = _senatorsNFTMetadata;
        senatorTermLength = _senatorTermLength;
        senateVotingContract = _senateVotingContract;
        maxSenators = _maxSenators;
    }

    /**
     * @notice Mint a new Senators token to the given address.
     * @param _to The address to mint the token to.
     */
    function mint(address _to) public {
        require(msg.sender == address(senateVotingContract), "TIDUS: Only the Senate Voting Contract can mint Senators.");
        require(totalSupply() < maxSenators, "TIDUS: Senator positions are full.");
        require(!isSenator(_to), "TIDUS: Address is already a Senator.");

        // Increment the Senator count
        senatorCount++;

        // Add the Senator to the senators mapping
        senators[senatorCount] = Senator({
            senator: _to,
            startTime: block.timestamp,
            endTime: block.timestamp + senatorTermLength
        });

        // Add the Senator to the current Senators array
        activeSenators.push(msg.sender);

        // Mint the token
        _safeMint(_to, senatorCount);
    }


   /**
     * @notice Burn a Dictator token with the given token ID.
     * @param _tokenId The token ID of the Dictator token to burn.
     */
    function burn(uint256 _tokenId) public {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(msg.sender == address(senateVotingContract) || msg.sender == ownerOf(_tokenId), "TIDUS: Only the Senate Voting Contract or Owner can burn the token.");

        /// @notice Remove the Senator from the current Senators array
        for (uint i = 0; i < activeSenators.length; i++) {
            if (activeSenators[i] == ownerOf(_tokenId)) {
                activeSenators[i] = activeSenators[activeSenators.length - 1];
                activeSenators.pop();
                break;
            }
        }

        _burn(_tokenId);
    }

    /**
     * @notice Get the token URI for the Censor contract.
     * @return The token URI as a string.
     */
    function tokenURI() internal view virtual returns (string memory) {
        return metadata;
    }

    /** 
     * @notice Check if address is a Senator
     * @param _address The address to check
     * @return True if address is a Senator
     */
    function isSenator(address _address) public view returns (bool) {
        for (uint i = 0; i < activeSenators.length; i++) {
            if (activeSenators[i] == _address && block.timestamp < senators[i].endTime) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Internal function to transfer a Censor token.
     * @param from The address to transfer the token from.
     * @param to The address to transfer the token to.
     * @param tokenId The token ID of the Censor token to transfer.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(to == address(0) || to == address(senateVotingContract), "TIDUS: Only the Senate Voting Contract can receive Senator tokens.");
        super._transfer(from, to, tokenId);
    }

    // Overrides to prevent errors with multiple inheritance of the same function.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Votes) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Update the metadata URI for the Censor contract.
     * @param _updatedMetadata The updated metadata URI as a string.
     */
    function updateMetadata(string calldata _updatedMetadata) public onlyOwner {
        metadata = _updatedMetadata;
    }

    /**
     * @notice Update the Senate Voting Contract address.
     * @param _updatedSenateAddress The updated Senate Voting Contract address.
     */
    function updateSenateAddress(address _updatedSenateAddress) public onlyOwner {
        senateVotingContract = _updatedSenateAddress;
    }
}