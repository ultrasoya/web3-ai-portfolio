// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ReportsManager} from "../../src/ReportsManager.sol";
import {VerifyEIP712} from "../../src/VerifyEIP712.sol";
import {IUserProfiles} from "../../src/interfaces/IUserProfiles.sol";
import {IReportNFT} from "../../src/interfaces/IReportNFT.sol";

contract MockUserProfiles is IUserProfiles {
    error NotImplemented();

    mapping(address => User) private _users;

    function setRegistered(address userAddress, bool isActive) external {
        _users[userAddress].isActive = isActive;
    }

    function registerUser(
        string memory,
        PreferredReportType,
        FocusArea
    ) external pure override {
        revert NotImplemented();
    }

    function getUser(
        address userAddress
    ) external view override returns (User memory) {
        return _users[userAddress];
    }

    function updatePreferredReportType(
        PreferredReportType
    ) external pure override {
        revert NotImplemented();
    }

    function updateNickname(string memory) external pure override {
        revert NotImplemented();
    }

    function updateFocusArea(FocusArea) external pure override {
        revert NotImplemented();
    }

    function updateLastReportId(
        address userAddress,
        uint lastReportId
    ) external override {
        _users[userAddress].lastReportId = lastReportId;
    }

    function checkUserRegisteredAndActive(
        address userAddress
    ) external view override returns (bool) {
        return _users[userAddress].isActive;
    }

    function deactivateUser(address userAddress) external override {
        _users[userAddress].isActive = false;
    }

    function activateUser(address userAddress) external override {
        _users[userAddress].isActive = true;
    }
}

contract MockReportNFT is IReportNFT {
    error NotImplemented();

    address private _reportManager;
    struct MintData {
        address mintOwner;
        uint256 tokenId;
        string cid;
    }

    MintData public lastMint;
    bool public wasMintCalled;

    function setReportManager(address newManager) external override {
        _reportManager = newManager;
    }

    function reportManager() external view override returns (address) {
        return _reportManager;
    }

    function mint(
        address mintOwner,
        uint256 tokenId,
        string calldata cid
    ) external override {
        wasMintCalled = true;
        lastMint = MintData(mintOwner, tokenId, cid);
    }

    function burnReport(uint256) external pure override {
        revert NotImplemented();
    }

    function setBaseURI(string calldata) external pure override {
        revert NotImplemented();
    }

    function tokenURI(uint256) external pure override returns (string memory) {
        revert NotImplemented();
    }

    function ownerOf(uint256) external pure override returns (address) {
        revert NotImplemented();
    }

    function getCID(uint256) external pure override returns (string memory) {
        revert NotImplemented();
    }
}

contract ReportsManagerTest is Test {
    ReportsManager private reportsManager;
    MockUserProfiles private userProfiles;
    MockReportNFT private reportNFT;
    VerifyEIP712 private verifyEIP712;

    address private backend;
    address private otherAccount;

    uint256 private ownerPrivateKey = 0xA11CE;
    address private reportOwner;

    function setUp() public {
        userProfiles = new MockUserProfiles();
        reportNFT = new MockReportNFT();
        verifyEIP712 = new VerifyEIP712();

        reportsManager = new ReportsManager(
            IUserProfiles(address(userProfiles)),
            IReportNFT(address(reportNFT)),
            verifyEIP712
        );

        reportNFT.setReportManager(address(reportsManager));

        backend = makeAddr("backend");
        otherAccount = makeAddr("stranger");
        reportOwner = vm.addr(ownerPrivateKey);
    }

    function _authorizeBackend(address account) internal {
        reportsManager.addAuthorizedBackend(account);
    }

    function _registerReportOwner() internal {
        userProfiles.setRegistered(reportOwner, true);
    }

    function testConstructorInitialState() public view {
        uint256 count = reportsManager.reportCount();
        assertEq(count, 1);
    }

    function testAddAuthorizedBackendOnlyOwner() public {
        reportsManager.addAuthorizedBackend(backend);
        assertTrue(reportsManager.authorizedBackends(backend));

        vm.prank(otherAccount);
        vm.expectRevert(ReportsManager.NotOwner.selector);
        reportsManager.addAuthorizedBackend(otherAccount);
    }

    function testRemoveAuthorizedBackend() public {
        reportsManager.addAuthorizedBackend(backend);
        assertTrue(reportsManager.authorizedBackends(backend));

        reportsManager.removeAuthorizedBackend(backend);
        assertFalse(reportsManager.authorizedBackends(backend));

        vm.prank(otherAccount);
        vm.expectRevert(ReportsManager.NotOwner.selector);
        reportsManager.removeAuthorizedBackend(backend);
    }

    function testCreateReportRequiresRegisteredUser() public {
        vm.expectRevert(ReportsManager.NotRegistered.selector);
        reportsManager.createReport(
            IUserProfiles.PreferredReportType.JSON,
            "cid",
            reportOwner
        );
    }

    function testCreateReportStoresDataAndUpdatesCounter() public {
        _registerReportOwner();

        vm.expectEmit(true, true, true, true);
        emit ReportsManager.ReportCreated(
            1,
            reportOwner,
            IUserProfiles.PreferredReportType.JSON,
            "cid"
        );

        reportsManager.createReport(
            IUserProfiles.PreferredReportType.JSON,
            "cid",
            reportOwner
        );

        (
            address ownerReport,
            uint64 createdAt,
            IUserProfiles.PreferredReportType reportType,
            string memory cid
        ) = reportsManager.reports(1);

        assertEq(ownerReport, reportOwner);
        assertEq(cid, "cid");
        assertEq(
            uint8(reportType),
            uint8(IUserProfiles.PreferredReportType.JSON)
        );
        assertEq(reportsManager.reportCount(), 2);
        assertEq(createdAt, uint64(block.timestamp));

        IUserProfiles.User memory user = userProfiles.getUser(reportOwner);
        assertEq(user.lastReportId, 1);
    }

    function testCreateReportMintsNftWhenPreferred() public {
        _registerReportOwner();

        reportsManager.createReport(
            IUserProfiles.PreferredReportType.NFT,
            "nft-cid",
            reportOwner
        );

        assertTrue(reportNFT.wasMintCalled());
        (address mintOwner, uint256 tokenId, string memory cid) = reportNFT
            .lastMint();
        assertEq(mintOwner, reportOwner);
        assertEq(tokenId, 1);
        assertEq(cid, "nft-cid");
    }

    function testCreateReportWithSignatureSuccess() public {
        _registerReportOwner();
        _authorizeBackend(backend);

        VerifyEIP712.Report memory report = VerifyEIP712.Report({
            ownerReport: reportOwner,
            createdAt: uint64(block.timestamp),
            reportType: uint8(IUserProfiles.PreferredReportType.NFT),
            cid: "signed-cid"
        });

        bytes32 digest = verifyEIP712.getTypedDataHash(report);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(backend);
        vm.expectEmit(true, true, true, true);
        emit ReportsManager.ReportCreated(
            1,
            reportOwner,
            IUserProfiles.PreferredReportType.NFT,
            "signed-cid"
        );
        reportsManager.createReportWithSignature(report, signature);

        assertTrue(reportNFT.wasMintCalled());
        assertEq(reportsManager.reportCount(), 2);
    }

    function testCreateReportWithSignatureInvalidSignatureReverts() public {
        _registerReportOwner();
        _authorizeBackend(backend);

        VerifyEIP712.Report memory report = VerifyEIP712.Report({
            ownerReport: reportOwner,
            createdAt: uint64(block.timestamp),
            reportType: uint8(IUserProfiles.PreferredReportType.JSON),
            cid: "cid"
        });

        bytes32 digest = verifyEIP712.getTypedDataHash(report);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xBEEF, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(backend);
        vm.expectRevert(ReportsManager.InvalidSignature.selector);
        reportsManager.createReportWithSignature(report, signature);
    }

    function testCreateReportWithSignatureUnauthorizedBackendReverts() public {
        _registerReportOwner();

        VerifyEIP712.Report memory report = VerifyEIP712.Report({
            ownerReport: reportOwner,
            createdAt: uint64(block.timestamp),
            reportType: uint8(IUserProfiles.PreferredReportType.JSON),
            cid: "cid"
        });

        bytes32 digest = verifyEIP712.getTypedDataHash(report);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(backend);
        vm.expectRevert(ReportsManager.NotAuthorizedBackend.selector);
        reportsManager.createReportWithSignature(report, signature);
    }

    function testCreateReportWithSignatureRequiresRegisteredUser() public {
        _authorizeBackend(backend);

        VerifyEIP712.Report memory report = VerifyEIP712.Report({
            ownerReport: reportOwner,
            createdAt: uint64(block.timestamp),
            reportType: uint8(IUserProfiles.PreferredReportType.JSON),
            cid: "cid"
        });

        bytes32 digest = verifyEIP712.getTypedDataHash(report);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(backend);
        vm.expectRevert(ReportsManager.NotRegistered.selector);
        reportsManager.createReportWithSignature(report, signature);
    }
}
