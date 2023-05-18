
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import { SenatePositions } from "../../contracts/ERC721/SenatePositions.sol";
import { ISenatePositions } from "../../contracts/ERC721/interfaces/ISenatePositions.sol";
import { Senate } from "../../contracts/governance/Senate.sol";
import { ISenate } from "../../contracts/governance/interfaces/ISenate.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { Timelock } from "../../contracts/governance/Timelock.sol";
import { IVotesUpgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IVotesUpgradeable.sol";

///@dev - AFAIK I can't instantiate a wallet within Solidity
///@dev - So making this mock wallet to test transfers.
contract MockWallet is IERC721Receiver {
	function transferToken(address _token, address _to, uint256 _tokenId) external {
		IERC721(_token).transferFrom(address(this), _to, _tokenId);
	}

    function submitProposal(address _senateAddress, address[] memory _targets, uint256[] memory _values, bytes[] memory _calldatas, string memory description) external {
        ISenate senate = ISenate(_senateAddress);
        senate.propose(_targets, _values, _calldatas, description);
    }

	function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
		return this.onERC721Received.selector;
	}
}

contract MockTimelock is Timelock {

}
contract TestSenate is Test {

    // Senate deployment vars
    Senate public senate;
    Timelock public timelock;
    uint16 quorumValue;

    // SenatePositions deployment vars
    ISenatePositions public senatePositions;
	string[] metadatas = ["Consul", "Censor", "Tribune", "Senator", "Dictator"];
	uint256[] termLengths = [5 * 86400, 5 * 86400, 5 * 86400, 5 * 86400, 5 * 86400];

    // Set up Mock Wallet
    MockWallet public mockWallet;

    // Test Addresses
	address[] testWallets = [
		0x84141fa1AC4084fbc8ec2cC6Dc3F055820657610,
		0x58736943CeDd4112Ee7058D63E5824942c029d42,
		0x7B08Bd13Ac6d47c1A3a7BA6F0696060e3A98b5B2,
		0x0e81C065FE246BB8B8cFe04D933B22d1ce4073d1,
		0x2A456bfbf334B6D52dFB2E1E80cf0333Cc201F40
	];

    function setUp() external {

        timelock = new Timelock();

        senatePositions = new SenatePositions(
            address(this),
            address(this),
            metadatas,
            termLengths
        );

        senate = new Senate();

        senate.initialize(
            address(timelock),
            address(senatePositions),
            quorumValue
        );
        mockWallet = new MockWallet();
    }
    
    function test_proposalSubmits() external {
        
        ///@dev Set up proposal vars
        address[] memory targets = new address[](1);
        targets[0] = address(senatePositions);
        
        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("mint(uint8, address)", 0, address(mockWallet));

        ///@dev Mint a token to mockWallet so it can submit a proposal
        senatePositions.mint(ISenatePositions.Position.Consul, address(mockWallet));

        ///@dev Submit a proposal
        mockWallet.submitProposal(address(this), targets, values, calldatas, "Test Proposal");


    }
}