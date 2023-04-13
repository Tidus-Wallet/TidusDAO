// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC721Votes } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ISenate } from "../governance/interfaces/ISenate.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact sekaieth@proton.me
contract Consuls is ERC721, ERC721Enumerable, ERC721Votes, Ownable {

    /**
     * @notice The Consul struct.
     * @param consul The address of the Consul.
     * @param startTime The start time of the Consul's term.
     * @param endTime The end time of the Consul's term.
     */
    struct Consul {
        address consul;
        uint256 startTime;
        uint256 endTime;
    }

    /// @notice The metadata URI for the Dictator NFT.
    string metadata;

    /// @notice The address of the Senate Contract.
    address public senateContract;

    /// @notice Track the number of Consuls minted
    uint256 public consulCount;

    /// @notice Track historical Consuls 
    mapping (uint256 => Consul) public consuls;

    /// @notice Array for active Consuls
    address[] public activeConsuls;

    /// @notice Address for the Timelock contract
    address public timelock;

    /// @notice The length of time a consul is allowed to hold the position
    uint256 public consulTermLength;

    /**
     * @notice Constructor for the Censor NFT contract.
     * @param _censorNFTMetadata The metadata URI for the Censor NFT.
     * @param _senateContract The address of the Timelock Contract.
     */
    constructor(
        string memory _censorNFTMetadata,
        uint256 _consulTermLength,
        address _senateContract,
        address _timelock
    ) ERC721("Censor", "CENSOR") EIP712("Censor", "1") {
        metadata = _censorNFTMetadata;
        consulTermLength = _consulTermLength;
        senateContract = _senateContract;
        timelock = _timelock;
    }

    /**
     * @notice Mint a new Consul token to the given address.
     * @param to The address to mint the token to.
     */
    function mint(address to) public {
        require(msg.sender == address(timelock), "TIDUS: Only the Timelock Contract can mint Consuls.");
        require(totalSupply() < 2, "TIDUS: Only 2 Consuls at a time.");
        consulCount++;

        // Add the Consul to the historical Consuls mapping
        consuls[consulCount] = Consul({
            consul: to,
            startTime: block.timestamp,
            endTime: block.timestamp + consulTermLength
        });

        // Add the Consul to the active Consuls array
        activeConsuls.push(to);

        // Mint the token
        _safeMint(to, totalSupply());
    }

    /**
     * @notice Burn a Censor token with the given token ID.
     * @param _tokenId The token ID of the Censor token to burn.
     */
    function burn(uint256 _tokenId) public {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(msg.sender == timelock || msg.sender == ownerOf(_tokenId), "CONSUL: Only the Timelock Contract or Token Owner can burn the token.");
        
        /// @notice Remove the Consul from the active Consuls array
        for (uint i = 0; i < activeConsuls.length; i++) {
            if (activeConsuls[i] == ownerOf(_tokenId)) {
                activeConsuls[i] = activeConsuls[activeConsuls.length - 1];
                activeConsuls.pop();
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
     * @notice Check if an address is a Consul.
     * @param _address The address to check.
     * @return True if the address is a Consul, false otherwise.
     */
    function isConsul(address _address) public view returns (bool) {
        for (uint i = 0; i < activeConsuls.length; i++) {
            if (activeConsuls[i] == _address && block.timestamp < consuls[i + 1].endTime) {
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
        require(to == address(0) || to == address(timelock), "TIDUS: Only the Timelock Contract can receive Censors.");
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
     * @notice Update the Timelock Contract address.
     * @param _updatedSenateAddress The updated Timelock Contract address.
     */
    function updateSenateAddress(address _updatedSenateAddress) public onlyOwner {
        senateContract = _updatedSenateAddress;
    }

}