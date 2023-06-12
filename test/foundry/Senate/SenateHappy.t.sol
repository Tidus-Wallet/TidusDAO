// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {SenatePositions} from "../../../contracts/ERC721/SenatePositions.sol";
import {ISenatePositions} from "../../../contracts/ERC721/interfaces/ISenatePositions.sol";
import {Senate} from "../../../contracts/governance/Senate.sol";
import {IGovernorUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/IGovernorUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Timelock} from "../../../contracts/governance/Timelock.sol";
import {IVotesUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

///@dev - AFAIK I can't instantiate a wallet within Solidity
///@dev - So making this mock wallet to test transfers.

interface Events {
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );
}

contract MockWallet is IERC721Receiver {
    function transferToken(address _token, address _to, uint256 _tokenId) external {
        IERC721(_token).transferFrom(address(this), _to, _tokenId);
    }

    function validatePositionInSenate(address _senateAddress, address _walletAddress) public view returns (bool) {
        Senate senate = Senate(payable(_senateAddress));
        bool isValid = senate.validatePosition(_walletAddress);
        return isValid;
    }

    function submitProposal(
        address _senateAddress,
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _calldatas,
        string memory description
    ) external {
        Senate senate = Senate(payable(_senateAddress));
        senate.propose(_targets, _values, _calldatas, description);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract MockTimelock is Timelock {}

contract MockProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _admin, bytes memory _data)
        TransparentUpgradeableProxy(_logic, _admin, _data)
    {}

    function implementation() external view returns (address) {
        return _implementation();
    }
}

contract TestSenate is Test, Events {
    // Senate deployment vars
    Senate public senateImpl;
    MockProxy public senate;
    Timelock public timelock;
    uint16 quorumValue;

    // SenatePositions deployment vars
    ISenatePositions public senatePositions;
    string[] metadatas = ["Consul", "Censor", "Tribune", "Senator", "Dictator"];
    uint256[] termLengths = [5 * 86400, 5 * 86400, 5 * 86400, 5 * 86400, 5 * 86400];

    // Set up Mock Wallet
    MockWallet public mockWallet;

    // Proxy Address
    address proxyAddress;

    // Test Addresses
    address[] testWallets = [
        0x84141fa1AC4084fbc8ec2cC6Dc3F055820657610,
        0x58736943CeDd4112Ee7058D63E5824942c029d42,
        0x7B08Bd13Ac6d47c1A3a7BA6F0696060e3A98b5B2,
        0x0e81C065FE246BB8B8cFe04D933B22d1ce4073d1,
        0x2A456bfbf334B6D52dFB2E1E80cf0333Cc201F40
    ];

    function setUp() external {
        // Timelock deployment
        timelock = new Timelock();

        // SenatePositions deployment
        senatePositions = new SenatePositions(
            address(this),
            address(this),
            metadatas,
            termLengths
        );

        // Senate Implementation Deployment
        senateImpl = new Senate();

        // Mock Wallet Deployment
        mockWallet = new MockWallet();

        // Set up Proxy
        senate = new MockProxy(
            address(senateImpl), address(mockWallet), abi.encodeWithSignature(
                "initialize(address,address,uint16)",
                address(timelock),
                address(senatePositions),
                0 
            )
        );

        ///@dev Verify that the proxy is pointing to the correct implementation
        assertEq(address(senateImpl), senate.implementation());

        bytes32 impSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        bytes32 proxySlot = vm.load(address(senate), impSlot);
        address addr;
        assembly {
            mstore(0, proxySlot)
            addr := mload(0)
        }
        assertEq(address(senateImpl), addr);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function test_deployment() external {
        ///@dev Verify that the Proposal Threshold is 0 votes
        (bool thresholdSuccess, bytes memory thresholdData) =
            address(senate).staticcall(abi.encodeWithSignature("proposalThreshold()"));

        assertEq(thresholdSuccess, true);
        if (thresholdSuccess) {
            uint256 proposalThreshold = abi.decode(thresholdData, (uint256));
            assertEq(proposalThreshold, type(uint256).max);
        }

        ///@dev Verify the correct SenatePositions contract is set
        (bool positionsSuccess, bytes memory positionsData) =
            address(senate).staticcall(abi.encodeWithSignature("senatePositionsContract()"));
        if (positionsSuccess) {
            assertEq(abi.decode(positionsData, (address)), address(senatePositions));
        }
    }

    function test_proposalSubmits() external {
        ///@dev Set up proposal vars
        ///@dev Targets
        address[] memory targets = new address[](1);
        targets[0] = address(senatePositions);
        ///@dev Values
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        ///@dev Calldatas
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("mint(uint8, address)", 0, address(mockWallet));

        ///@dev Mint a token to mockWallet so it can submit a proposal
        senatePositions.mint(ISenatePositions.Position.Consul, address(this));
        assertEq(senatePositions.isConsul(address(this)), true);

        ///@dev Verify that the Senate `validationPosition` is true
        (bool validationSuccess, bytes memory validationData) =
            address(senate).staticcall(abi.encodeWithSignature("validatePosition(address)", address(this)));
        assertEq(validationSuccess, true);
        if (validationSuccess) {
            assertEq(abi.decode(validationData, (bool)), true);
        }

        ///@dev Verify that the Proposal Threshold is 0 votes
        (bool thresholdSuccess, bytes memory thresholdData) =
            address(senate).staticcall(abi.encodeWithSignature("proposalThreshold()"));
        assertEq(thresholdSuccess, true);
        if (thresholdSuccess) {
            uint256 proposalThreshold = abi.decode(thresholdData, (uint256));
            assertEq(proposalThreshold, 0);
        }

        ///@dev Submit a proposal
        // vm.expectEmit();
        // emit Events.ProposalCreated(
        //     0,
        //     address(mockWallet),
        //     targets,
        //     values,
        //     new string[](0),
        //     calldatas,
        //     block.number,
        //     block.number + 100,
        //     "Test Proposal"
        // );
        (bool proposalSuccess, bytes memory proposalData) = address(senate).call(
            abi.encodeWithSignature(
                "propose(address[],uint256[],bytes[],string)", targets, values, calldatas, "Test Proposal"
            )
        );
        if (proposalSuccess) {
            console.log(abi.decode(proposalData, (uint256)));
        }
    }
}
