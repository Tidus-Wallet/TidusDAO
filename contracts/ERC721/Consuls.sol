// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ISenate } from "../governance/interfaces/ISenate.sol";
import "../TidusDAOConstitution.sol";
contract Consuls is ERC721Enumerable {

    string public constitution;
    string metadata;
    address public senateVotingContract;
    TidusDAOConstitution public constitutionAddress;

    constructor(string memory _consulsNFTMetadata, address _senateVotingContract, address _constitution) ERC721("Consuls", "CONSULS") {
        metadata = _consulsNFTMetadata;
        senateVotingContract = _senateVotingContract;
        constitutionAddress = TidusDAOConstitution(_constitution);
    }

    function mint(address to) public {
        require(msg.sender == address(senateVotingContract), "TIDUS: Only the Senate Voting Contract can mint Consuls.");
        require(ISenate(senateVotingContract).consuls(to), "TIDUS: Cannot mint to a non-Consul address.");
        require(totalSupply() < 2, "TIDUS: Only 2 Consuls at a time.");
        _safeMint(to, totalSupply());
    }

    function burn(uint256 tokenId) public  {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(balanceOf(msg.sender) > 0, "TIDUS: You are not a Consul.");
        require(msg.sender == address(senateVotingContract) || msg.sender == ownerOf(tokenId), "TIDUS: Only the Senate Voting Contract or Consuls can burn the token.");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return metadata;
    }

    function daoConstitution() public view returns (string memory) {
        return constitutionAddress.constitution();
    }
}