// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Structs} from "./shared/Structs.sol";

/**
 * @title ReportNFT
 * @author Your Name
 * @notice This contract manages NFT tokens for reports in the Web3 AI Portfolio platform
 * @dev Implements ERC721 standard for non-fungible tokens representing reports
 */
contract ReportNFT is IERC721, Ownable {
    address immutable i_reportManager;

    mapping(uint256 => Structs.IpfsCID) public reportToOwner;

    constructor(address reportManager) Ownable(msg.sender) {
        i_reportManager = reportManager;
    }

    error NotReportManager();

    modifier onlyReportManager() {
        if (msg.sender != i_reportManager) {
            revert NotReportManager();
        }
        _;
    }

    event ReportMinted(
        address indexed mintOwner,
        uint256 indexed _tokenId,
        Structs.IpfsCID _ipfsCID
    );

    /**
     * @notice Mints a new NFT token for a report
     * @param mintOwner Address to mint the token to
     * @param _tokenId ID of the token to mint
     * @param _ipfsCID IPFS CID of the report
     */
    function mint(
        address mintOwner,
        uint256 _tokenId,
        Structs.IpfsCID _ipfsCID
    ) external onlyReportManager {
        reportToOwner[_tokenId] = _ipfsCID;
        _safeMint(mintOwner, _tokenId);

        emit ReportMinted(mintOwner, _tokenId, _ipfsCID);
    }

    /**
     * @notice Returns the URI for a given token ID
     * @param _tokenId ID of the token to query
     * @return The URI string for the token metadata
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "https://ipfs.io/ipfs/",
                    reportToOwner[_tokenId].hashDigest
                )
            );
    }

    // /// @notice Current token ID counter
    // uint256 tokenId;

    // /// @notice Base URI for token metadata
    // string tokenURI;

    // /**
    //  * @notice Constructor that initializes the contract owner
    //  * @dev Sets the deployer as the owner of the contract
    //  */
    // constructor() Ownable(msg.sender) {}

    // /**
    //  * @notice Mints a new NFT token for a report
    //  * @param to Address to mint the token to
    //  * @param _tokenId ID of the token to mint
    //  * @param _tokenURI URI hash for the token metadata
    //  * @dev Only the contract owner can call this function
    //  * @dev Increments the token ID counter and mints the token
    //  */
    // function mint(
    //     address to,
    //     uint256 _tokenId,
    //     bytes32 _tokenURI
    // ) external onlyOwner {
    //     tokenId++;
    //     tokenURI = _tokenURI;
    //     _mint(to, tokenId);
    // }

    // /**
    //  * @notice Returns the URI for a given token ID
    //  * @param _tokenId ID of the token to query
    //  * @return The URI string for the token metadata
    //  * @dev Returns the base token URI for all tokens
    //  */
    // function tokenURI(uint256 _tokenId) external view returns (string memory) {
    //     return tokenURI;
    // }

    // /**
    //  * @notice Returns the owner of a given token ID
    //  * @param _tokenId ID of the token to query
    //  * @return The address of the token owner
    //  * @dev This function has a recursive call issue that should be fixed
    //  */
    // function ownerOf(uint256 _tokenId) external view returns (address) {
    //     return ownerOf(_tokenId);
    // }
}
