// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {SenatePositions} from "../../../contracts/ERC721/SenatePositions.sol";
import {ISenatePositions} from "../../../contracts/ERC721/interfaces/ISenatePositions.sol";
import {Senate} from "../../../contracts/governance/Senate.sol";
import {ISenate} from "../../../contracts/governance/interfaces/ISenate.sol";
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

contract TestSenateHappy is Test, Events {
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
    }

    function submitProposalHelper() internal returns (uint256) {
        // Submit a new proposal
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
        
        (bool proposalSuccess, bytes memory proposalData) = address(senate).call(
            abi.encodeWithSignature(
                "propose(address[],uint256[],bytes[],string)", targets, values, calldatas, "Test Proposal"
            )
        );
        assertEq(proposalSuccess, true);
        uint256 proposalId = abi.decode(proposalData, (uint256));
        return proposalId;
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
            assertEq(proposalThreshold, 0);
        }

        ///@dev Verify the correct SenatePositions contract is set
        (bool positionsSuccess, bytes memory positionsData) =
            address(senate).staticcall(abi.encodeWithSignature("senatePositionsContract()"));
        if (positionsSuccess) {
            assertEq(abi.decode(positionsData, (address)), address(senatePositions));
        }
        
        ///@dev Verify voting delay
        (bool delaySuccess, bytes memory delayData) =
            address(senate).staticcall(abi.encodeWithSignature("votingDelay()"));
        if (delaySuccess) {
            uint256 votingDelay = abi.decode(delayData, (uint256));
            uint256 expectedDelay = 1;
            assertEq(votingDelay, expectedDelay);
        }

        ///@dev Verify Voting Period
        (bool periodSuccess, bytes memory periodData) =
            address(senate).staticcall(abi.encodeWithSignature("votingPeriod()"));
        if (periodSuccess) {
            uint256 votingPeriod = abi.decode(periodData, (uint256));
            uint256 expectedPeriod = 21600;
            assertEq(votingPeriod, expectedPeriod);
        }
        
        ///@dev Verify Quorum
        (bool quorumSuccess, bytes memory quorumData) =
            address(senate).staticcall(abi.encodeWithSignature("quorum(uint256)", block.number));
        if (quorumSuccess) {
            uint256 quorum = abi.decode(quorumData, (uint256));
            uint256 expectedQuorum = 0;
            assertEq(quorum, expectedQuorum);
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



        ///@dev Verify that the Proposal Threshold is 0 votes
        (bool thresholdSuccess, bytes memory thresholdData) =
            address(senate).staticcall(abi.encodeWithSignature("proposalThreshold()"));
        assertEq(thresholdSuccess, true);
        if (thresholdSuccess) {
            uint256 proposalThreshold = abi.decode(thresholdData, (uint256));
            assertEq(proposalThreshold, 0);
        }

        (bool proposalSuccess, bytes memory proposalData) = address(senate).call(
            abi.encodeWithSignature(
                "propose(address[],uint256[],bytes[],string)", targets, values, calldatas, "Test Proposal"
            )
        );
        if (proposalSuccess) {
            // Verify proposal ID
            uint256 hashedProposal = uint256(keccak256(abi.encode(targets, values, calldatas, keccak256(bytes("Test Proposal")))));
            assertEq(abi.decode(proposalData, (uint256)), hashedProposal);  

            // Verify proposal is 'Pending' (uint8 0)
            (bool proposalStateSuccess, bytes memory proposalStateData) =
                address(senate).staticcall(abi.encodeWithSignature("proposalState(uint256)", hashedProposal));
            if (proposalStateSuccess) {
                uint8 proposalState = abi.decode(proposalStateData, (uint8));
                uint8 expectedStatePending = 0;
                assertEq(proposalState, expectedStatePending);
            }

            // Change block number to 2 as the contract was deployed at block 2
            vm.roll(2);

            // Verify proposal details
            /// Proposal State == 'Active' (uint8 1)
            (bool proposalStateSuccess2, bytes memory proposalStateData2) =
                address(senate).staticcall(abi.encodeWithSignature("proposalState(uint256)", hashedProposal));
            if (proposalStateSuccess2) {
                uint8 expectedStateActive = 1;
                uint8 proposalState = abi.decode(proposalStateData2, (uint8));
                assertEq(proposalState, expectedStateActive);
            }

            /// Proposal Snapshot
            uint256 expectedSnapshot = block.number;
            (bool snapshotSuccess, bytes memory snapshotData) =
                address(senate).staticcall(abi.encodeWithSignature("proposalSnapshot(uint256)", hashedProposal));
                if(snapshotSuccess) {
                    uint256 snapshot = abi.decode(snapshotData, (uint256));
                    assertEq(snapshot, expectedSnapshot);
                }
            /// Proposal Deadline
            uint256 expectedDeadline = block.number + 21600;
            (bool deadlineSuccess, bytes memory deadlineData) =
                address(senate).staticcall(abi.encodeWithSignature("proposalDeadline(uint256)", hashedProposal));
                if(deadlineSuccess) {
                    uint256 deadline = abi.decode(deadlineData, (uint256));
                    assertEq(deadline, expectedDeadline);
                }
        }
    }

    function test_castVote() external {
        uint256 proposalId = submitProposalHelper();

        // Change block number to make proposal active 
        vm.roll(5);

        // Verify proposal state is Active
        (bool proposalStateSuccess, bytes memory proposalStateData) =
            address(senate).staticcall(abi.encodeWithSignature("proposalState(uint256)", proposalId));
            if(proposalStateSuccess) {
                uint8 proposalStateActive = abi.decode(proposalStateData, (uint8));
                uint8 expectedProposalState = 1;
                assertEq(proposalStateActive, expectedProposalState);
            }
        
        // Cast vote on proposal
        uint8 vote = 1; // Vote for proposal
        (bool voteSuccess, bytes memory voteData) = address(senate).call(
            abi.encodeWithSignature("castVote(uint256,uint8)", proposalId, vote)
        );
            if(voteSuccess) {
                uint256 expectedVoteWeight = 0; 
                uint256 voteWeight = abi.decode(voteData, (uint256));
                // Using ERC721 so vote weight should be 0
                assertEq(voteWeight, expectedVoteWeight);
            }

        // Verify vote is cast
        (bool hasVotedSuccess, bytes memory hasVotedData) =
            address(senate).staticcall(abi.encodeWithSignature("hasVoted(uint256,address)", proposalId, address(this)));
            if(hasVotedSuccess) {
                bool hasVoted = abi.decode(hasVotedData, (bool));
                bool expectedVote = true;
                assertEq(hasVoted, expectedVote);
            }
    }

    function test_ProposalSucceeded() external {
        uint256 proposalId = submitProposalHelper();

        // Change block number to make proposal active
        vm.roll(5);

        // Cast vote on proposal
        uint8 vote = 1; // Vote for proposal
        (bool voteSuccess, bytes memory voteData) = address(senate).call(
            abi.encodeWithSignature("castVote(uint256,uint8)", proposalId, vote)
        );
            if(voteSuccess) {
                uint256 expectedVoteWeight = 0; 
                uint256 voteWeight = abi.decode(voteData, (uint256));
                // Using ERC721 so vote weight should be 0
                assertEq(voteWeight, expectedVoteWeight);
            }
        
        // Change block number to get past deadline 
        vm.roll(21603);

        // Verify proposal state is Succeeded
        (bool proposalStateSuccess, bytes memory proposalStateData) =
            address(senate).staticcall(abi.encodeWithSignature("state(uint256)", proposalId));
            if(proposalStateSuccess) {
                uint8 proposalStateSucceeded = abi.decode(proposalStateData, (uint8));
                uint8 expectedProposalState = 2;
                assertEq(proposalStateSucceeded, expectedProposalState);
            }
    }

    function test_ProposalDefeated() external {
        uint256 proposalId = submitProposalHelper();

        // Change block number to make proposal active
        vm.roll(5);

        // Cast vote on proposal
        uint8 vote = 0; // Vote against proposal
        (bool voteSuccess, bytes memory voteData) = address(senate).call(
            abi.encodeWithSignature("castVote(uint256,uint8)", proposalId, vote)
        );
            if(voteSuccess) {
                uint256 expectedVoteWeight = 0; 
                uint256 voteWeight = abi.decode(voteData, (uint256));
                // Using ERC721 so vote weight should be 0
                assertEq(voteWeight, expectedVoteWeight);
            }
        
        // Change block number to get past deadline 
        vm.roll(21603);

        // Verify proposal state is Defeated
        (bool proposalStateSuccess, bytes memory proposalStateData) =
            address(senate).staticcall(abi.encodeWithSignature("state(uint256)", proposalId));
            if(proposalStateSuccess) {
                uint8 proposalStateDefeated = abi.decode(proposalStateData, (uint8));
                uint8 expectedProposalState = 3;
                assertEq(proposalStateDefeated, expectedProposalState);
            }
    }

    function test_ConsulVeto() external {
        uint256 proposalId = submitProposalHelper();

        // Change block number to make proposal active, verify status
        vm.roll(5);
        (bool proposalStateTx, bytes memory proposalStateTxData) =
            address(senate).staticcall(abi.encodeWithSignature("proposalState(uint256)", proposalId));
            if(proposalStateTx) {
                uint8 proposalStateActive = abi.decode(proposalStateTxData, (uint8));
                uint8 expectedProposalState = 1;
                assertEq(proposalStateActive, expectedProposalState);
            }


        // Cast vote on proposal
        uint8 vote = 1; // Vote for proposal
        (bool voteSuccess, bytes memory voteData) = address(senate).call(
            abi.encodeWithSignature("castVote(uint256,uint8)", proposalId, vote)
        );
            if(voteSuccess) {
                uint256 expectedVoteWeight = 0; 
                uint256 voteWeight = abi.decode(voteData, (uint256));
                // Using ERC721 so vote weight should be 0
                assertEq(voteWeight, expectedVoteWeight);
            }
        
        // Change block number to get past deadline 
        vm.roll(21603);

        // Verify proposal state is Succeeded
        (bool proposalStateSuccess, bytes memory proposalStateData) =
            address(senate).staticcall(abi.encodeWithSignature("state(uint256)", proposalId));
            if(proposalStateSuccess) {
                uint8 proposalStateSucceeded = abi.decode(proposalStateData, (uint8));
                uint8 expectedProposalState = 2;
                assertEq(proposalStateSucceeded, expectedProposalState);
            }



        // Verify proposal state is Defeated
        (bool proposalStateSuccess2, bytes memory proposalStateData2) =
            address(senate).staticcall(abi.encodeWithSignature("state(uint256)", proposalId));
            if(proposalStateSuccess2) {
                uint8 proposalStateDefeated = abi.decode(proposalStateData2, (uint8));
                uint8 expectedProposalState = 3;
                assertEq(proposalStateDefeated, expectedProposalState);
            }
    }
    
    function test_consulVeto() external {
        uint256 proposalId = submitProposalHelper();

        // Change block number to make proposal active, verify status
        vm.roll(5);

        // Cast vote on proposal
        uint8 vote = 1; // Vote for proposal
        (bool voteSuccess, bytes memory voteData) = address(senate).call(
            abi.encodeWithSignature("castVote(uint256,uint8)", proposalId, vote)
        );
            if(voteSuccess) {
                uint256 expectedVoteWeight = 0; 
                uint256 voteWeight = abi.decode(voteData, (uint256));
                // Using ERC721 so vote weight should be 0
                assertEq(voteWeight, expectedVoteWeight);
            }

        // Change block number to get past deadline
        vm.roll(21603);

        // Cast Consul Veto
        (bool consulVetoSuccess, bytes memory consulVetoData) = address(senate).call(
            abi.encodeWithSignature("consulVeto(uint256)", proposalId)
        );
            if(consulVetoSuccess) {
                // Verify Consul Veto Response 
                bool expectedVetoResponse = true;
                bool vetoResponse = abi.decode(consulVetoData, (bool));
                assertEq(expectedVetoResponse, vetoResponse);
            }

        // Verify proposal veto status 
        (bool vetoBoolSuccess, bytes memory vetoBoolData) = address(senate).staticcall(
            abi.encodeWithSignature("hasConsulVetoed(uint256,address)", proposalId, address(this))
        );
            if(vetoBoolSuccess) {
                bool expectedVetoBool = true;
                bool vetoBool = abi.decode(vetoBoolData, (bool));
                assertEq(expectedVetoBool, vetoBool);
            }

        // Verify proposal veto count
        (bool vetoCountSuccess, bytes memory vetoCountData) = address(senate).staticcall(
            abi.encodeWithSignature("consulVetoCount(uint256)", proposalId)
        );
            if(vetoCountSuccess) {
                uint8 expectedVetoCount = 1;
                uint8 vetoCount = abi.decode(vetoCountData, (uint8));
                assertEq(expectedVetoCount, vetoCount);
            }
    }
}

