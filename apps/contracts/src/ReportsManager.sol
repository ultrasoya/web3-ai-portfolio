// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {IUserProfiles} from "./interfaces/IUserProfiles.sol";
import {IReportNFT} from "./interfaces/IReportNFT.sol";
import {VerifyEIP712} from "./VerifyEIP712.sol";

/**
 * @title ReportsManager
 * @author Your Name
 * @notice This contract manages report creation and verification for the Web3 AI Portfolio platform
 * @dev Handles report creation with signature verification and NFT minting
 */
contract ReportsManager {
    /**
     * @notice Report structure containing all report information
     * @param ownerReport Address of the report owner
     * @param createdAt Unix timestamp when the report was created
     * @param reportType Type of the report (JSON, PDF, or NFT)
     * @param cid IPFS CID (Content Identifier) for the report content
     */
    struct Report {
        address ownerReport;
        uint64 createdAt;
        IUserProfiles.PreferredReportType reportType;
        string cid;
    }

    /// @notice Address of the user profiles contract
    IUserProfiles public s_userProfiles;

    /// @notice Address of the report NFT contract
    IReportNFT public s_reportNFT;

    /// @notice Address of the EIP-712 verification contract
    VerifyEIP712 immutable i_verifyEIP712;

    /// @notice Address of the contract owner
    address public immutable i_owner;

    /// @notice Mapping from report ID to report information
    mapping(uint256 reportId => Report) public reports;

    /// @notice Mapping from backend address to authorization status
    mapping(address => bool) public authorizedBackends;

    /// @notice Total number of reports created
    uint256 public reportCount = 1;

    /// @notice Flag to check if the contract is initialized
    bool private s_initialized = false;

    /**
     * @notice Emitted when a new report is created
     * @param reportId ID of the created report
     * @param ownerReport Address of the report owner
     * @param reportType Type of the created report
     * @param cid IPFS CID of the report content
     */
    event ReportCreated(
        uint256 indexed reportId,
        address ownerReport,
        IUserProfiles.PreferredReportType reportType,
        string cid
    );

    /**
     * @notice Emitted when the contract is initialized
     */
    event ContractInitialized();

    /// @notice Thrown when an operation requires registration but user is not registered
    error NotRegistered();

    /// @notice Thrown when a signature verification fails
    error InvalidSignature();

    /// @notice Thrown when a non-authorized backend tries to call an authorized backend-only function
    error NotAuthorizedBackend();

    /// @notice Thrown when a non-owner tries to call an owner-only function
    error NotOwner();

    /// @notice Thrown when the contract is already initialized
    error AlreadyInitialized();

    /// @notice Thrown when the user profiles or report NFT address is invalid
    error InvalidUserProfilesOrReportNFT();

    /**
     * @notice Modifier that ensures only the contract owner can call the function
     * @dev Reverts with NotOwner if the caller is not the owner
     */
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    /**
     * @notice Modifier that ensures only authorized backends can call the function
     * @dev Reverts with NotAuthorizedBackend if the caller is not authorized
     */
    modifier onlyAuthorizedBackend() {
        if (!authorizedBackends[msg.sender]) {
            revert NotAuthorizedBackend();
        }
        _;
    }

    /**
     * @notice Modifier that ensures only registered users can call the function
     * @param ownerReport Address of the user to check registration for
     * @dev Reverts with NotRegistered if the user is not registered
     */
    modifier onlyRegisteredUser(address ownerReport) {
        if (!s_userProfiles.checkUserRegisteredAndActive(ownerReport)) {
            revert NotRegistered();
        }
        _;
    }

    /**
     * @notice Constructor that initializes the contract with required dependencies
     * @param _userProfiles Address of the user profiles contract
     * @param _reportNFT Address of the report NFT contract
     * @param _verifyEIP712 Address of the EIP-712 verification contract
     * @dev Sets the deployer as the owner of the contract
     */
    constructor(
        IUserProfiles _userProfiles,
        IReportNFT _reportNFT,
        VerifyEIP712 _verifyEIP712
    ) {
        s_userProfiles = IUserProfiles(_userProfiles);
        s_reportNFT = IReportNFT(_reportNFT);
        i_verifyEIP712 = _verifyEIP712;
        i_owner = msg.sender;
    }

    /**
     * @notice Creates a new report with signature verification
     * @param report The report data to create
     * @param signature The EIP-712 signature to verify
     * @dev Only authorized backends can call this function
     * @dev Verifies the signature matches the report owner before creating the report
     * @dev Emits ReportCreated event upon successful creation
     */
    function createReportWithSignature(
        VerifyEIP712.Report calldata report,
        bytes calldata signature
    ) external onlyRegisteredUser(report.ownerReport) onlyAuthorizedBackend {
        if (!i_verifyEIP712.verify(report, signature, report.ownerReport)) {
            revert InvalidSignature();
        }

        createReport(
            IUserProfiles.PreferredReportType(report.reportType),
            report.cid,
            report.ownerReport
        );
    }

    /**
     * @notice Creates a new report without signature verification
     * @param reportType Type of the report to create (JSON, PDF, or NFT)
     * @param cid IPFS CID for the report content
     * @param ownerReport Address of the report owner
     * @dev Only registered users can have reports created for them
     * @dev Automatically mints an NFT if the report type is NFT
     * @dev Updates the user's last report ID
     * @dev Emits ReportCreated event upon successful creation
     */
    function createReport(
        IUserProfiles.PreferredReportType reportType,
        string calldata cid,
        address ownerReport
    ) public onlyRegisteredUser(ownerReport) {
        uint256 reportId = reportCount;
        reports[reportId] = Report(
            ownerReport,
            uint64(block.timestamp),
            reportType,
            cid
        );

        s_userProfiles.updateLastReportId(ownerReport, reportId);

        if (reportType == IUserProfiles.PreferredReportType.NFT) {
            s_reportNFT.mint(ownerReport, reportId, cid);
        }

        emit ReportCreated(reportId, ownerReport, reportType, cid);

        reportCount++;
    }

    /**
     * @notice Initializes the contract
     * @dev Only the contract owner can call this function
     */
    function initialize(
        IUserProfiles _userProfiles,
        IReportNFT _reportNFT
    ) external onlyOwner {
        if (s_initialized) {
            revert AlreadyInitialized();
        }
        if (
            address(_userProfiles) == address(0) ||
            address(_reportNFT) == address(0)
        ) {
            revert InvalidUserProfilesOrReportNFT();
        }
        s_userProfiles = _userProfiles;
        s_reportNFT = _reportNFT;
        s_initialized = true;

        emit ContractInitialized();
    }
    /**
     * @notice Adds a backend address to the list of authorized backends
     * @param backend Address of the backend to authorize
     * @dev Only the contract owner can call this function
     */
    function addAuthorizedBackend(address backend) external onlyOwner {
        authorizedBackends[backend] = true;
    }

    /**
     * @notice Removes a backend address from the list of authorized backends
     * @param backend Address of the backend to deauthorize
     * @dev Only the contract owner can call this function
     */
    function removeAuthorizedBackend(address backend) external onlyOwner {
        authorizedBackends[backend] = false;
    }
}
