// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

interface IUserProfiles {
    struct User {
        string nickname;
        uint40 registrationDate;
        PreferredReportType preferredReportType;
        FocusArea focusArea;
        uint lastReportId;
        bool isActive;
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
    function checkUserRegisteredAndActive(
        address userAddress
    ) external view returns (bool);
    function deactivateUser(address userAddress) external;
    function activateUser(address userAddress) external;
}
