// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

interface IUserProfile {
    struct User {
        string nickname;
        uint64 registrationDate;
        PreferredReportType preferredReportType;
        FocusArea focusArea;
        uint lastReportId;
    }

    enum PreferredReportType {
        JSON,
        PDF,
        NFT
    }

    enum FocusArea {
        DeFi,
        NFT,
        Tokens,
        Portfolio
    }
    function registerUser(
        string memory nickname,
        PreferredReportType preferredReportType,
        FocusArea focusArea
    ) external;
    function getUser(address userAddress) external view returns (User memory);
    function updatePreferredReportType(
        PreferredReportType preferredReportType
    ) external;
    function updateNickname(string memory nickname) external;
    function updateFocusArea(FocusArea focusArea) external;
    function updateLastReportId(
        address userAddress,
        uint lastReportId
    ) external;
    function checkUserRegistered(
        address userAddress
    ) external view returns (bool);
}
