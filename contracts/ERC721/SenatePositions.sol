//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Votes } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ISenate } from "../governance/interfaces/ISenate.sol";
import { ISenatePositions } from "./interfaces/ISenatePositions.sol";
import { ITimelock } from "../governance/interfaces/ITimelock.sol";
import { console } from "../../lib/forge-std/src/console.sol";

/// @custom:security-contact sekaieth@proton.me
contract SenatePositions is ERC721, ERC721Votes, ERC721Enumerable, Ownable, ISenatePositions {

    struct Consul {
        address consul;
        uint256 startTime;
        uint256 endTime;
    }

    struct Censor {
        address censor;
        uint256 startTime;
        uint256 endTime;
    }

    struct Tribune {
        address tribune;
        uint256 startTime;
        uint256 endTime;
    }
    
    struct Senator {
        address senator;
        uint256 startTime;
        uint256 endTime;
    }

    struct Caesar {
        address caesar;
        uint256 startTime;
        uint256 endTime;
    }

    /// @notice Track minted positions
    mapping (uint256 => Consul) public consuls;
    mapping (uint256 => Censor) public censors;
    mapping (uint256 => Tribune) public tribunes;
    mapping (uint256 => Senator) public senators;
    mapping (uint256 => Caesar) public caesars;
    mapping (address => uint256) public ownedTokens;

    /// @notice The metadata URIs for the various positions.
    string public consulMetadata;
    string public censorMetadata;
    string public tribuneMetadata;
    string public senatorMetadata;
    string public caesarMetadata;

    /// @notice The address of the Senate Voting Contract.
    ISenate public senateContract;

    /// @notice The length of time a member of the Senate is allowed to hold the position 
    uint256 public consulTermLength;
    uint256 public censorTermLength;
    uint256 public tribuneTermLength;
    uint256 public senatorTermLength;
    uint256 public caesarTermLength;

    /// @notice Track the addresses that are actively holding a position
    address[] public activeConsuls;
    address[] public activeCensors;
    address[] public activeTribunes;
    address[] public activeSenators;
    address[] public activeCaesar;

    /// @notice Address of the Timelock Contract that Executes Proposals
    ITimelock public timelockContract;

    /// @notice Track next Token ID
    uint256 public nextTokenId = 1;

    /**
     * @notice Constructor for the Senators NFT contract.
     * @param _senateContract The address of the Senate Voting Contract.
     * @param _metadatas The metadata URIs for the various positions.
     * @param _termLengths The length of time a member of the Senate is allowed to hold the position.
     */
    constructor(
        address _senateContract,
        address _timelockContract,
        string[] memory _metadatas,
        uint256[] memory _termLengths
    ) ERC721("Senators", "SENATORS") EIP712("SENATORS", "1") {

        // Instantiate the Senate Contract Address
        senateContract = ISenate(_senateContract);

        // Instantiate the Timelock Contract Address
        timelockContract = ITimelock(_timelockContract);

        // Instantiate metadata URIs
        consulMetadata = _metadatas[0];
        censorMetadata = _metadatas[1];
        tribuneMetadata = _metadatas[2];
        senatorMetadata = _metadatas[3];
        caesarMetadata = _metadatas[4];

        // Instantiate term lengths
        consulTermLength = _termLengths[0];
        censorTermLength = _termLengths[1];
        tribuneTermLength = _termLengths[2];
        senatorTermLength = _termLengths[3];
        caesarTermLength = _termLengths[4];

        
    }

    /**
     * @notice Mint a new Senators token to the given address.
     * @param _to The address to mint the token to.
     */
    function mint(Position _position, address _to) public {
        require(msg.sender == address(senateContract), "TIDUS: Only the Senate Voting Contract can mint Senators.");
        require(_to != address(0), "TIDUS: Cannot mint to the zero address.");
        require(_position != Position.None, "TIDUS: Cannot mint a None position.");
        require(balanceOf(_to) == 0, "TIDUS: Cannot mint more than one token per address.");

        if(_position == Position.Consul) {
            require(activeConsuls.length < 2, "TIDUS: Cannot mint a Consul position when there are already two Consuls.");

            // Add the Consul to the current Consuls array
            consuls[nextTokenId] = Consul({
                consul: _to,
                startTime: block.timestamp,
                endTime: block.timestamp + consulTermLength
            });

            activeConsuls.push(_to);
            ownedTokens[_to] = nextTokenId;
        }

        else if(_position == Position.Censor) {

            // Add the Censor to the current Censors array
            censors[nextTokenId] = Censor({
                censor: _to,
                startTime: block.timestamp,
                endTime: block.timestamp + censorTermLength
            });

            activeCensors.push(_to);
            ownedTokens[_to] = nextTokenId;
        }

        else if(_position == Position.Tribune) {

            // Add the Tribune to the current Tribunes array
            tribunes[nextTokenId] = Tribune({
                tribune: _to,
                startTime: block.timestamp,
                endTime: block.timestamp + tribuneTermLength
            });

            activeTribunes.push(_to);
            ownedTokens[_to] = nextTokenId;
        }

        else if(_position == Position.Senator) {

            // Add the Senator to the current Senators array
            senators[nextTokenId] = Senator({
                senator: _to,
                startTime: block.timestamp,
                endTime: block.timestamp + senatorTermLength
            });

            activeSenators.push(_to);
            ownedTokens[_to] = nextTokenId;
        }

        else if(_position == Position.Caesar) {
            require(activeCaesar.length < 1, "TIDUS: There is already a Caesar.");

            // Add the Caesar to the current Caesars array
            caesars[nextTokenId] = Caesar({
                caesar: _to,
                startTime: block.timestamp,
                endTime: block.timestamp + caesarTermLength
            });

            activeCaesar.push(_to);
            ownedTokens[_to] = nextTokenId;

        }

        else {
            revert("TIDUS: Invalid position.");
        }

        // Mint the token
        _safeMint(_to, nextTokenId);
        nextTokenId++;
    }


   /**
     * @notice Burn a Caesar token with the given token ID.
     * @param _tokenId The token ID of the Caesar token to burn.
     */
    function burn(uint256 _tokenId) public {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(msg.sender == address(senateContract) || msg.sender == ownerOf(_tokenId), "TIDUS: Only the Senate Voting Contract or Owner can burn the token.");

        address tokenOwner = ownerOf(_tokenId);
        Position position = getPosition(tokenOwner);

        if(position == Position.Consul) {
            // Remove the Consul from the current Consuls array
            for(uint i = 0; i < activeConsuls.length; i++) {
                if(activeConsuls[i] == consuls[_tokenId].consul) {
                    activeConsuls[i] = activeConsuls[activeConsuls.length - 1];
                    activeConsuls.pop();
                    break;
                }
            }

            // Delete the token from the ownedToken mapping
            delete ownedTokens[tokenOwner];
        }

        else if(position == Position.Censor) {
            // Remove the Censor from the current Censors array
            for(uint i = 0; i < activeCensors.length; i++) {
                if(activeCensors[i] == censors[_tokenId].censor) {
                    activeCensors[i] = activeCensors[activeCensors.length - 1];
                    activeCensors.pop();
                    break;
                }
            }

            // Delete the token from the ownedToken mapping
            delete ownedTokens[tokenOwner];
        }

        else if(position == Position.Tribune) {
            // Remove the Tribune from the current Tribunes array
            for(uint i = 0; i < activeTribunes.length; i++) {
                if(activeTribunes[i] == tribunes[_tokenId].tribune) {
                    activeTribunes[i] = activeTribunes[activeTribunes.length - 1];
                    activeTribunes.pop();
                    break;
                }
            }

            // Delete the token from the ownedToken mapping
            delete ownedTokens[tokenOwner];
        }

        else if(position == Position.Senator) {
            // Remove the Senator from the current Senators array
            for(uint i = 0; i < activeSenators.length; i++) {
                if(activeSenators[i] == senators[_tokenId].senator) {
                    activeSenators[i] = activeSenators[activeSenators.length - 1];
                    activeSenators.pop();
                    break;
                }
            }

            // Delete the token from the ownedToken mapping
            delete ownedTokens[tokenOwner];
        }

        else if(position == Position.Caesar) {
            // Remove the Caesar from the current Caesars array
            for(uint i = 0; i < activeCaesar.length; i++) {
                if(activeCaesar[i] == caesars[_tokenId].caesar) {
                    activeCaesar[i] = activeCaesar[activeCaesar.length - 1];
                    activeCaesar.pop();
                    break;
                }
            }

            // Delete the token from the ownedToken mapping
            delete ownedTokens[tokenOwner];
        }

        else {
            revert("TIDUS: Invalid position");
        }

        _burn(_tokenId);
    }

    /**
     * @notice Get the token URI for the position.
     * @param _tokenId The token ID to get the URI for.
     * @return uri The token URI for the position.
     */
    function tokenURI(uint256 _tokenId) public view override(ERC721, ISenatePositions) returns (string memory uri) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        Position position = getPosition(ownerOf(_tokenId));

        // Get the position of the token and return metadata
        if (position == Position.Consul) {
            uri = consulMetadata;
        } else if (position == Position.Censor) {
            uri = censorMetadata;
        } else if (position == Position.Tribune) {
            uri = tribuneMetadata;
        } else if (position == Position.Senator) {
            uri = senatorMetadata;
        } else if (position == Position.Caesar) {
            uri = caesarMetadata;
        } else {
            revert("TIDUS: Invalid position.");
        }     
    }

    /**
     * @notice Determine given address' Position.
     * @param _address The address to check.
     * @return The Position of the address.
     */
    function getPosition(address _address) public view returns (Position) {
        if (isConsul(_address)) {
            return Position.Consul;
        } else if (isCensor(_address)) {
            return Position.Censor;
        } else if (isTribune(_address)) {
            return Position.Tribune;
        } else if (isSenator(_address)) {
            return Position.Senator;
        } else if (isCaesar(_address)) {
            return Position.Caesar;
        } else {
            return Position.None;
        }
    }

    /**
     * @notice Determine if given address is a Consul.
     * @param _address The address to check.
     * @return _isConsul True if address is a Consul.
     */
    function isConsul(address _address) public view returns (bool) {
        // Get the token that the address owns
        uint256 ownedTokenId = ownedTokens[_address];

        ///@dev - If the returned tokenID is 0, the address does not own a token.
        ///@dev - We start the token IDs at 1 for this reason.
        if(ownedTokenId == 0) {
            return false;
        }

        // Loop through active Consuls and check if address is a Consul
        for (uint i = 0; i < activeConsuls.length; i++) {
            if (activeConsuls[i] == _address && block.timestamp < consuls[ownedTokenId].endTime) {
                return true;
            }
        }

        return false;
    }

    /** 
     * @notice Check if address is a Senator
     * @param _address The address to check
     * @return True if address is a Senator
     */
    function isSenator(address _address) public view returns (bool) {
        // Get the token that the address owns
        uint256 ownedTokenId = ownedTokens[_address];

        if(ownedTokenId == 0) {
            return false;
        }

        // Loop through active Senators and check if address is a Senator
        for (uint i = 0; i < activeSenators.length; i++) {
            if (activeSenators[i] == _address && block.timestamp < senators[ownedTokenId].endTime) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Determine if given address is a Censor.
     * @param _address The address to check.
     * @return True if address is a Censor.
     */
    function isCensor(address _address) public view returns (bool) {
        // Get the token that the address owns
        uint256 ownedTokenId = ownedTokens[_address];

        if(ownedTokenId == 0) {
            return false;
        }

        // Loop through active Censors and check if address is a Censor
        for (uint i = 0; i < activeCensors.length; i++) {
            if (activeCensors[i] == _address && block.timestamp < censors[ownedTokenId].endTime) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Determine if given address is a Tribune.
     * @param _address The address to check.
     * @return True if address is a Tribune.
     */
    function isTribune(address _address) public view returns (bool) {
        // Get the token that the address owns
        uint256 ownedTokenId = ownedTokens[_address];

        if(ownedTokenId == 0) {
            return false;
        }

        // Loop through active Tribunes and check if address is a Tribune
        for (uint i = 0; i < activeTribunes.length; i++) {
            if (activeTribunes[i] == _address && block.timestamp < tribunes[ownedTokenId].endTime) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Determine if given address is a Caesar.
     * @param _address The address to check.
     * @return True if address is a Caesar.
     */
    function isCaesar(address _address) public view returns (bool) {
        // Get the token that the address owns
        uint256 ownedTokenId = ownedTokens[_address];

        if(ownedTokenId == 0) {
            return false;
        }

        // Loop through active Caesars and check if address is a Caesar
        for (uint i = 0; i < activeCaesar.length; i++) {
            if (activeCaesar[i] == _address && block.timestamp < caesars[ownedTokenId].endTime) {
                return true;
            }
        }

        return false;
    }


    /**
     * @notice Update the metadata URI for the Censor contract.
     * @param _updatedMetadata The updated metadata URI as a string.
     */
    function updateMetadata(Position _position, string calldata _updatedMetadata) public onlyOwner {
    }

    /**
     * @notice Update the Senate Voting Contract address.
     * @param _updatedSenateAddress The updated Senate Voting Contract address.
     */
    function updateSenateAddress(address _updatedSenateAddress) public onlyOwner {
        senateContract = ISenate(_updatedSenateAddress);

    }

    /**
     * @notice Update the position's term length
     * @param _position The position to update
     * @param _newTermLength The new term length
     */
    function updateTermLength(Position _position, uint256 _newTermLength) public {
        require(msg.sender == address(timelockContract), "TIDUS: Only timelock contract can update term length.");
        require(_newTermLength > 0, "TIDUS: Term length must be greater than 0.");

        if(_position == Position.Consul) {
            consulTermLength = _newTermLength;
        } else if(_position == Position.Censor) {
            censorTermLength = _newTermLength;
        } else if(_position == Position.Tribune) {
            tribuneTermLength = _newTermLength;
        } else if(_position == Position.Senator) {
            senatorTermLength = _newTermLength;
        } else if(_position == Position.Caesar) {
            caesarTermLength = _newTermLength;
        } else {
            revert("TIDUS: Invalid position.");
        }
    }

    /**
     * @notice Internal function to transfer a Censor token.
     * @param from The address to transfer the token from.
     * @param to The address to transfer the token to.
     * @param tokenId The token ID of the Censor token to transfer.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(to == address(senateContract), "TIDUS: Only the Senate Voting Contract can receive Senator tokens.");
        super._transfer(from, to, tokenId);
    }

    // Overrides to prevent errors with multiple inheritance of the same function.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Votes) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
