pragma solidity 0.8.18;

import "forge-std/Test.sol";
import { SenatePositions } from "../../contracts/ERC721/SenatePositions.sol";
import { ISenatePositions } from "../../contracts/ERC721/interfaces/ISenatePositions.sol";

contract MockSenate is Test {

	// Mock Senate contract
	// This contract is used to test the SenatePositions contract
	// It is used to mint tokens to the SenatePositions contract

	ISenatePositions private senatePositions;
	address constant SENATE_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;

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

	address senateContract = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
	address timelockContract = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
	string[] metadatas = ["Consul", "Censor", "Tribune", "Senator", "Dictator"];
	uint256[] termLengths = [1, 1, 1, 1, 1];

	function setUp() public {
		senatePositions = new SenatePositions(
		senateContract,
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
