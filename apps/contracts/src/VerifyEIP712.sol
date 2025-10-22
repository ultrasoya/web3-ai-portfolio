// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IUserProfiles} from "./interfaces/IUserProfiles.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract VerifyEIP712 is EIP712 {
    using ECDSA for bytes32;

    struct Report {
        address ownerReport;
        uint64 createdAt;
        uint8 reportType;
        string cid;
    }

    bytes32 private constant _REPORT_TYPEHASH =
        keccak256(
            "Report(address ownerReport,uint64 createdAt,uint8 reportType,string cid)"
        );

    constructor() EIP712("ReportCreator", "1") {}

    error EmptyCid();

    modifier notEmptyCid(string memory cid) {
        if (bytes(cid).length == 0) {
            revert EmptyCid();
        }
        _;
    }

    function _hashReport(
        Report calldata report
    ) internal view notEmptyCid(report.cid) returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _REPORT_TYPEHASH,
                    report.ownerReport,
                    report.createdAt,
                    uint8(report.reportType),
                    keccak256(bytes(report.cid))
                )
            );
    }

    function getTypedDataHash(
        Report calldata report
    ) external view returns (bytes32) {
        return _hashTypedDataV4(_hashReport(report));
    }

    function verify(
        Report calldata report,
        bytes calldata signature,
        address expectedSigner
    ) external view returns (bool) {
        // digest по EIP-712
        bytes32 digest = _hashTypedDataV4(_hashReport(report));
        // восстанавливаем адрес подписанта
        address signer = ECDSA.recover(digest, signature);
        return signer == expectedSigner;
    }
}
