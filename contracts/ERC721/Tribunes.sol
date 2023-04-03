// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../TidusDAOConstitution.sol";

contract Tribunes is ERC721Enumerable {

    string public constitution;
    string metadata;
    address public senateVotingContract;
    TidusDAOConstitution public constitutionAddress;

    constructor(string memory _tribunesNFTMetadata, address _senateVotingContract, address _constitution) ERC721("Tribunes", "TRIBUNES") {
        metadata = _tribunesNFTMetadata;
        senateVotingContract = _senateVotingContract;
        constitutionAddress = TidusDAOConstitution(_constitution);
    }

    modifier onlyVoteContract() {
        require(msg.sender == address(senateVotingContract), "TIDUS: Only the Senate Voting Contract can mint Tribunes.");
        _;
    }

    function mint(address to) public onlyVoteContract {
        require(totalSupply() < 2, "TIDUS: Only 2 Tribunes at a time.");
        _safeMint(to, totalSupply());
    }

    function burn(uint256 tokenId) public onlyVoteContract {
        
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