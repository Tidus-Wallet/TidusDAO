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

    struct Dictator {
        address dictator;
        uint256 startTime;
        uint256 endTime;
    }

    /// @notice Track minted positions
    mapping (uint256 => Consul) public consuls;
    mapping (uint256 => Censor) public censors;
    mapping (uint256 => Tribune) public tribunes;
    mapping (uint256 => Senator) public senators;
    mapping (uint256 => Dictator) public dictators;

    /// @notice The metadata URIs for the various positions.
    string public consulMetadata;
    string public censorMetadata;
    string public tribuneMetadata;
    string public senatorMetadata;
    string public dictatorMetadata;

    /// @notice The address of the Senate Voting Contract.
    ISenate public senateContract;

    /// @notice The length of time a member of the Senate is allowed to hold the position 
    uint256 public consulTermLength;
    uint256 public censorTermLength;
    uint256 public tribuneTermLength;
    uint256 public senatorTermLength;
    uint256 public dictatorTermLength;

    /// @notice Track the addresses that are actively holding a position
    address[] public activeConsuls;
    address[] public activeCensors;
    address[] public activeTribunes;
    address[] public activeSenators;
    address[] public activeDictator;

    /// @notice Address of the Timelock Contract that Executes Proposals
    ITimelock public timelockContract;

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
        dictatorMetadata = _metadatas[4];

        // Instantiate term lengths
        consulTermLength = _termLengths[0];
        censorTermLength = _termLengths[1];
        tribuneTermLength = _termLengths[2];
        senatorTermLength = _termLengths[3];
        dictatorTermLength = _termLengths[4];
        
    }

    /**
     * @notice Mint a new Senators token to the given address.
     * @param _to The address to mint the token to.
     */
    function mint(Position _position, address _to) public {
        require(msg.sender == address(senateContract), "TIDUS: Only the Senate Voting Contract can mint Senators.");
        require(_to != address(0), "TIDUS: Cannot mint to the zero address.");
        require(_position != Position.None, "TIDUS: Cannot mint a None position.");

        if(_position == Position.Consul) {
            require(activeConsuls.length < 2, "TIDUS: Cannot mint a Consul position when there are already two Consuls.");

            // Add the Consul to the current Consuls array
            consuls[totalSupply()] = Consul({
                consul: _to,
                startTime: block.timestamp,
                endTime: block.timestamp + consulTermLength
            });

            activeConsuls.push(_to);

            // Mint the token
            _safeMint(_to, totalSupply());
        }

        else if(_position == Position.Censor) {

            // Add the Censor to the current Censors array
            censors[totalSupply()] = Censor({
                censor: _to,
                startTime: block.timestamp,
                endTime: block.timestamp + censorTermLength
            });

            activeCensors.push(_to);

            // Mint the token
            _safeMint(_to, totalSupply());
        }

        else if(_position == Position.Tribune) {

            // Add the Tribune to the current Tribunes array
            tribunes[totalSupply()] = Tribune({
                tribune: _to,
                startTime: block.timestamp,
                endTime: block.timestamp + tribuneTermLength
            });

            activeTribunes.push(_to);

            // Mint the token
            _safeMint(_to, totalSupply());
        }

        else if(_position == Position.Senator) {

            // Add the Senator to the current Senators array
            senators[totalSupply()] = Senator({
                senator: _to,
                startTime: block.timestamp,
                endTime: block.timestamp + senatorTermLength
            });

            activeSenators.push(_to);

            // Mint the token
            _safeMint(_to, totalSupply());
        }

        else if(_position == Position.Dictator) {
            require(activeDictator.length < 1, "TIDUS: There is already a Dictator.");

            // Add the Dictator to the current Dictators array
            dictators[totalSupply()] = Dictator({
                dictator: _to,
                startTime: block.timestamp,
                endTime: block.timestamp + dictatorTermLength
            });

            activeDictator.push(_to);

            // Mint the token
            _safeMint(_to, totalSupply());
        }

        else {
            revert("TIDUS: Invalid position.");
        }

    }


   /**
     * @notice Burn a Dictator token with the given token ID.
     * @param _tokenId The token ID of the Dictator token to burn.
     */
    function burn(uint256 _tokenId) public {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(msg.sender == address(senateContract) || msg.sender == ownerOf(_tokenId), "TIDUS: Only the Senate Voting Contract or Owner can burn the token.");

        Position position = getPosition(ownerOf(_tokenId));

        if(position == Position.Consul) {
            // Remove the Consul from the current Consuls array
            for(uint i = 0; i < activeConsuls.length; i++) {
                if(activeConsuls[i] == consuls[_tokenId].consul) {
                    activeConsuls[i] = activeConsuls[activeConsuls.length - 1];
                    activeConsuls.pop();
                    break;
                }
            }
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
        }

        if(position == Position.Senator) {
            // Remove the Senator from the current Senators array
            for(uint i = 0; i < activeSenators.length; i++) {
                if(activeSenators[i] == senators[_tokenId].senator) {
                    activeSenators[i] = activeSenators[activeSenators.length - 1];
                    activeSenators.pop();
                    break;
                }
            }
        }

        else if(position == Position.Dictator) {
            // Remove the Dictator from the current Dictators array
            for(uint i = 0; i < activeDictator.length; i++) {
                if(activeDictator[i] == dictators[_tokenId].dictator) {
                    activeDictator[i] = activeDictator[activeDictator.length - 1];
                    activeDictator.pop();
                    break;
                }
            }
        }

        else {
            revert("TIDUS: Invalid position.");
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

        // Get the position of the token and return metadata
        if (isConsul(ownerOf(_tokenId))) {
            uri = consulMetadata;
        } else if (isCensor(ownerOf(_tokenId))) {
            uri = censorMetadata;
        } else if (isTribune(ownerOf(_tokenId))) {
            uri = tribuneMetadata;
        } else if (isSenator(ownerOf(_tokenId))) {
            uri = senatorMetadata;
        } else if (isDictator(ownerOf(_tokenId))) {
            uri = dictatorMetadata;
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
        } else if (isDictator(_address)) {
            return Position.Dictator;
        } else {
            return Position.None;
        }
    }

    /**
     * @notice Determine if given address is a Consul.
     * @param _address The address to check.
     * @return True if address is a Consul.
     */
    function isConsul(address _address) public view returns (bool) {
        for (uint i = 0; i < activeConsuls.length; i++) {
            if (activeConsuls[i] == _address && block.timestamp < consuls[i].endTime) {
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
        for (uint i = 0; i < activeSenators.length; i++) {
            if (activeSenators[i] == _address && block.timestamp < senators[i].endTime) {
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
        for (uint i = 0; i < activeCensors.length; i++) {
            if (activeCensors[i] == _address && block.timestamp < censors[i].endTime) {
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
        for (uint i = 0; i < activeTribunes.length; i++) {
            if (activeTribunes[i] == _address && block.timestamp < tribunes[i].endTime) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Determine if given address is a Dictator.
     * @param _address The address to check.
     * @return True if address is a Dictator.
     */
    function isDictator(address _address) public view returns (bool) {
        for (uint i = 0; i < activeDictator.length; i++) {
            if (activeDictator[i] == _address && block.timestamp < dictators[i].endTime) {
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
        } else if(_position == Position.Dictator) {
            dictatorTermLength = _newTermLength;
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
        require(to == address(0) || to == address(senateContract), "TIDUS: Only the Senate Voting Contract can receive Senator tokens.");
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