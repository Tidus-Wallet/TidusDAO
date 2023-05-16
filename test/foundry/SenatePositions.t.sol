pragma solidity 0.8.18;

import "forge-std/Test.sol";
import { SenatePositions } from "../../contracts/ERC721/SenatePositions.sol";
import { ISenatePositions } from "../../contracts/ERC721/interfaces/ISenatePositions.sol";
import { Senate } from "../../contracts/governance/Senate.sol";

contract MockSenate is Test {

	SenatePositions private senatePositions;
	address constant SENATE_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
	string[] metadatas = ["Consul", "Censor", "Tribune", "Senator", "Dictator"];
	uint256[] termLengths = [5 * 86400, 5 * 86400, 5 * 86400, 5 * 86400, 5 * 86400];

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
	
	/**
	 * @dev Test Minting
	 */
	function test_mint() external {
		// Mint from the Senate contract
		senatePositions.mint(ISenatePositions.Position.Consul, testWallets[0]);
		senatePositions.mint(ISenatePositions.Position.Censor, testWallets[1]);
		senatePositions.mint(ISenatePositions.Position.Tribune, testWallets[2]);
		senatePositions.mint(ISenatePositions.Position.Senator, testWallets[3]);
		senatePositions.mint(ISenatePositions.Position.Dictator, testWallets[4]);

		// Verify total supply
		assertEq(senatePositions.totalSupply(), 5);
		
		// Loop through wallets, verify balance and tokenId
		for (uint256 i = 0; i < testWallets.length; i++) {
			assertEq(senatePositions.balanceOf(testWallets[i]), 1);
			assertEq(senatePositions.ownedTokens(testWallets[i]), i + 1);
		}

		// Verify token URIs
		assertEq(senatePositions.tokenURI(1), "Consul");
		assertEq(senatePositions.tokenURI(2), "Censor");
		assertEq(senatePositions.tokenURI(3), "Tribune");
		assertEq(senatePositions.tokenURI(4), "Senator");
		assertEq(senatePositions.tokenURI(5), "Dictator");

	}

	/**
	 * @dev Test Burning
	 */
	function test_burn() external {
		// Mint one token
		senatePositions.mint(ISenatePositions.Position.Consul, testWallets[0]);

		// Get total supply
		uint256 totalSupply = senatePositions.totalSupply();
		
		// Get tokenId of the token we just minted and verify it's correct
		uint256 tokenId = senatePositions.ownedTokens(testWallets[0]);
		assertEq(tokenId, 1);

		// Burn token ID 1
		senatePositions.burn(tokenId);

		// Assert that updated total supply is 1 less than before
		assertEq(senatePositions.totalSupply(), totalSupply - 1);
	}

	/**
	 * @dev Test Expected Minting Reverts
	 */
	function test_mintReverts() external {
		// Mint to zero address
		vm.expectRevert("TIDUS: Cannot mint to the zero address.");
		senatePositions.mint(ISenatePositions.Position.Consul, address(0));
		// Mint Position "None"
		vm.expectRevert("TIDUS: Cannot mint a None position.");
		senatePositions.mint(ISenatePositions.Position.None, address(this));
	}
	
	function test_mintTooManyConsuls() external {
		// Mint 2 Consuls
		senatePositions.mint(ISenatePositions.Position.Consul, testWallets[0]);
		senatePositions.mint(ISenatePositions.Position.Consul, testWallets[1]);

		// Expect next Consul mint to fail
		vm.expectRevert("TIDUS: Cannot mint a Consul position when there are already two Consuls.");
		senatePositions.mint(ISenatePositions.Position.Consul, testWallets[2]);
	}

	function test_mintTooManyDictators() external {
		// Mint a dictator
		senatePositions.mint(ISenatePositions.Position.Dictator, testWallets[0]);

		// Expect next Dictator mint to fail
		vm.expectRevert("TIDUS: There is already a Dictator.");
		senatePositions.mint(ISenatePositions.Position.Dictator, testWallets[1]);
	}

	/**
	 * @dev Test Expected Burning Reverts
	 */
	function test_invalidTokenId() external {
		// Burn a token that doesn't exist
		vm.expectRevert("ERC721Metadata: URI query for nonexistent token");
		senatePositions.burn(1);
	}

	function test_callerNotOwnerOfTokenOrSenateContract() external {
		// Mint a token
		senatePositions.mint(ISenatePositions.Position.Consul, testWallets[0]);

		// Expect burn to fail because caller is not owner of token or Senate contract
		vm.expectRevert("TIDUS: Only the Senate contract can burn tokens.");
		testWallets[1].delegatecall(abi.encodeWithSignature("burn(uint256)", 1));
	}
}
	
contract SenateTest is Test {

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
	
	// Test constructor args populate the initial state correctly
	function test_constructor() public {
		assertEq(address(senatePositions.senateContract()), address(senateContract));
		assertEq(address(senatePositions.timelockContract()), timelockContract);
		assertEq(senatePositions.consulMetadata(), "Consul");
		assertEq(senatePositions.censorMetadata(), "Censor");
		assertEq(senatePositions.tribuneMetadata(), "Tribune");
		assertEq(senatePositions.senatorMetadata(), "Senator");
		assertEq(senatePositions.dictatorMetadata(), "Dictator");
		assertEq(senatePositions.consulTermLength(), 1);
		assertEq(senatePositions.censorTermLength(), 1);
		assertEq(senatePositions.tribuneTermLength(), 1);
		assertEq(senatePositions.senatorTermLength(), 1);
		assertEq(senatePositions.dictatorTermLength(), 1);
		assertEq(senatePositions.nextTokenId(), 1);
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
