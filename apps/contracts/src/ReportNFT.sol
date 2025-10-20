// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ReportNFT
 * @author Web3 AI Portfolio Team
 * @notice Contract for managing NFT tokens representing reports in the Web3 AI Portfolio platform
 * @dev Implements ERC721 standard for non-fungible tokens representing reports
 * @custom:security-contact security@web3aiportfolio.com
 */
contract ReportNFT is ERC721, Ownable {
    /// @notice Address of the ReportManager contract that has permission to mint and burn tokens
    address public reportManager;

    /// @dev Base URI for token metadata (e.g., ipfs:// or https://)
    string private baseTokenURI;

    /// @dev Mapping to associate tokenId with CID (Content Identifier) in IPFS
    mapping(uint256 => string) private tokenToCID;

    /**
     * @notice Initializes the ReportNFT contract
     * @dev Sets msg.sender as owner through Ownable
     * @param _reportManager Address of the ReportManager contract
     * @param _baseTokenURI Base URI for tokens (e.g., "ipfs://")
     */
    constructor(
        address _reportManager,
        string memory _baseTokenURI
    ) ERC721("ReportNFT", "REPORT") Ownable(msg.sender) {
        reportManager = _reportManager;
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Error thrown when caller is not the ReportManager
    error NotReportManager();

    /// @notice Error thrown when caller is not the token owner
    error NotTokenOwner();

    /**
     * @notice Modifier to restrict access to ReportManager only
     * @dev Checks that msg.sender == reportManager
     */
    modifier onlyReportManager() {
        if (msg.sender != reportManager) {
            revert NotReportManager();
        }
        _;
    }

    /**
     * @notice Modifier to restrict access to token owner only
     * @dev Checks that msg.sender is the owner of the specified tokenId
     * @param tokenId Token ID to check ownership for
     */
    modifier onlyTokenOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotTokenOwner();
        }
        _;
    }

    /**
     * @notice Emitted when a new report is minted
     * @param mintOwner Address of the token recipient
     * @param _tokenId ID of the minted token
     * @param _cid IPFS CID of the report
     */
    event ReportMinted(
        address indexed mintOwner,
        uint256 indexed _tokenId,
        string _cid
    );

    /**
     * @notice Emitted when a report is burned
     * @param tokenId ID of the burned token
     */
    event ReportBurned(uint256 indexed tokenId);

    /**
     * @notice Emitted when the base URI is updated
     * @param newBaseTokenURI New base URI for tokens
     */
    event BaseURIUpdated(string newBaseTokenURI);

    /**
     * @notice Mints a new NFT token for a report
     * @dev Can only be called by ReportManager contract. Uses _safeMint for secure minting
     * @param mintOwner Address of the token recipient
     * @param tokenId Token ID to mint
     * @param cid IPFS CID of the report
     * @custom:emits ReportMinted
     */
    function mint(
        address mintOwner,
        uint256 tokenId,
        string calldata cid
    ) external onlyReportManager {
        tokenToCID[tokenId] = cid;
        _safeMint(mintOwner, tokenId);

        emit ReportMinted(mintOwner, tokenId, cid);
    }

    /**
     * @notice Sets a new base URI for token metadata
     * @dev Can only be called by ReportManager contract
     * @param newBaseTokenURI New base URI (e.g., "ipfs://" or "https://api.example.com/metadata/")
     * @custom:emits BaseURIUpdated
     */
    function setBaseURI(
        string calldata newBaseTokenURI
    ) external onlyReportManager {
        baseTokenURI = newBaseTokenURI;

        emit BaseURIUpdated(newBaseTokenURI);
    }

    /**
     * @notice Updates the ReportManager contract address
     * @dev Can only be called by contract owner. Use with caution!
     * @param newReportManager New address of the ReportManager contract
     */
    function setReportManager(address newReportManager) external onlyOwner {
        reportManager = newReportManager;
    }

    /**
     * @notice Returns the metadata URI for a given token
     * @dev Overrides tokenURI from ERC721. Constructs URI from baseTokenURI + CID + "/metadata.json"
     * @param tokenId Token ID to query
     * @return Complete URI for the token metadata
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return
            string.concat(baseTokenURI, tokenToCID[tokenId], "/metadata.json");
    }

    /**
     * @notice Burns a report NFT token
     * @dev Can only be called by ReportManager contract. Deletes the token and associated CID
     * @param tokenId Token ID to burn
     * @custom:emits ReportBurned
     */
    function burnReport(uint256 tokenId) public onlyReportManager {
        _burn(tokenId);
        delete tokenToCID[tokenId];

        emit ReportBurned(tokenId);
    }

    /**
     * @notice Returns the CID (Content Identifier) for a given token
     * @dev Public function to retrieve the IPFS CID of a report
     * @param tokenId Token ID to query
     * @return IPFS CID of the report
     */
    function getCID(uint256 tokenId) public view returns (string memory) {
        return tokenToCID[tokenId];
    }
}
