// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {SenatePositions} from "../../../contracts/ERC721/SenatePositions.sol";
import {ISenatePositions} from "../../../contracts/ERC721/interfaces/ISenatePositions.sol";
import {MockWallet} from "../mocks/MockWallet.sol";

contract SenatePositionsFuzzing is Test {
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

    /**
     * @dev Fuzz Tests
     */
    function testFuzz_mint(uint8 positionIndex, uint8 walletIndex) external {
        // Define the positions that can be minted
        ISenatePositions.Position[] memory positions = new ISenatePositions.Position[](5);
        positions[0] = ISenatePositions.Position.Consul;
        positions[1] = ISenatePositions.Position.Censor;
        positions[2] = ISenatePositions.Position.Tribune;
        positions[3] = ISenatePositions.Position.Senator;
        positions[4] = ISenatePositions.Position.Caesar;

        // Select the position that will be minted
        ISenatePositions.Position position = positions[positionIndex % positions.length];

        // Select the wallet that will receive the minted token
        address wallet = testWallets[walletIndex % testWallets.length];

        // Record the balance of the wallet before the mint
        uint256 previousBalance = senatePositions.balanceOf(wallet);

        // Mint the token
        senatePositions.mint(position, wallet);

        // Record the balance of the wallet after the mint
        uint256 newBalance = senatePositions.balanceOf(wallet);

        // Verify the balance increased by 1
        assertEq(newBalance, previousBalance + 1);

        // Retrieve the last token id minted to this wallet and check its URI
        uint256 lastTokenId = senatePositions.ownedTokens(wallet);
        assertEq(senatePositions.tokenURI(lastTokenId), metadatas[uint256(position) - 1]);
    }

    function testFuzz_burn(uint8 walletIndex) external {
        // Select the wallet that will burn the token
        address wallet = testWallets[walletIndex % testWallets.length];

        // Mint a token to that wallet
        senatePositions.mint(ISenatePositions.Position.Consul, wallet);

        // Get balance of the wallet before the burn
        uint256 previousBalance = senatePositions.balanceOf(wallet);

        // Get the tokenID of the newly minted token
        uint256 tokenId = senatePositions.ownedTokens(wallet);

        // Burn the token
        senatePositions.burn(tokenId);

        // Record the balance of the wallet after the burn
        uint256 newBalance = senatePositions.balanceOf(wallet);

        // Verify the balance decreased by 1
        assertEq(newBalance, previousBalance - 1);
    }

    function testFuzz_getPosition(uint256 _position, uint256 walletIndex) external {
        if (_position > 5) {
            vm.expectRevert();
        }

        if (_position == 0) {
            vm.expectRevert(abi.encodeWithSelector(ISenatePositions.TIDUS_INVALID_POSITION.selector, (_position)));
        }

        // Select a wallet within the bounds of the testWallets array
        address wallet = testWallets[walletIndex % testWallets.length];

        // Mint a token to that wallet
        senatePositions.mint(ISenatePositions.Position(_position), wallet);

        // Verify the position of the token
        assertEq(uint256(senatePositions.getPosition(wallet)), uint256(_position));
    }
}
