//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Votes } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ISenate } from "../governance/interfaces/ISenate.sol";

/// @custom:security-contact sekaieth@proton.me
contract Censors is ERC721, ERC721Votes, ERC721Enumerable, Ownable {

    /// @notice The text of the DAO constitution.
    string public constitution;

    /// @notice The metadata URI for the Dictator NFT.
    string metadata;

    /// @notice The address of the Senate Voting Contract.
    address public senateVotingContract;

    /// @notice The address of the Timelock Contract.
    address public timelock;

    /// @notice Track historical Censors
    mapping (uint256 => address) public censors;

    /// @notice Track the number of Censors minted
    uint256 public censorCount;

    /// @notice The current censors (if any)
    address[] public currentCensors;

    /**
     * @notice Constructor for the Censor NFT contract.
     * @param _censorNFTMetadata The metadata URI for the Censor NFT.
     * @param _senateVotingContract The address of the Senate Voting Contract.
     * @param _timelock The address of the Timelock Contract.
     */
    constructor(
        string memory _censorNFTMetadata,
        address _senateVotingContract,
        address _timelock
    ) ERC721("Censor", "CENSOR") EIP712("Censor", "1") {
        metadata = _censorNFTMetadata;
        senateVotingContract = _senateVotingContract;
        timelock = _timelock;
    }

    /**
     * @notice Mint a new Censor token to the given address.
     * @param _to The address to mint the token to.
     */
    function mint(address _to) public {
        require(msg.sender == address(senateVotingContract), "TIDUS: Only the Senate Voting Contract can mint Censors.");

        censorCount++;
        censors[censorCount] = _to;
        currentCensors.push(_to);

        _safeMint(_to, totalSupply());
    }

    /**
     * @notice Burn a Censor token with the given token ID.
     * @param _tokenId The token ID of the Censor token to burn.
     */
    function burn(uint256 _tokenId) public {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(msg.sender == address(senateVotingContract) || msg.sender == ownerOf(_tokenId), "TIDUS: Only the Senate Voting Contract or Owner can burn the token.");
        
        /// @notice Remove the address from the current censors array
        for (uint i = 0; i < currentCensors.length; i++) {
            if (currentCensors[i] == ownerOf(_tokenId)) {
                currentCensors[i] = currentCensors[currentCensors.length - 1];
                currentCensors.pop();
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
     * @notice Check if the given address is a current censor.
     * @param _address - The address to check.
     * @return True if the address is a current censor, false otherwise.
     */
    function isCensor(address _address) public view returns (bool) {
        for (uint i = 0; i < currentCensors.length; i++) {
            if (currentCensors[i] == _address) {
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
        require(to == address(0) || to == address(senateVotingContract), "TIDUS: Only the Senate Voting Contract can receive Censors.");
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
     * @notice Update the timelock address for the Censor contract.
     * @param _updatedTimelock The updated timelock address.
     */
    function updateTimelock(address _updatedTimelock) public onlyOwner {
        timelock = _updatedTimelock;
    }

    /**
     * @notice Update the Senate Voting Contract address.
     * @param _updatedSenateAddress The updated Senate Voting Contract address.
     */
    function updateSenateAddress(address _updatedSenateAddress) public onlyOwner {
        senateVotingContract = _updatedSenateAddress;
    }

}