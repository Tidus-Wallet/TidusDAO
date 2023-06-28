// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Senate } from "../contracts/governance/Senate.sol";
import { SenatePositions } from "../contracts/ERC721/SenatePositions.sol";
import "forge-std/Script.sol";

contract DeployDAO is Script {

    Senate senate;
    SenatePositions senatePositions;

    function deploySenatePositions() internal {
        string[] memory metadatas = new string[](5);
        {
            metadatas[0] = "Consul";
            metadatas[1] = "Censor";
            metadatas[2] = "Tribune";
            metadatas[3] = "Senator";
            metadatas[4] = "Caesar";
        }
        uint256[] memory termLengths = new uint256[](5);
        {
            for(uint256 i = 0; i < 5; i++) {
                termLengths[i] = 5 * 86400;
            }
        }
        uint256 deployerPrivkey = vm.envUint("ANVIL_FIRST_SIGNER");
        address deployerAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        vm.startBroadcast(deployerPrivkey);

        senatePositions = new SenatePositions(
            address(deployerAddress),
            address(deployerAddress),
            metadatas,
            termLengths
        );

        console.log("SenatePositions Deployed! Address: %s", address(senatePositions));
    }

    function deploySenate() internal {
        senate = new Senate();
        console.log("Senate Deployed! Address: %s", address(senate));
    }


    function run() external {
        deploySenatePositions();
    }
    
}