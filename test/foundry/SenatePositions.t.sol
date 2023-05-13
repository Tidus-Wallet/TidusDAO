pragma solidity 0.8.18;

import "forge-std/Test.sol";
import { SenatePositions } from "../../contracts/ERC721/SenatePositions.sol";
import { ISenatePositions } from "../../contracts/ERC721/interfaces/ISenatePositions.sol";
import { Senate } from "../../contracts/governance/Senate.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract MockSenate is Test, ERC721Holder {

	SenatePositions private senatePositions;
	address constant SENATE_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
	string[] metadatas = ["Consul", "Censor", "Tribune", "Senator", "Dictator"];
	uint256[] termLengths = [1, 1, 1, 1, 1];

	function setUp() public {
		senatePositions = new SenatePositions(
			address(this),
			address(this),
			metadatas,
			termLengths
		);
	}

	function test_mint() external {
		senatePositions.mint(ISenatePositions.Position.Consul, address(this));
		senatePositions.mint(ISenatePositions.Position.Censor, address(this));
		senatePositions.mint(ISenatePositions.Position.Tribune, address(this));
		senatePositions.mint(ISenatePositions.Position.Senator, address(this));
		senatePositions.mint(ISenatePositions.Position.Dictator, address(this));
	}
	
}
contract SenatePositionsTest is Test {

	SenatePositions private senatePositions;

	Senate senateContract;
	address timelockContract = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
	string[] metadatas = ["Consul", "Censor", "Tribune", "Senator", "Dictator"];
	uint256[] termLengths = [1, 1, 1, 1, 1];

	function setUp() public {
		senateContract = new Senate();
		senatePositions = new SenatePositions(
		address(senateContract),
		timelockContract,
		metadatas,
		termLengths
		);
	}

	// Minting from anything but the Senate contract should fail
	function testFail_mint() public {
		senatePositions.mint(ISenatePositions.Position.Consul, address(this));
		senatePositions.mint(ISenatePositions.Position.Censor, address(this));
		senatePositions.mint(ISenatePositions.Position.Tribune, address(this));
		senatePositions.mint(ISenatePositions.Position.Senator, address(this));
		senatePositions.mint(ISenatePositions.Position.Dictator, address(this));
	}
}
