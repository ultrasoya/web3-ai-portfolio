// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {IUserProfile} from "./interfaces/IUserProfile.sol";
import {IReportNFT} from "./interfaces/IReportNFT.sol";
import {VerifyEIP712} from "./VerifyEIP712.sol";
import {Structs} from "./shared/Structs.sol";

contract ReportManager {
    struct Report {
        address ownerReport;
        uint64 createdAt;
        IUserProfile.PreferredReportType reportType;
        Structs.IpfsCID ipfsHash;
    }

    IUserProfile immutable i_userProfile;
    IReportNFT immutable i_reportNFT;
    VerifyEIP712 immutable i_verifyEIP712;
    address public immutable i_owner;
    mapping(uint256 reportId => Report) public reports;
    mapping(address => bool) public authorizedBackends;
    uint256 public reportCount;

    event ReportCreated(
        address ownerReport,
        uint256 indexed reportId,
        IUserProfile.PreferredReportType reportType,
        Structs.IpfsCID ipfsHash
    );

    error NotRegistered();
    error InvalidSignature();
    error NotAuthorizedBackend();
    error NotOwner();

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyAuthorizedBackend() {
        if (!authorizedBackends[msg.sender]) {
            revert NotAuthorizedBackend();
        }
        _;
    }

    modifier onlyRegisteredUser(address ownerReport) {
        if (!i_userProfile.checkUserRegistered(ownerReport)) {
            revert NotRegistered();
        }
        _;
    }

    constructor(
        IUserProfile _userProfile,
        IReportNFT _reportNFT,
        VerifyEIP712 _verifyEIP712
    ) {
        i_userProfile = IUserProfile(_userProfile);
        i_reportNFT = IReportNFT(_reportNFT);
        i_verifyEIP712 = _verifyEIP712;
        i_owner = msg.sender;
    }

    function createReportWithSignature(
        VerifyEIP712.Report calldata report,
        bytes calldata signature
    ) external onlyRegisteredUser(report.ownerReport) onlyAuthorizedBackend {
        if (!i_verifyEIP712.verify(report, signature, report.ownerReport)) {
            revert InvalidSignature();
        }

        createReport(
            IUserProfile.PreferredReportType(report.reportType),
            report.ipfsHash,
            report.ownerReport
        );
    }

    function createReport(
        IUserProfile.PreferredReportType reportType,
        Structs.IpfsCID calldata ipfsHash,
        address ownerReport
    ) public onlyRegisteredUser(ownerReport) {
        uint256 reportId = reportCount;
        reports[reportId] = Report(
            ownerReport,
            uint64(block.timestamp),
            reportType,
            ipfsHash
        );

        i_userProfile.updateLastReportId(ownerReport, reportId);

        if (reportType == IUserProfile.PreferredReportType.NFT) {
            i_reportNFT.mint(ownerReport, reportId, ipfsHash.hashDigest);
        }

        emit ReportCreated(ownerReport, reportId, reportType, ipfsHash);

        reportCount++;
    }

    function addAuthorizedBackend(address backend) external onlyOwner {
        authorizedBackends[backend] = true;
    }

    function removeAuthorizedBackend(address backend) external onlyOwner {
        authorizedBackends[backend] = false;
    }
}
