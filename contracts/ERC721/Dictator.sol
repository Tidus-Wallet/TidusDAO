// SPDX-License-Identifier: MIT;
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ISenate } from "../governance/interfaces/ISenate.sol";

contract Dictator is ERC721Enumerable {

    string public constitution;
    string metadata;
    address public senateVotingContract;


    constructor(string _dictatorMetadata, address _senateVotingContract) ERC721("Dictator", "DICTATOR") {
        metadata = _dictatorMetadata;
        senateVotingContract = _senateVotingContract;
    }

    function mint(address to) public {
        require(msg.sender == address(senateVotingContract), "TIDUS: Only the Senate Voting Contract can mint Dictators.");
        require(ISenate(senateVotingContract).dictators(to), "TIDUS: Cannot mint to a non-Dictator address.");
        require(totalSupply() < 1, "TIDUS: Only 1 Dictator at a time.");
        _safeMint(to, totalSupply());
    }

    function burn(uint256 tokenId) public  {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(balanceOf(msg.sender) > 0, "TIDUS: You are not a Dictator.");
        require(msg.sender == address(senateVotingContract) || msg.sender == ownerOf(tokenId), "TIDUS: Only the Senate Voting Contract or Dictators can burn the token.");
        _burn(tokenId);
    }
}