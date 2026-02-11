// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {UserProfiles} from "../src/UserProfiles.sol";
import {ReportsManager} from "../src/ReportsManager.sol";
import {VerifyEIP712} from "../src/VerifyEIP712.sol";
import {ReportNFT} from "../src/ReportNFT.sol";
import {IUserProfiles} from "../src/interfaces/IUserProfiles.sol";
import {IReportNFT} from "../src/interfaces/IReportNFT.sol";

contract DeployContracts is Script {
    function run()
        external
        returns (
            address userProfiles,
            address reportsManager,
            address verifyEIP712,
            address reportNFT
        )
    {
        vm.startBroadcast();

        VerifyEIP712 verifyEIP712 = new VerifyEIP712();
        ReportsManager reportsManager = new ReportsManager(
            IUserProfiles(address(0)),
            IReportNFT(address(0)),
            verifyEIP712
        );
        UserProfiles userProfiles = new UserProfiles(address(reportsManager));
        ReportNFT reportNFT = new ReportNFT(address(reportsManager), "ipfs://");

        reportsManager.initialize(
            IUserProfiles(address(userProfiles)),
            IReportNFT(address(reportNFT))
        );

        vm.stopBroadcast();

        console.log("UserProfiles deployed to:", address(userProfiles));
        console.log("ReportsManager deployed to:", address(reportsManager));
        console.log("VerifyEIP712 deployed to:", address(verifyEIP712));
        console.log("ReportNFT deployed to:", address(reportNFT));

        return (
            address(userProfiles),
            address(reportsManager),
            address(verifyEIP712),
            address(reportNFT)
        );
    }
}
