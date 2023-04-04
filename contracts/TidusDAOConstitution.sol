// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

contract TidusDAOConstitution is ERC721Enumerable {


    string public constitution;

    constructor(string memory _constitutionText) ERC721("TidusDAO Constitution", "TDC") {
        constitution = _constitutionText;
        mint(address(this));
    }

    function mint(address to) public {
        _safeMint(to, totalSupply());
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(
            "data:application/json;base64,", 
            Base64.encode(bytes(
                abi.encodePacked(
                    '{"name": "TidusDAO Constitution",',
                    '"description": "The TidusDAO Constitution is a living document that defines the rules and processes by which the TidusDAO operates.",',
                    '"external_url": "https://tidusdao.com/constitution",',
                    '"constitution:": "', constitution, '",'
        )))));
    }
}
