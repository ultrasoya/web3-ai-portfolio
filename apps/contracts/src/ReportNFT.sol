// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ReportNFT is IERC721, Ownable {
    uint256 tokenId;
    string tokenURI;

    constructor() Ownable(msg.sender) {}

    function mint(
        address to,
        uint256 _tokenId,
        bytes32 _tokenURI
    ) external onlyOwner {
        tokenId++;
        tokenURI = _tokenURI;
        _mint(to, tokenId);
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return tokenURI;
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return ownerOf(_tokenId);
    }
}
