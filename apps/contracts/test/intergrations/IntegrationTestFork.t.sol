// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {UserProfiles} from "../../src/UserProfiles.sol";
import {ReportsManager} from "../../src/ReportsManager.sol";
import {ReportNFT} from "../../src/ReportNFT.sol";
import {VerifyEIP712} from "../../src/VerifyEIP712.sol";
import {IUserProfiles} from "../../src/interfaces/IUserProfiles.sol";

/**
 * @title IntegrationTestFork
 * @notice Integration tests using Sepolia fork
 * @dev Tests the full flow using a fork of Sepolia network
 *      This allows testing against real deployed contracts without spending gas
 */
contract IntegrationTestFork is Test {
    // Deployed contract addresses on Sepolia
    address constant SEPOLIA_USER_PROFILES = 0x2E18db242466875C57CB74395d7fFf263193eBD8;
    address constant SEPOLIA_REPORTS_MANAGER = 0xb579c9d2F2733cf214e39543D938B2fd59c1853D;
    address constant SEPOLIA_VERIFY_EIP712 = 0xFf97F4C4C43edffbbCE0A79d98e27f01512CBE68;
    address constant SEPOLIA_REPORT_NFT = 0xbb0b1F447962fbEC49A76070068A85A35a5DC371;

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
        // Fork Sepolia network
        string memory sepoliaRpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(sepoliaRpcUrl);

        // Connect to deployed contracts
        userProfiles = UserProfiles(SEPOLIA_USER_PROFILES);
        reportsManager = ReportsManager(SEPOLIA_REPORTS_MANAGER);
        reportNFT = ReportNFT(SEPOLIA_REPORT_NFT);
        verifyEIP712 = VerifyEIP712(SEPOLIA_VERIFY_EIP712);

        user = vm.addr(userPrivateKey);
        backend = vm.addr(backendPrivateKey);
        owner = reportsManager.i_owner();

        // Fund test accounts
        vm.deal(user, 1 ether);
        vm.deal(backend, 1 ether);
    }

    /**
     * @notice Test full flow on forked Sepolia
     */
    function testFork_FullFlow() public {
        // Register user
        vm.startPrank(user);
        userProfiles.registerUser(
            "ForkUser",
            IUserProfiles.PreferredReportType.NFT,
            IUserProfiles.FocusArea.Portfolio
        );
        vm.stopPrank();

        // Verify registration
        IUserProfiles.User memory userData = userProfiles.getUser(user);
        assertEq(userData.nickname, "ForkUser");
        assertTrue(userData.isActive);

        // Authorize backend
        vm.startPrank(owner);
        reportsManager.addAuthorizedBackend(backend);
        vm.stopPrank();

        // Create report
        string memory testCid = "QmForkTest123";
        vm.startPrank(backend);
        reportsManager.createReport(
            IUserProfiles.PreferredReportType.NFT,
            testCid,
            user
        );
        vm.stopPrank();

        // Verify report and NFT
        (
            address reportOwner,
            ,
            ,
            string memory cid
        ) = reportsManager.reports(1);
        assertEq(reportOwner, user);
        assertEq(cid, testCid);

        // Verify NFT was minted
        address nftOwner = reportNFT.ownerOf(1);
        assertEq(nftOwner, user);
    }

    /**
     * @notice Test that we can read existing state from forked network
     */
    function testFork_ReadExistingState() public view {
        // These tests verify that we can read from the forked network
        // Check that contracts are deployed
        assertNotEq(address(userProfiles), address(0));
        assertNotEq(address(reportsManager), address(0));
        assertNotEq(address(reportNFT), address(0));
        assertNotEq(address(verifyEIP712), address(0));

        // Check owner
        assertNotEq(owner, address(0));
    }
}

