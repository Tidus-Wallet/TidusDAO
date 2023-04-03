//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";

abstract contract ISenate is IGovernor {
    function consuls(address) public view virtual returns (bool);
    function senators(address) public view virtual returns (bool);
    function dictator(address) public view virtual returns (bool);
    function censor(address) public view virtual returns (bool);
}