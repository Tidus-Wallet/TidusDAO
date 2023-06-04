// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {SenatePositions} from "../../../contracts/ERC721/SenatePositions.sol";
import {ISenatePositions} from "../../../contracts/ERC721/interfaces/ISenatePositions.sol";
import {Senate} from "../../../contracts/governance/Senate.sol";
import {MockWallet} from "../mocks/MockWallet.sol";


contract SenatePositionsTestReverts is Test {
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
    

    ///@dev - Test transfer to anything but the Senate contract
    function test_transferToUnallowedAddressFail() external {
        // Mint one token
        senatePositions.mint(ISenatePositions.Position.Consul, address(mockWallet));

        // Get tokenId of the token we just minted and verify it's correct
        uint256 tokenId = senatePositions.ownedTokens(address(mockWallet));
        assertEq(tokenId, 1);

        // Transfer token to another wallet
        vm.expectRevert(abi.encodeWithSelector(ISenatePositions.TIDUS_INVALID_TRANSFER.selector,testWallets[0]));
        mockWallet.transferToken(address(senatePositions), testWallets[0], tokenId);
    }

    /**
     * @dev Test Expected Minting Reverts
     */
    ///@dev - Test minting to zero addr should revert
    function test_MintToZeroAddr() external {
        // Mint to zero address
        vm.expectRevert(abi.encodeWithSelector(ISenatePositions.TIDUS_INVALID_ADDRESS.selector,address(0)));
        senatePositions.mint(ISenatePositions.Position.Consul, address(0));
    }

    ///@dev - Test minting to "None" position should revert
    function test_MintToNonePosition() external {
        // Mint Position "None"
        vm.expectRevert(abi.encodeWithSelector(ISenatePositions.TIDUS_INVALID_POSITION.selector,uint256(0)));
        senatePositions.mint(ISenatePositions.Position.None, address(this));
    }

    ///@dev - Test minting multiple tokens to single addr should revert
    function test_mintMultipleTokensToSameAddr() external {
        // Mint two tokens to the same address
        senatePositions.mint(ISenatePositions.Position.Consul, testWallets[0]);
        vm.expectRevert(abi.encodeWithSelector(ISenatePositions.TIDUS_SINGLE_MINT.selector));
        senatePositions.mint(ISenatePositions.Position.Censor, testWallets[0]);
    }

    ///@dev - Test minting too many of Consuls should revert
    function test_mintTooManyConsuls() external {
        // Mint 2 Consuls
        senatePositions.mint(ISenatePositions.Position.Consul, testWallets[0]);
        senatePositions.mint(ISenatePositions.Position.Consul, testWallets[1]);

        // Expect next Consul mint to fail
        vm.expectRevert(abi.encodeWithSelector(ISenatePositions.TIDUS_POSITION_FULL.selector,uint256(1)));
        senatePositions.mint(ISenatePositions.Position.Consul, testWallets[2]);
    }

    ///@dev - Test minting too many Caesars should revert
    function test_mintTooManyCaesars() external {
        // Mint a caesar
        senatePositions.mint(ISenatePositions.Position.Caesar, testWallets[0]);

        // Expect next Caesar mint to fail
        vm.expectRevert(abi.encodeWithSelector(ISenatePositions.TIDUS_POSITION_FULL.selector,uint256(5)));
        senatePositions.mint(ISenatePositions.Position.Caesar, testWallets[1]);
    }

    /**
     * @dev Test Expected Burning Reverts
     */
    ///@dev - Test invalid Token ID should revert (ERC721 Standard)
    function test_invalidTokenId() external {
        // Burn a token that doesn't exist
        vm.expectRevert(abi.encodeWithSelector(ISenatePositions.TIDUS_INVALID_TOKENID.selector,uint256(1)));
        senatePositions.burn(1);
    }

    ///@dev - Test burn from non-owner or not Senate contract should revert
    function test_callerNotOwnerOfTokenOrSenateContract() external {
        // Mint a token
        senatePositions.mint(ISenatePositions.Position.Consul, testWallets[0]);

        // Expect burn to fail because caller is not owner of token or Senate contract
        vm.expectRevert(abi.encodeWithSelector(ISenatePositions.TIDUS_ONLY_TIMELOCK.selector));
        (bool burnSuccess,) = testWallets[1].delegatecall(abi.encodeWithSignature("burn(uint256)", 1));
        assertEq(burnSuccess, false);
    }

}
