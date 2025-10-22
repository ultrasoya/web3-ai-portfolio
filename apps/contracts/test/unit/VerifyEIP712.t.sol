// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {VerifyEIP712} from "../../src/VerifyEIP712.sol";

contract VerifyEIP712Test is Test {
    address public USER;
    uint256 public USER_PRIVATE_KEY;
    address public ATTACKER;
    uint256 public ATTACKER_PRIVATE_KEY;
    VerifyEIP712 public verifyEIP712;

    struct Report {
        address ownerReport;
        uint64 createdAt;
        uint8 reportType;
        string cid;
    }

    function setUp() public {
        verifyEIP712 = new VerifyEIP712();
        (USER, USER_PRIVATE_KEY) = makeAddrAndKey("user");
        (ATTACKER, ATTACKER_PRIVATE_KEY) = makeAddrAndKey("attacker");
    }

    function testValidSignature() public view {
        VerifyEIP712.Report memory report = VerifyEIP712.Report({
            ownerReport: USER,
            createdAt: uint64(block.timestamp),
            reportType: 0,
            cid: "ipfs://bafkreig4567890123456789012345678901234567890123456789012345678901234567"
        });

        bytes32 digest = verifyEIP712.getTypedDataHash(report);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(USER_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        bool isValid = verifyEIP712.verify(report, signature, USER);
        assertTrue(isValid);
    }

    function testInvalidSignature_WrongSigner() public view {
        VerifyEIP712.Report memory report = VerifyEIP712.Report({
            ownerReport: USER,
            createdAt: uint64(block.timestamp),
            reportType: 0,
            cid: "ipfs://bafkreig4567890123456789012345678901234567890123456789012345678901234567"
        });
        bytes32 digest = verifyEIP712.getTypedDataHash(report);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(USER_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        bool isValid = verifyEIP712.verify(report, signature, ATTACKER);
        assertFalse(isValid);
    }

    function testInvalidSignature_ModifiedData() public view {
        VerifyEIP712.Report memory report = VerifyEIP712.Report({
            ownerReport: USER,
            createdAt: uint64(block.timestamp),
            reportType: 0,
            cid: "ipfs://bafkreig4567890123456789012345678901234567890123456789012345678901234567"
        });
        bytes32 digest = verifyEIP712.getTypedDataHash(report);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(USER_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        report
            .cid = "ipfs://bafkreig4567890123456789012345678901234567890123456789012345678901234568";

        bool isValid = verifyEIP712.verify(report, signature, USER);
        assertFalse(isValid);
    }

    function testInvalidSignature_WrongKey() public view {
        VerifyEIP712.Report memory report = VerifyEIP712.Report({
            ownerReport: USER,
            createdAt: uint64(block.timestamp),
            reportType: 0,
            cid: "ipfs://bafkreig4567890123456789012345678901234567890123456789012345678901234567"
        });
        bytes32 digest = verifyEIP712.getTypedDataHash(report);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ATTACKER_PRIVATE_KEY, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        bool isValid = verifyEIP712.verify(report, signature, USER);
        assertFalse(isValid);
    }

    function testEmptyCid() public {
        VerifyEIP712.Report memory report = VerifyEIP712.Report({
            ownerReport: USER,
            createdAt: uint64(block.timestamp),
            reportType: 0,
            cid: ""
        });

        vm.expectRevert(VerifyEIP712.EmptyCid.selector);
        verifyEIP712.getTypedDataHash(report);
    }
}
