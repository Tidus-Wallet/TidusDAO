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

	address[] testWallets = [
		0x84141fa1AC4084fbc8ec2cC6Dc3F055820657610,
		0x58736943CeDd4112Ee7058D63E5824942c029d42,
		0x7B08Bd13Ac6d47c1A3a7BA6F0696060e3A98b5B2,
		0x0e81C065FE246BB8B8cFe04D933B22d1ce4073d1,
		0x2A456bfbf334B6D52dFB2E1E80cf0333Cc201F40
	];


	function setUp() public {
		senatePositions = new SenatePositions(
			address(this),
			address(this),
			metadatas,
			termLengths
		);
	}

	function test_mint() external {
		// Mint from the Senate contract
		senatePositions.mint(ISenatePositions.Position.Consul, testWallets[0]);
		senatePositions.mint(ISenatePositions.Position.Censor, testWallets[1]);
		senatePositions.mint(ISenatePositions.Position.Tribune, testWallets[2]);
		senatePositions.mint(ISenatePositions.Position.Senator, testWallets[3]);
		senatePositions.mint(ISenatePositions.Position.Dictator, testWallets[4]);

		// Verify total supply
		assertEq(senatePositions.totalSupply(), 5);
		
		// Loop through wallets and verify balance
		for (uint256 i = 0; i < testWallets.length; i++) {
			assertEq(senatePositions.balanceOf(testWallets[i]), 1);
		}

		// Verify token URI
		assertEq(senatePositions.tokenURI(0), "Consul");
		// assertEq(senatePositions.tokenURI(1), "Censor");
		// assertEq(senatePositions.tokenURI(2), "Tribune");
		// assertEq(senatePositions.tokenURI(3), "Senator");
		// assertEq(senatePositions.tokenURI(4), "Dictator");

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
