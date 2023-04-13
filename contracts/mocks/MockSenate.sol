// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../ERC721/Censors.sol";
import "../ERC721/Consuls.sol";
import "../ERC721/Senators.sol";
import "../ERC721/Tribunes.sol";
import "../ERC721/Dictators.sol";

contract MockSenate {
    Censors public censors;
    Consuls public consuls;
    Senators public senators;
    Tribunes public tribunes;
    Dictators public dictator;

    constructor(
        address _censors,
        address _consuls,
        address _senators,
        address _tribunes,
        address _dictator
    ) {
        censors = Censors(_censors);
        consuls = Consuls(_consuls);
        senators = Senators(_senators);
        tribunes = Tribunes(_tribunes);
        dictator = Dictators(_dictator);
    }

    function mintCensor(address to) external {
        censors.mint(to);
    }

    function burnCensor(uint256 tokenId) external {
        censors.burn(tokenId);
    }

    function mintConsul(address to) external {
        consuls.mint(to);
    }

    function burnConsul(uint256 tokenId) external {
        consuls.burn(tokenId);
    }

    function mintSenator(address to) external {
        senators.mint(to);
    }

    function burnSenator(uint256 tokenId) external {
        senators.burn(tokenId);
    }

    function mintTribune(address to) external {
        tribunes.mint(to);
    }

    function burnTribune(uint256 tokenId) external {
        tribunes.burn(tokenId);
    }

    function mintDictator(address to) external {
        dictator.mint(to);
    }

    function burnDictator(uint256 tokenId) external {
        dictator.burn(tokenId);
    }
}
