// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

interface IReportNFT {
    function mint(address to, uint256 _tokenId, bytes32 _tokenURI) external;
    function tokenURI(uint256 _tokenId) external view returns (string memory);
    function ownerOf(uint256 _tokenId) external view returns (address);
}
