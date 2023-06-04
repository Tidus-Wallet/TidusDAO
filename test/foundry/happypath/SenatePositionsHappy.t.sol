
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {SenatePositions} from "../../../contracts/ERC721/SenatePositions.sol";
import {ISenatePositions} from "../../../contracts/ERC721/interfaces/ISenatePositions.sol";
import {MockWallet} from "../mocks/MockWallet.sol";

contract SenatePositionsHappy is Test {
    SenatePositions private senatePositions;
    MockWallet private mockWallet;

    string[] metadatas = ["Consul", "Censor", "Tribune", "Senator", "Caesar"];
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

        mockWallet = new MockWallet();
    }

    function test_constructor() public {
        assertEq(address(senatePositions.senateContract()), address(this));
        assertEq(senatePositions.consulMetadata(), "Consul");
        assertEq(senatePositions.censorMetadata(), "Censor");
        assertEq(senatePositions.tribuneMetadata(), "Tribune");
        assertEq(senatePositions.senatorMetadata(), "Senator");
        assertEq(senatePositions.caesarMetadata(), "Caesar");
        assertEq(senatePositions.consulTermLength(), 5 * 86400);
        assertEq(senatePositions.censorTermLength(), 5 * 86400);
        assertEq(senatePositions.tribuneTermLength(), 5 * 86400);
        assertEq(senatePositions.senatorTermLength(), 5 * 86400);
        assertEq(senatePositions.caesarTermLength(), 5 * 86400);
        assertEq(senatePositions.nextTokenId(), 1);
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
        senatePositions.mint(ISenatePositions.Position.Caesar, testWallets[4]);

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
        assertEq(senatePositions.tokenURI(5), "Caesar");
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
     * @dev Test Transfer of Tokens
     */

    ///@dev Test Successful transfer to Senate contract
    function test_transferToSenateContract() external {
        // Mint one token
        senatePositions.mint(ISenatePositions.Position.Consul, address(mockWallet));

        // Get tokenId of the token we just minted and verify it's correct
        uint256 tokenId = senatePositions.ownedTokens(address(mockWallet));
        assertEq(tokenId, 1);

        // Transfer token to Senate contract
        mockWallet.transferToken(address(senatePositions), address(this), tokenId);

        // Verify balance of mockWallet is 0
        assertEq(senatePositions.balanceOf(address(mockWallet)), 0);
    }

    /**
     * @dev Test isConsul, isCensor, isTribune, isSenator, isCaesar
     */
    function test_isPosition() external {
        // Mint token for each position
        senatePositions.mint(ISenatePositions.Position.Consul, testWallets[0]);
        senatePositions.mint(ISenatePositions.Position.Censor, testWallets[1]);
        senatePositions.mint(ISenatePositions.Position.Tribune, testWallets[2]);
        senatePositions.mint(ISenatePositions.Position.Senator, testWallets[3]);
        senatePositions.mint(ISenatePositions.Position.Caesar, testWallets[4]);

        // Verify each position
        assertEq(senatePositions.isConsul(testWallets[0]), true);
        assertEq(senatePositions.isCensor(testWallets[1]), true);
        assertEq(senatePositions.isTribune(testWallets[2]), true);
        assertEq(senatePositions.isSenator(testWallets[3]), true);
        assertEq(senatePositions.isCaesar(testWallets[4]), true);
    }

    /**
     * @dev Test getPosition
     */
    function test_getPosition() external {
        // Mint token for each position
        senatePositions.mint(ISenatePositions.Position.Consul, testWallets[0]);
        senatePositions.mint(ISenatePositions.Position.Censor, testWallets[1]);
        senatePositions.mint(ISenatePositions.Position.Tribune, testWallets[2]);
        senatePositions.mint(ISenatePositions.Position.Senator, testWallets[3]);
        senatePositions.mint(ISenatePositions.Position.Caesar, testWallets[4]);

        // Verify each position
        assertEq(uint256(senatePositions.getPosition(testWallets[0])), uint256(1));
        assertEq(uint256(senatePositions.getPosition(testWallets[1])), uint256(2));
        assertEq(uint256(senatePositions.getPosition(testWallets[2])), uint256(3));
        assertEq(uint256(senatePositions.getPosition(testWallets[3])), uint256(4));
        assertEq(uint256(senatePositions.getPosition(testWallets[4])), uint256(5));
    }

}

