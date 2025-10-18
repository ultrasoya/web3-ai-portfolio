// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Structs} from "./shared/Structs.sol";

/**
 * @title ReportNFT
 * @author Your Name
 * @notice This contract manages NFT tokens for reports in the Web3 AI Portfolio platform
 * @dev Implements ERC721 standard for non-fungible tokens representing reports
 */
contract ReportNFT is ERC721, Ownable {
    address immutable i_reportManager;
    string private _baseTokenURI;

    mapping(uint256 => Structs.IpfsCID) private tokenToIpfsCID;

    constructor(
        address reportManager,
        string memory baseTokenURI
    ) ERC721("ReportNFT", "REPORT") Ownable(msg.sender) {
        i_reportManager = reportManager;
        _baseTokenURI = baseTokenURI;
    }

    error NotReportManager();
    error NotTokenOwner();

    modifier onlyReportManager() {
        if (msg.sender != i_reportManager) {
            revert NotReportManager();
        }
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotTokenOwner();
        }
        _;
    }

    event ReportMinted(
        address indexed mintOwner,
        uint256 indexed _tokenId,
        Structs.IpfsCID _ipfsCID
    );

    event ReportBurned(uint256 indexed tokenId);

    /**
     * @notice Mints a new NFT token for a report
     * @param mintOwner Address to mint the token to
     * @param tokenId ID of the token to mint
     * @param ipfsCID IPFS CID of the report
     */
    function mint(
        address mintOwner,
        uint256 tokenId,
        Structs.IpfsCID calldata ipfsCID
    ) external onlyReportManager {
        tokenToIpfsCID[tokenId] = ipfsCID;
        _safeMint(mintOwner, tokenId);

        emit ReportMinted(mintOwner, tokenId, ipfsCID);
    }

    function _getBaseURI() internal view returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(
        string memory newBaseTokenURI
    ) external onlyReportManager {
        _baseTokenURI = newBaseTokenURI;
    }

    /**
     * @notice Returns the URI for a given token ID
     * @param tokenId ID of the token to query
     * @return The URI string for the token metadata
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _getBaseURI(),
                    tokenToIpfsCID[tokenId].hashDigest,
                    ".json"
                )
            );
    }

    /**
     * @notice Burns a report NFT token
     * @param tokenId ID of the token to burn
     */
    function burnReport(uint256 tokenId) public onlyReportManager {
        _burn(tokenId);

        emit ReportBurned(tokenId);
    }

    function getIpfsCID(
        uint256 tokenId
    ) public view returns (Structs.IpfsCID memory) {
        return tokenToIpfsCID[tokenId];
    }
}
