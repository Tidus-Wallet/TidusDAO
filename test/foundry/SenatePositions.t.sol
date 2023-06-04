pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {SenatePositions} from "../../contracts/ERC721/SenatePositions.sol";
import {ISenatePositions} from "../../contracts/ERC721/interfaces/ISenatePositions.sol";
import {Senate} from "../../contracts/governance/Senate.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

///@dev - AFAIK I can't instantiate a wallet within Solidity
///@dev - So making this mock wallet to test transfers.
contract MockWallet is IERC721Receiver {
    function transferToken(address _token, address _to, uint256 _tokenId) external {
        IERC721(_token).transferFrom(address(this), _to, _tokenId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract MockSenate is Test {
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
    function test_MintMultipleTokensToSameAddr() external {
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
            vm.expectRevert("TIDUS: Cannot mint a None position.");
        }

        // Select a wallet within the bounds of the testWallets array
        address wallet = testWallets[walletIndex % testWallets.length];

        // Mint a token to that wallet
        senatePositions.mint(ISenatePositions.Position(_position), wallet);

        // Verify the position of the token
        assertEq(uint256(senatePositions.getPosition(wallet)), uint256(_position));
    }
}
