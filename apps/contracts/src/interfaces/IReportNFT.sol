// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

interface IReportNFT {
    event ReportMinted(
        address indexed mintOwner,
        uint256 indexed _tokenId,
        string _cid
    );
    event ReportBurned(uint256 indexed tokenId);
    event BaseURIUpdated(string newBaseTokenURI);

    error NotReportManager();
    error NotTokenOwner();
    error NotExistsToken();

    function mint(
        address mintOwner,
        uint256 tokenId,
        string calldata cid
    ) external;

    function burnReport(uint256 tokenId) external;

    function setBaseURI(string calldata newBaseTokenURI) external;

    function setReportManager(address newReportManager) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getCID(uint256 tokenId) external view returns (string memory);

    function reportManager() external view returns (address);
}
