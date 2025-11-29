// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ReportNFT} from "../../src/ReportNFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ReportNFTHarness is ReportNFT {
    mapping(uint256 => bool) private _forceNonexistent;

    constructor(
        address _reportManager,
        string memory _baseTokenURI
    ) ReportNFT(_reportManager, _baseTokenURI) {}

    function checkOnlyTokenOwner(
        uint256 tokenId
    ) external onlyTokenOwner(tokenId) {}

    function checkOnlyExistsToken(
        uint256 tokenId
    ) external onlyExistsToken(tokenId) {}

    function setForceNonexistent(uint256 tokenId, bool value) external {
        _forceNonexistent[tokenId] = value;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (_forceNonexistent[tokenId]) {
            return address(0);
        }

        return super.ownerOf(tokenId);
    }
}

contract ReportNFTTest is Test {
    ReportNFTHarness private reportNFT;
    address private reportManager;
    address private newReportManager;
    address private user;

    string private constant INITIAL_BASE_URI = "ipfs://";
    string private constant CID = "bafybeigdyrzt5n2";

    function setUp() public {
        reportManager = makeAddr("reportManager");
        newReportManager = makeAddr("newReportManager");
        user = makeAddr("user");

        reportNFT = new ReportNFTHarness(reportManager, INITIAL_BASE_URI);
    }

    function testConstructorSetsState() public view {
        assertEq(reportNFT.reportManager(), reportManager);
    }

    function testMintByReportManager() public {
        vm.prank(reportManager);
        vm.expectEmit(true, true, true, true);
        emit ReportNFT.ReportMinted(user, 1, CID);
        reportNFT.mint(user, 1, CID);

        assertEq(reportNFT.ownerOf(1), user);
        assertEq(reportNFT.getCID(1), CID);
        assertEq(
            reportNFT.tokenURI(1),
            string.concat(INITIAL_BASE_URI, CID, "/metadata.json")
        );
    }

    function testMintNotReportManagerReverts() public {
        vm.expectRevert(ReportNFT.NotReportManager.selector);
        reportNFT.mint(user, 1, CID);
    }

    function testSetBaseURIByReportManager() public {
        string memory newBaseURI = "https://example.com/";

        vm.prank(reportManager);
        vm.expectEmit(true, true, true, true);
        emit ReportNFT.BaseURIUpdated(newBaseURI);
        reportNFT.setBaseURI(newBaseURI);

        vm.prank(reportManager);
        reportNFT.mint(user, 1, CID);

        assertEq(
            reportNFT.tokenURI(1),
            string.concat(newBaseURI, CID, "/metadata.json")
        );
    }

    function testSetBaseURIUnauthorizedReverts() public {
        vm.expectRevert(ReportNFT.NotReportManager.selector);
        reportNFT.setBaseURI("https://malicious.com/");
    }

    function testSetReportManagerByOwner() public {
        reportNFT.setReportManager(newReportManager);
        assertEq(reportNFT.reportManager(), newReportManager);

        vm.prank(newReportManager);
        reportNFT.mint(user, 1, CID);

        assertEq(reportNFT.ownerOf(1), user);
    }

    function testSetReportManagerByNonOwnerReverts() public {
        address stranger = makeAddr("stranger");

        vm.prank(stranger);
        vm.expectRevert();
        reportNFT.setReportManager(newReportManager);

        assertEq(reportNFT.reportManager(), reportManager);
    }

    function testBurnReport() public {
        vm.prank(reportManager);
        reportNFT.mint(user, 1, CID);

        vm.prank(reportManager);
        vm.expectEmit(true, true, true, true);
        emit ReportNFT.ReportBurned(1);
        reportNFT.burnReport(1);

        vm.expectRevert();
        reportNFT.ownerOf(1);
        assertEq(reportNFT.getCID(1), "");
    }

    function testBurnReportUnauthorizedReverts() public {
        vm.prank(reportManager);
        reportNFT.mint(user, 1, CID);

        vm.expectRevert(ReportNFT.NotReportManager.selector);
        reportNFT.burnReport(1);
    }

    function testOnlyTokenOwnerAllowsOwner() public {
        vm.prank(reportManager);
        reportNFT.mint(user, 1, CID);

        vm.prank(user);
        reportNFT.checkOnlyTokenOwner(1);
    }

    function testOnlyTokenOwnerNonOwnerReverts() public {
        vm.prank(reportManager);
        reportNFT.mint(user, 1, CID);

        address stranger = makeAddr("stranger");
        vm.prank(stranger);
        vm.expectRevert(ReportNFT.NotTokenOwner.selector);
        reportNFT.checkOnlyTokenOwner(1);
    }

    function testOnlyExistsTokenPassesForExistingToken() public {
        vm.prank(reportManager);
        reportNFT.mint(user, 1, CID);

        reportNFT.checkOnlyExistsToken(1);
    }

    function testOnlyExistsTokenRevertsForMissingToken() public {
        reportNFT.setForceNonexistent(1, true);

        vm.expectRevert(ReportNFT.NotExistsToken.selector);
        reportNFT.checkOnlyExistsToken(1);
    }
}
