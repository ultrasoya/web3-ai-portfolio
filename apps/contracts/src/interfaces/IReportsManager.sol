// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {IUserProfiles} from "./IUserProfiles.sol";
import {VerifyEIP712} from "../VerifyEIP712.sol";

/**
 * @title IReportsManager
 * @notice Interface for the ReportsManager contract
 * @dev Defines the structure and methods for managing reports in the Web3 AI Portfolio platform
 */
interface IReportsManager {
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

    /// @notice Thrown when an operation requires registration but user is not registered
    error NotRegistered();

    /// @notice Thrown when a signature verification fails
    error InvalidSignature();

    /// @notice Thrown when a non-authorized backend tries to call an authorized backend-only function
    error NotAuthorizedBackend();

    /// @notice Thrown when a non-owner tries to call an owner-only function
    error NotOwner();

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
    ) external;

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
    ) external;

    /**
     * @notice Adds a backend address to the list of authorized backends
     * @param backend Address of the backend to authorize
     * @dev Only the contract owner can call this function
     */
    function addAuthorizedBackend(address backend) external;

    /**
     * @notice Removes a backend address from the list of authorized backends
     * @param backend Address of the backend to deauthorize
     * @dev Only the contract owner can call this function
     */
    function removeAuthorizedBackend(address backend) external;

    /**
     * @notice Returns the report information for a given report ID
     * @param reportId ID of the report to query
     * @return Report structure containing report information
     */
    function reports(uint256 reportId) external view returns (Report memory);

    /**
     * @notice Checks if a backend address is authorized
     * @param backend Address of the backend to check
     * @return bool True if the backend is authorized, false otherwise
     */
    function authorizedBackends(address backend) external view returns (bool);

    /**
     * @notice Returns the total number of reports created
     * @return uint256 Total count of reports
     */
    function reportCount() external view returns (uint256);

    /**
     * @notice Returns the address of the contract owner
     * @return address Address of the owner
     */
    function i_owner() external view returns (address);
}
