// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {IUserProfile} from "./interfaces/IUserProfile.sol";
import {IReportNFT} from "./interfaces/IReportNFT.sol";

contract ReportManager {
    struct Report {
        address ownerReport;
        uint64 createdAt;
        IUserProfile.PreferredReportType reportType;
        bytes32 ipfsHash;
    }

    IUserProfile immutable userProfile;
    IReportNFT immutable reportNFT;
    address public owner;
    mapping(uint256 reportId => Report) public reports;
    mapping(address => bool) public authorizedBackends;
    uint256 public reportCount;

    event ReportCreated(
        address ownerReport,
        uint256 indexed reportId,
        IUserProfile.PreferredReportType reportType,
        bytes32 ipfsHash
    );

    error NotReportOwnerOrOwner();
    error NotRegistered();

    modifier onlyReportOwnerOrOwner(uint256 reportId) {
        if (
            reports[reportId].ownerReport != msg.sender && msg.sender != owner
        ) {
            revert NotReportOwnerOrOwner();
        }
        _;
    }

    modifier onlyRegisteredUser(address ownerReport) {
        if (!userProfile.checkUserRegistered(ownerReport)) {
            revert NotRegistered();
        }
        _;
    }

    constructor(IUserProfile _userProfile, IReportNFT _reportNFT) {
        userProfile = IUserProfile(_userProfile);
        reportNFT = IReportNFT(_reportNFT);
        owner = msg.sender;
    }

    function createReport(
        IUserProfile.PreferredReportType reportType,
        bytes32 ipfsHash,
        address ownerReport
    ) external onlyRegisteredUser(ownerReport) {
        uint256 reportId = reportCount;
        reports[reportId] = Report(
            ownerReport,
            uint64(block.timestamp),
            reportType,
            ipfsHash
        );

        userProfile.updateLastReportId(ownerReport, reportId);

        if (reportType == IUserProfile.PreferredReportType.NFT) {
            reportNFT.mint(ownerReport, reportId, ipfsHash);
        }

        emit ReportCreated(ownerReport, reportId, reportType, ipfsHash);

        reportCount++;
    }
}
