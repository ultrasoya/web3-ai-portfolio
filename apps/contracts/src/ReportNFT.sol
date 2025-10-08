// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ReportNFT
 * @author Your Name
 * @notice This contract manages NFT tokens for reports in the Web3 AI Portfolio platform
 * @dev Implements ERC721 standard for non-fungible tokens representing reports
 */
contract ReportNFT is IERC721, Ownable {
    /// @notice Current token ID counter
    uint256 tokenId;

    /// @notice Base URI for token metadata
    string tokenURI;

    /**
     * @notice Constructor that initializes the contract owner
     * @dev Sets the deployer as the owner of the contract
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Mints a new NFT token for a report
     * @param to Address to mint the token to
     * @param _tokenId ID of the token to mint
     * @param _tokenURI URI hash for the token metadata
     * @dev Only the contract owner can call this function
     * @dev Increments the token ID counter and mints the token
     */
    function mint(
        address to,
        uint256 _tokenId,
        bytes32 _tokenURI
    ) external onlyOwner {
        tokenId++;
        tokenURI = _tokenURI;
        _mint(to, tokenId);
    }

    /**
     * @notice Returns the URI for a given token ID
     * @param _tokenId ID of the token to query
     * @return The URI string for the token metadata
     * @dev Returns the base token URI for all tokens
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return tokenURI;
    }

    /**
     * @notice Returns the owner of a given token ID
     * @param _tokenId ID of the token to query
     * @return The address of the token owner
     * @dev This function has a recursive call issue that should be fixed
     */
    function ownerOf(uint256 _tokenId) external view returns (address) {
        return ownerOf(_tokenId);
    }
}
