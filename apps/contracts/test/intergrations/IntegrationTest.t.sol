// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {UserProfiles} from "../../src/UserProfiles.sol";
import {ReportsManager} from "../../src/ReportsManager.sol";
import {ReportNFT} from "../../src/ReportNFT.sol";
import {VerifyEIP712} from "../../src/VerifyEIP712.sol";
import {IUserProfiles} from "../../src/interfaces/IUserProfiles.sol";

/**
 * @title IntegrationTest
 * @notice Integration tests for the Web3 AI Portfolio platform
 * @dev Tests the full flow of user registration, report creation, and NFT minting
 *      using deployed contracts on Sepolia (or fork)
 */
contract IntegrationTest is Test {
    // Deployed contract addresses on Sepolia
    address constant SEPOLIA_USER_PROFILES =
        0x2E18db242466875C57CB74395d7fFf263193eBD8;
    address constant SEPOLIA_REPORTS_MANAGER =
        0xb579c9d2F2733cf214e39543D938B2fd59c1853D;
    address constant SEPOLIA_VERIFY_EIP712 =
        0xFf97F4C4C43edffbbCE0A79d98e27f01512CBE68;
    address constant SEPOLIA_REPORT_NFT =
        0xbb0b1F447962fbEC49A76070068A85A35a5DC371;

    UserProfiles public userProfiles;
    ReportsManager public reportsManager;
    ReportNFT public reportNFT;
    VerifyEIP712 public verifyEIP712;

    address public user;
    address public backend;
    address public owner;

    uint256 private userPrivateKey = 0xA11CE;
    uint256 private backendPrivateKey = 0xBEEF;

    function setUp() public {
        // Option 1: Use fork of Sepolia (uncomment if you want to fork)
        // string memory sepoliaRpcUrl = vm.envString("SEPOLIA_RPC_URL");
        // vm.createSelectFork(sepoliaRpcUrl);

        // Option 2: Use deployed contracts directly (current approach)
        userProfiles = UserProfiles(SEPOLIA_USER_PROFILES);
        reportsManager = ReportsManager(SEPOLIA_REPORTS_MANAGER);
        reportNFT = ReportNFT(SEPOLIA_REPORT_NFT);
        verifyEIP712 = VerifyEIP712(SEPOLIA_VERIFY_EIP712);

        user = vm.addr(userPrivateKey);
        backend = vm.addr(backendPrivateKey);
        owner = reportsManager.i_owner();

        // Fund test accounts if using fork
        // vm.deal(user, 1 ether);
        // vm.deal(backend, 1 ether);
    }

    /**
     * @notice Test full flow: register user -> create report -> mint NFT
     */
    function testFullFlow_RegisterUser_CreateReport_MintNFT() public {
        // Step 1: Register user
        vm.startPrank(user);
        userProfiles.registerUser(
            "TestUser",
            UserProfiles.PreferredReportType.NFT,
            UserProfiles.FocusArea.Portfolio
        );
        vm.stopPrank();

        // Verify registration
        UserProfiles.User memory userData = userProfiles.getUser(user);
        assertEq(userData.nickname, "TestUser");
        assertTrue(userData.isActive);
        assertEq(
            uint8(userData.preferredReportType),
            uint8(UserProfiles.PreferredReportType.NFT)
        );

        // Step 2: Authorize backend (only owner can do this)
        vm.startPrank(owner);
        reportsManager.addAuthorizedBackend(backend);
        vm.stopPrank();

        // Step 3: Create report (should mint NFT because preferredReportType is NFT)
        string memory testCid = "QmTest123";
        vm.startPrank(backend);
        reportsManager.createReport(
            IUserProfiles.PreferredReportType.NFT,
            testCid,
            user
        );
        vm.stopPrank();

        // Verify report was created
        (
            address reportOwner,
            ,
            IUserProfiles.PreferredReportType reportType,
            string memory cid
        ) = reportsManager.reports(1);

        assertEq(reportOwner, user);
        assertEq(cid, testCid);
        assertEq(
            uint8(reportType),
            uint8(IUserProfiles.PreferredReportType.NFT)
        );
        assertEq(reportsManager.reportCount(), 2);

        // Verify NFT was minted
        address nftOwner = reportNFT.ownerOf(1);
        assertEq(nftOwner, user);

        // Verify user's lastReportId was updated
        userData = userProfiles.getUser(user);
        assertEq(userData.lastReportId, 1);

        // Verify NFT metadata
        string memory tokenURI = reportNFT.tokenURI(1);
        assertTrue(bytes(tokenURI).length > 0);
    }

    /**
     * @notice Test creating report with signature verification
     */
    function testCreateReportWithSignature() public {
        // Register user
        vm.startPrank(user);
        userProfiles.registerUser(
            "SignedUser",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

        // Authorize backend
        vm.startPrank(owner);
        reportsManager.addAuthorizedBackend(backend);
        vm.stopPrank();

        // Create report data
        VerifyEIP712.Report memory report = VerifyEIP712.Report({
            ownerReport: user,
            createdAt: uint64(block.timestamp),
            reportType: uint8(UserProfiles.PreferredReportType.PDF),
            cid: "QmSignedReport"
        });

        // Sign the report
        bytes32 digest = verifyEIP712.getTypedDataHash(report);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Create report with signature
        vm.startPrank(backend);
        reportsManager.createReportWithSignature(report, signature);
        vm.stopPrank();

        // Verify report was created
        (address reportOwner, , , string memory cid) = reportsManager.reports(
            1
        );
        assertEq(reportOwner, user);
        assertEq(cid, "QmSignedReport");
    }

    /**
     * @notice Test that non-NFT reports don't mint NFTs
     */
    function testNonNFTReport_DoesNotMintNFT() public {
        // Register user with JSON preference
        vm.startPrank(user);
        userProfiles.registerUser(
            "JSONUser",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.Tokens
        );
        vm.stopPrank();

        // Authorize backend
        vm.startPrank(owner);
        reportsManager.addAuthorizedBackend(backend);
        vm.stopPrank();

        // Create JSON report
        vm.startPrank(backend);
        reportsManager.createReport(
            IUserProfiles.PreferredReportType.JSON,
            "QmJSONReport",
            user
        );
        vm.stopPrank();

        // Verify report exists
        assertEq(reportsManager.reportCount(), 2);

        // Verify NFT was NOT minted (should revert on ownerOf for non-existent token)
        vm.expectRevert();
        reportNFT.ownerOf(1);
    }

    /**
     * @notice Test multiple reports for same user
     */
    function testMultipleReportsForSameUser() public {
        // Register user
        vm.startPrank(user);
        userProfiles.registerUser(
            "MultiReportUser",
            UserProfiles.PreferredReportType.NFT,
            UserProfiles.FocusArea.Portfolio
        );
        vm.stopPrank();

        // Authorize backend
        vm.startPrank(owner);
        reportsManager.addAuthorizedBackend(backend);
        vm.stopPrank();

        // Create multiple reports
        vm.startPrank(backend);
        reportsManager.createReport(
            IUserProfiles.PreferredReportType.NFT,
            "QmReport1",
            user
        );
        reportsManager.createReport(
            IUserProfiles.PreferredReportType.NFT,
            "QmReport2",
            user
        );
        reportsManager.createReport(
            IUserProfiles.PreferredReportType.NFT,
            "QmReport3",
            user
        );
        vm.stopPrank();

        // Verify all reports exist
        assertEq(reportsManager.reportCount(), 4);

        // Verify all NFTs were minted
        assertEq(reportNFT.ownerOf(1), user);
        assertEq(reportNFT.ownerOf(2), user);
        assertEq(reportNFT.ownerOf(3), user);

        // Verify lastReportId is updated to latest
        UserProfiles.User memory userData = userProfiles.getUser(user);
        assertEq(userData.lastReportId, 3);
    }

    /**
     * @notice Test that unauthorized backend cannot create reports
     */
    function testUnauthorizedBackend_CannotCreateReport() public {
        // Register user
        vm.startPrank(user);
        userProfiles.registerUser(
            "ProtectedUser",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

        // Try to create report without authorization
        vm.startPrank(backend);
        vm.expectRevert(ReportsManager.NotAuthorizedBackend.selector);
        reportsManager.createReportWithSignature(
            VerifyEIP712.Report({
                ownerReport: user,
                createdAt: uint64(block.timestamp),
                reportType: uint8(UserProfiles.PreferredReportType.JSON),
                cid: "QmTest"
            }),
            ""
        );
        vm.stopPrank();
    }

    /**
     * @notice Test that unregistered user cannot have reports created
     */
    function testUnregisteredUser_CannotHaveReports() public {
        // Authorize backend
        vm.startPrank(owner);
        reportsManager.addAuthorizedBackend(backend);
        vm.stopPrank();

        // Try to create report for unregistered user
        vm.startPrank(backend);
        vm.expectRevert(ReportsManager.NotRegistered.selector);
        reportsManager.createReport(
            IUserProfiles.PreferredReportType.JSON,
            "QmTest",
            user
        );
        vm.stopPrank();
    }

    /**
     * @notice Test user profile updates affect report creation
     */
    function testUserProfileUpdate_AffectsReportCreation() public {
        // Register user with JSON preference
        vm.startPrank(user);
        userProfiles.registerUser(
            "UpdateUser",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

        // Change preference to NFT
        vm.startPrank(user);
        userProfiles.updatePreferredReportType(
            UserProfiles.PreferredReportType.NFT
        );
        vm.stopPrank();

        // Authorize backend
        vm.startPrank(owner);
        reportsManager.addAuthorizedBackend(backend);
        vm.stopPrank();

        // Create report with NFT type (user's new preference)
        vm.startPrank(backend);
        reportsManager.createReport(
            IUserProfiles.PreferredReportType.NFT,
            "QmUpdatedPreference",
            user
        );
        vm.stopPrank();

        // Verify NFT was minted
        assertEq(reportNFT.ownerOf(1), user);
    }

    /**
     * @notice Test that deactivated user cannot have reports created
     */
    function testDeactivatedUser_CannotHaveReports() public {
        // Register user
        vm.startPrank(user);
        userProfiles.registerUser(
            "DeactivatedUser",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

        // Deactivate user
        vm.startPrank(user);
        userProfiles.deactivateUser(user);
        vm.stopPrank();

        // Authorize backend
        vm.startPrank(owner);
        reportsManager.addAuthorizedBackend(backend);
        vm.stopPrank();

        // Try to create report for deactivated user
        vm.startPrank(backend);
        vm.expectRevert(ReportsManager.NotRegistered.selector);
        reportsManager.createReport(
            IUserProfiles.PreferredReportType.JSON,
            "QmTest",
            user
        );
        vm.stopPrank();
    }

    /**
     * @notice Test NFT tokenURI format
     */
    function testNFTTokenURI_Format() public {
        // Register user
        vm.startPrank(user);
        userProfiles.registerUser(
            "NFTUser",
            UserProfiles.PreferredReportType.NFT,
            UserProfiles.FocusArea.NFT
        );
        vm.stopPrank();

        // Authorize backend
        vm.startPrank(owner);
        reportsManager.addAuthorizedBackend(backend);
        vm.stopPrank();

        // Create NFT report
        string memory testCid = "QmTestCID123";
        vm.startPrank(backend);
        reportsManager.createReport(
            IUserProfiles.PreferredReportType.NFT,
            testCid,
            user
        );
        vm.stopPrank();

        // Verify tokenURI format
        string memory tokenURI = reportNFT.tokenURI(1);
        assertTrue(bytes(tokenURI).length > 0);
        // Should contain the CID
        assertTrue(
            keccak256(bytes(tokenURI)) ==
                keccak256(
                    bytes(string.concat("ipfs://", testCid, "/metadata.json"))
                )
        );
    }
}
