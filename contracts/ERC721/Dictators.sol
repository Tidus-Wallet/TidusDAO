//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Votes } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ISenate } from "../governance/interfaces/ISenate.sol";

/// @custom:security-contact sekaieth@proton.me
contract Dictators is ERC721, ERC721Votes, ERC721Enumerable, Ownable {

    struct Dictator {
        address dictatorAddress;
        uint256 dictatorStartTime;
        uint256 dictatorEndTime;
    }

    /// @notice The metadata URI for the Dictator NFT.
    string metadata;

    /// @notice The address of the Senate Voting Contract.
    address public senateVotingContract;

    /// @notice The address of the Timelock Contract.
    address public timelock;

    /// @notice The length of time a dictator is allowed to hold the position
    uint256 public dictatorServiceLength;

    /// @notice Track historical dictators
    mapping (uint256 => Dictator) public dictators;

    /// @notice Track the number of dictators minted
    uint256 public dictatorCount;

    /// @notice The current dictator (if any)
    address public currentDictator;

    /**
     * @notice Constructor for the Dictator NFT contract.
     * @param _dictatorNFTMetadata The metadata URI for the Dictator NFT.
     * @param _senateVotingContract The address of the Senate Voting Contract.
     * @param _timelock The address of the Timelock Contract.
     */
    constructor(
        string memory _dictatorNFTMetadata,
        address _senateVotingContract,
        address _timelock,
        uint256 _dictatorServiceLength

    ) ERC721("Dictator", "DICTATOR") EIP712("DICTATOR", "1") {
        metadata = _dictatorNFTMetadata;
        senateVotingContract = _senateVotingContract;
        timelock = _timelock;
        dictatorServiceLength = _dictatorServiceLength;
    }

/**
 * @notice Allows the Senate Voting Contract to mint a new Dictator token to the given address.
 * @param _to The address to mint the token to.
 * @dev Only callable by the Senate Voting Contract.
 * @dev Only one Dictator token can be minted at a time.
 * @dev The newly minted Dictator token will be assigned a start and end time for the Dictator's service.
 */
function mint(address _to) public {
    require(msg.sender == address(senateVotingContract), "TIDUS: Only the Senate Voting Contract can mint Dictators.");
    require(isDictator(_to) == false, "TIDUS: Address is already a Dictator.");
    require(_to != address(0), "TIDUS: Cannot mint to the zero address.");
    require(_to != address(this), "TIDUS: Cannot mint to the contract address.");
    require(_to != address(senateVotingContract), "TIDUS: Cannot mint to the Senate Voting Contract address.");
    require(_to != address(timelock), "TIDUS: Cannot mint to the Timelock Contract address.");
    require(totalSupply() < 1, "TIDUS: Only 1 Dictator at a time.");

    // Create a new Dictator struct
    Dictator storage dictator = dictators[dictatorCount + 1];
    
    // Assign values to the Dictator struct
    dictator.dictatorAddress = _to;
    dictator.dictatorStartTime = block.timestamp;
    dictator.dictatorEndTime = block.timestamp + dictatorServiceLength;

    // Set the current Dictator
    currentDictator = _to;

    // Increase the dictator count
    dictatorCount++;

    // Add the Dictator to the dictators mapping
    dictators[dictatorCount + 1] = dictator;

    // Mint the token to the given address
    _safeMint(_to, totalSupply());
}


    /**
     * @notice Burn a Dictator token with the given token ID.
     * @param _tokenId The token ID of the Dictator token to burn.
     */
    function burn(uint256 _tokenId) public {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(msg.sender == address(timelock) || msg.sender == ownerOf(_tokenId), "TIDUS: Only the Timelock Contract or Owner can burn the token.");
        currentDictator = address(0);
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
     * @notice Check if address is Dictator and that Dictator time is not expired
     * @param _address The address to check
     * @return True if Dictator and time is not expired
     */
    function isDictator(address _address) public view returns (bool) {
        return currentDictator == _address && block.timestamp < dictators[dictatorCount].dictatorEndTime;
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
        require(to == address(0) || to == address(senateVotingContract), "TIDUS: Only the Senate Voting Contract can receive Dictator tokens.");
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
        require(bytes(_updatedMetadata).length != 0, "TIDUS: Metadata URI cannot be empty.");
        require(msg.sender == timelock, "TIDUS: Only the Timelock Contract can update the metadata URI.");
        require(keccak256(bytes(metadata)) != keccak256(bytes(_updatedMetadata)), "TIDUS: Metadata URI is already set to the given URI.");
        metadata = _updatedMetadata;
    }

    /**
     * @notice Update the timelock address for the Censor contract.
     * @param _updatedTimelock The updated timelock address.
     */
    function updateTimelock(address _updatedTimelock) public {
        require(msg.sender == timelock, "TIDUS: Only the Timelock Contract can update the Timelock Contract address.");
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