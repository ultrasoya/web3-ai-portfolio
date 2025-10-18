// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Structs} from "../shared/Structs.sol";
interface IReportNFT {
    function mint(
        address to,
        uint256 tokenId,
        Structs.IpfsCID calldata ipfsCID
    ) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getIpfsCID(
        uint256 tokenId
    ) external view returns (Structs.IpfsCID memory);
}
