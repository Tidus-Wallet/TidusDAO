//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ISenate } from "../governance/interfaces/ISenate.sol";

contract Senators is ERC721Enumerable {

    string public constitution;
    string metadata;
    address public senateVotingContract;

    constructor(string memory _senatorsNFTMetadata, address _senateVotingContract) ERC721("Senators", "SENATORS") {
        metadata = _senatorsNFTMetadata;
        senateVotingContract = _senateVotingContract;
    }

    function mint(address to) public {
        require(msg.sender == address(senateVotingContract), "TIDUS: Only the Senate Voting Contract can mint Senators.");
        require(ISenate(senateVotingContract).senators(to), "TIDUS: Cannot mint to a non-Senator address.");
        require(totalSupply() < 5, "TIDUS: Only 5 Senators at a time.");
        _safeMint(to, totalSupply());
    }

    function burn(uint256 tokenId) public  {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(balanceOf(msg.sender) > 0, "TIDUS: You are not a Senator.");
        require(msg.sender == address(senateVotingContract) || msg.sender == ownerOf(tokenId), "TIDUS: Only the Senate Voting Contract or Senators can burn the token.");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return metadata;
    }

    function daoConstitution() public view returns (string memory) {
        return constitution;
    }
}