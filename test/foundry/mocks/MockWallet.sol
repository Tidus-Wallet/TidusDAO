// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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
