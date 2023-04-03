//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ISenate } from "../governance/interfaces/ISenate.sol";

contract Censor is ERC721Enumerable {

    string public constitution;
    string metadata;
    address public senateVotingContract;

    constructor(string memory _censorNFTMetadata, address _senateVotingContract) ERC721("Censor", "CENSOR") {
        metadata = _censorNFTMetadata;
        senateVotingContract = _senateVotingContract;
    }

    function mint(address to) public {
        require(msg.sender == address(senateVotingContract), "TIDUS: Only the Senate Voting Contract can mint Censors.");
        require(ISenate(senateVotingContract).censor(to), "TIDUS: Cannot mint to a non-Censor address.");
        require(totalSupply() < 5, "TIDUS: Only 5 Censors at a time.");
        _safeMint(to, totalSupply());
    }


}