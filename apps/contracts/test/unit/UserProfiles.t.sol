// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {UserProfiles} from "../../src/UserProfiles.sol";
import {ReportsManager} from "../../src/ReportsManager.sol";
import {IUserProfiles} from "../../src/interfaces/IUserProfiles.sol";

contract UserProfilesTest is Test {
    UserProfiles public userProfiles;
    address public reportsManager;
    address public user;
    address public reportManager;

    function setUp() public {
        reportsManager = makeAddr("reportManager");
        userProfiles = new UserProfiles(reportsManager);
        user = makeAddr("user");
        reportManager = makeAddr("reportManager");
    }

    function _registerUser(
        address userAddress,
        string memory nickname,
        UserProfiles.PreferredReportType preferredReportType,
        UserProfiles.FocusArea focusArea
    ) internal {
        vm.startPrank(userAddress);
        userProfiles.registerUser(nickname, preferredReportType, focusArea);
        vm.stopPrank();
    }

    function _registerUser(address userAddress) internal {
        _registerUser(
            userAddress,
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
    }

    function _registerUser(
        address userAddress,
        string memory nickname
    ) internal {
        _registerUser(
            userAddress,
            nickname,
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
    }

    function testRegisterUser() public {
        _registerUser(user);

        UserProfiles.User memory userProfile = userProfiles.getUser(user);

        assertEq(userProfile.nickname, "John Doe");
        assertEq(
            uint8(userProfile.preferredReportType),
            uint8(UserProfiles.PreferredReportType.JSON)
        );
        assertEq(
            uint8(userProfile.focusArea),
            uint8(UserProfiles.FocusArea.DeFi)
        );
    }

    function testUserRegisteredEvent() public {
        vm.startPrank(user);
        vm.expectEmit(true, true, true, true);
        emit UserProfiles.UserRegistered(
            user,
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();
    }

    function testAlreadyRegisteredUser() public {
        _registerUser(user);

        vm.startPrank(user);
        vm.expectRevert(UserProfiles.AlreadyRegistered.selector);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();
    }

    function testEmptyNickname() public {
        vm.startPrank(user);
        vm.expectRevert(UserProfiles.EmptyNickname.selector);
        userProfiles.registerUser(
            "",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();
    }

    function testNicknameAlreadyTaken() public {
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.deactivateUser(user);
        vm.stopPrank();

        vm.expectRevert(UserProfiles.NicknameAlreadyTaken.selector);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();
    }

    function testRightTimestampIsSet() public {
        uint256 timestamp = block.timestamp;
        _registerUser(user);

        UserProfiles.User memory userProfile = userProfiles.getUser(user);
        assertEq(userProfile.registrationDate, timestamp);
    }

    function testRegisteredUserHasActiveStatus() public {
        _registerUser(user);

        bool isActive = userProfiles.checkUserRegisteredAndActive(user);
        assertTrue(isActive);
    }

    function testUserDataIsValid() public {
        _registerUser(user);

        UserProfiles.User memory userProfile = userProfiles.getUser(user);
        assertEq(userProfile.nickname, "John Doe");
        assertEq(
            uint8(userProfile.preferredReportType),
            uint8(UserProfiles.PreferredReportType.JSON)
        );
        assertEq(
            uint8(userProfile.focusArea),
            uint8(UserProfiles.FocusArea.DeFi)
        );
        assertTrue(userProfile.isActive);
        assertEq(userProfile.registrationDate, block.timestamp);
    }

    function testNonRegisteredUserHasEmptyData() public view {
        UserProfiles.User memory userProfile = userProfiles.getUser(user);
        assertEq(userProfile.nickname, "");
        assertEq(
            uint8(userProfile.preferredReportType),
            uint8(UserProfiles.PreferredReportType.JSON)
        );
        assertEq(
            uint8(userProfile.focusArea),
            uint8(UserProfiles.FocusArea.DeFi)
        );
        assertFalse(userProfile.isActive);
        assertEq(userProfile.registrationDate, 0);
    }

    function testUserUpdatePreferredReportType() public {
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.updatePreferredReportType(
            UserProfiles.PreferredReportType.NFT
        );
        vm.stopPrank();

        UserProfiles.User memory userProfile = userProfiles.getUser(user);
        assertEq(
            uint8(userProfile.preferredReportType),
            uint8(UserProfiles.PreferredReportType.NFT)
        );
    }

    function testUserUpdatePreferredReportTypeEvent() public {
        _registerUser(user);

        vm.startPrank(user);
        vm.expectEmit(true, true, true, true);
        emit UserProfiles.PreferredReportTypeUpdated(
            user,
            UserProfiles.PreferredReportType.NFT
        );
        userProfiles.updatePreferredReportType(
            UserProfiles.PreferredReportType.NFT
        );
        vm.stopPrank();
    }

    function testNonRegisteredUserCannotUpdatePreferredReportType() public {
        vm.startPrank(user);
        vm.expectRevert(UserProfiles.NotRegisteredOrActive.selector);
        userProfiles.updatePreferredReportType(
            UserProfiles.PreferredReportType.NFT
        );
        vm.stopPrank();
    }

    function testNonActiveUserCannotUpdatePreferredReportType() public {
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.deactivateUser(user);
        vm.stopPrank();

        vm.expectRevert(UserProfiles.NotRegisteredOrActive.selector);
        userProfiles.updatePreferredReportType(
            UserProfiles.PreferredReportType.NFT
        );
        vm.stopPrank();
    }

    function testUserUpdateNickname() public {
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.updateNickname("Jane Doe");
        vm.stopPrank();

        UserProfiles.User memory userProfile = userProfiles.getUser(user);
        assertEq(userProfile.nickname, "Jane Doe");
    }

    function testUserUpdateNicknameEvent() public {
        _registerUser(user);

        vm.startPrank(user);
        vm.expectEmit(true, true, true, true);
        emit UserProfiles.NicknameUpdated(user, "Jane Doe");
        userProfiles.updateNickname("Jane Doe");
        vm.stopPrank();
    }

    function testFreeOldNickname() public {
        address user2 = makeAddr("user2");
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.updateNickname("Jane Doe");
        vm.stopPrank();

        assertEq(userProfiles.nicknames("John Doe"), false);

        _registerUser(user2);

        UserProfiles.User memory userProfile = userProfiles.getUser(user);
        UserProfiles.User memory userProfile2 = userProfiles.getUser(user2);

        assertEq(userProfile.nickname, "Jane Doe");
        assertEq(userProfile2.nickname, "John Doe");
    }

    function testUpdateNonUniqueNickname() public {
        address user2 = makeAddr("user2");
        _registerUser(user);

        vm.startPrank(user2);
        vm.expectRevert(UserProfiles.NicknameAlreadyTaken.selector);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();
    }

    function testUpdateEmptyNickname() public {
        _registerUser(user);

        vm.startPrank(user);
        vm.expectRevert(UserProfiles.EmptyNickname.selector);
        userProfiles.updateNickname("");
        vm.stopPrank();
    }

    function testNonRegisteredUserCannotUpdateNickname() public {
        vm.startPrank(user);
        vm.expectRevert(UserProfiles.NotRegisteredOrActive.selector);
        userProfiles.updateNickname("Jane Doe");
        vm.stopPrank();
    }

    function testUpdateFocusArea() public {
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.updateFocusArea(UserProfiles.FocusArea.NFT);
        vm.stopPrank();

        UserProfiles.User memory userProfile = userProfiles.getUser(user);
        assertEq(
            uint8(userProfile.focusArea),
            uint8(UserProfiles.FocusArea.NFT)
        );
    }

    function testUpdateFocusAreaEvent() public {
        _registerUser(user);

        vm.startPrank(user);
        vm.expectEmit(true, true, true, true);
        emit UserProfiles.FocusAreaUpdated(user, UserProfiles.FocusArea.NFT);
        userProfiles.updateFocusArea(UserProfiles.FocusArea.NFT);
        vm.stopPrank();
    }

    function testNonRegisteredUserCannotUpdateFocusArea() public {
        vm.startPrank(user);
        vm.expectRevert(UserProfiles.NotRegisteredOrActive.selector);
        userProfiles.updateFocusArea(UserProfiles.FocusArea.NFT);
        vm.stopPrank();
    }

    function testNonActiveUserCannotUpdateFocusArea() public {
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.deactivateUser(user);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(UserProfiles.NotRegisteredOrActive.selector);
        userProfiles.updateFocusArea(UserProfiles.FocusArea.NFT);
        vm.stopPrank();
    }

    function testUpdateFocusAreaToAllEnumValues() public {
        _registerUser(user);

        for (uint256 i = 0; i < 4; i++) {
            vm.startPrank(user);
            userProfiles.updateFocusArea(UserProfiles.FocusArea(i));
            vm.stopPrank();

            UserProfiles.User memory userProfile = userProfiles.getUser(user);
            assertEq(uint8(userProfile.focusArea), i);
        }
    }

    function testUpdateLastReportId() public {
        _registerUser(user);

        vm.startPrank(reportManager);
        userProfiles.updateLastReportId(user, 1);
        vm.stopPrank();

        UserProfiles.User memory userProfile = userProfiles.getUser(user);
        assertEq(userProfile.lastReportId, 1);
    }

    function testUpdateLastReportIdEvent() public {
        _registerUser(user);

        vm.startPrank(reportManager);
        vm.expectEmit(true, true, true, true);
        emit UserProfiles.LastReportIdUpdated(user, 1);
        userProfiles.updateLastReportId(user, 1);
        vm.stopPrank();
    }

    function testNonReportManagerCannotUpdateLastReportId() public {
        vm.startPrank(user);
        vm.expectRevert(UserProfiles.NotAuthorizedReportManager.selector);
        userProfiles.updateLastReportId(user, 1);
        vm.stopPrank();
    }

    function testUpdateLastReportIdForNonActiveUser() public {
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.deactivateUser(user);
        vm.stopPrank();

        vm.startPrank(reportManager);
        vm.expectRevert(UserProfiles.NotRegisteredOrActive.selector);
        userProfiles.updateLastReportId(user, 1);
        vm.stopPrank();
    }

    function testUpdateLastReportIdForNonRegisteredUser() public {
        vm.startPrank(reportManager);
        vm.expectRevert(UserProfiles.NotRegisteredOrActive.selector);
        userProfiles.updateLastReportId(user, 1);
        vm.stopPrank();
    }

    function testDeactivateUser() public {
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.deactivateUser(user);
        vm.stopPrank();

        UserProfiles.User memory userProfile = userProfiles.getUser(user);
        assertFalse(userProfile.isActive);
    }

    function testDeactivateUserCannotUpdateProfile() public {
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.deactivateUser(user);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(UserProfiles.NotRegisteredOrActive.selector);
        userProfiles.updatePreferredReportType(
            UserProfiles.PreferredReportType.NFT
        );
        vm.stopPrank();
    }

    function testCannotDeactivateAnotherUser() public {
        _registerUser(user);
        address user2 = makeAddr("user2");
        _registerUser(user2, "Jane Doe");

        vm.startPrank(user2);
        vm.expectRevert(UserProfiles.NonSelfCaller.selector);
        userProfiles.deactivateUser(user);
        vm.stopPrank();
    }

    function testDeactiveAlreadyDeactivatedUser() public {
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.deactivateUser(user);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(UserProfiles.NotRegisteredOrActive.selector);
        userProfiles.deactivateUser(user);
        vm.stopPrank();
    }

    function testNonRegisteredUserCannotDeactivateUser() public {
        vm.startPrank(user);
        vm.expectRevert(UserProfiles.NotRegisteredOrActive.selector);
        userProfiles.deactivateUser(user);
        vm.stopPrank();
    }

    function testActivateUser() public {
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.deactivateUser(user);
        userProfiles.activateUser(user);
        vm.stopPrank();

        UserProfiles.User memory userProfile = userProfiles.getUser(user);
        assertTrue(userProfile.isActive);
    }

    function testCannotActivateAnotherUser() public {
        _registerUser(user);
        address user2 = makeAddr("user2");
        _registerUser(user2, "Jane Doe");

        vm.startPrank(user);
        userProfiles.deactivateUser(user);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert(UserProfiles.NonSelfCaller.selector);
        userProfiles.activateUser(user);
        vm.stopPrank();
    }

    function testActivateAlreadyActivatedUser() public {
        _registerUser(user);

        vm.startPrank(user);
        vm.expectRevert(UserProfiles.NotDeactivated.selector);
        userProfiles.activateUser(user);
        vm.stopPrank();
    }

    function testCheckUserRegisteredAndActiveTrue() public {
        _registerUser(user);

        assertTrue(userProfiles.checkUserRegisteredAndActive(user));
    }

    function testCheckUserRegisteredAndActiveFalseForNonActiveUser() public {
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.deactivateUser(user);
        vm.stopPrank();

        assertFalse(userProfiles.checkUserRegisteredAndActive(user));
    }

    function testCheckUserRegisteredAndActiveFalseForNonRegisteredUser()
        public
        view
    {
        assertFalse(userProfiles.checkUserRegisteredAndActive(user));
    }

    function testMultipleUsersCanRegister() public {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        address user5 = makeAddr("user5");
        address user6 = makeAddr("user6");
        address user7 = makeAddr("user7");
        address user8 = makeAddr("user8");
        address user9 = makeAddr("user9");
        address user10 = makeAddr("user10");

        _registerUser(user2, "Jane Doe");
        _registerUser(user3, "Doe Doe");
        _registerUser(user4, "Charlie Doe");
        _registerUser(user5, "David Doe");
        _registerUser(user6, "Eve Doe");
        _registerUser(user7, "Frank Doe");
        _registerUser(user8, "George Doe");
        _registerUser(user9, "Hannah Doe");
        _registerUser(user10, "Isaac Doe");

        assertTrue(userProfiles.checkUserRegisteredAndActive(user2));
        assertTrue(userProfiles.checkUserRegisteredAndActive(user3));
        assertTrue(userProfiles.checkUserRegisteredAndActive(user4));
        assertTrue(userProfiles.checkUserRegisteredAndActive(user5));
        assertTrue(userProfiles.checkUserRegisteredAndActive(user6));
        assertTrue(userProfiles.checkUserRegisteredAndActive(user7));
        assertTrue(userProfiles.checkUserRegisteredAndActive(user8));
        assertTrue(userProfiles.checkUserRegisteredAndActive(user9));
        assertTrue(userProfiles.checkUserRegisteredAndActive(user10));
    }

    function testNultipleUsersCanHaveSamePreferences() public {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        address user5 = makeAddr("user5");
        address user6 = makeAddr("user6");
        address user7 = makeAddr("user7");
        address user8 = makeAddr("user8");
        address user9 = makeAddr("user9");
        address user10 = makeAddr("user10");

        _registerUser(user2, "Jane Doe");
        _registerUser(user3, "Doe Doe");
        _registerUser(user4, "Charlie Doe");
        _registerUser(user5, "David Doe");
        _registerUser(user6, "Eve Doe");
        _registerUser(user7, "Frank Doe");
        _registerUser(user8, "George Doe");
        _registerUser(user9, "Hannah Doe");
        _registerUser(user10, "Isaac Doe");

        assertEq(
            uint8(userProfiles.getUser(user2).preferredReportType),
            uint8(UserProfiles.PreferredReportType.JSON)
        );
        assertEq(
            uint8(userProfiles.getUser(user3).preferredReportType),
            uint8(UserProfiles.PreferredReportType.JSON)
        );
        assertEq(
            uint8(userProfiles.getUser(user4).preferredReportType),
            uint8(UserProfiles.PreferredReportType.JSON)
        );
        assertEq(
            uint8(userProfiles.getUser(user5).preferredReportType),
            uint8(UserProfiles.PreferredReportType.JSON)
        );
        assertEq(
            uint8(userProfiles.getUser(user6).preferredReportType),
            uint8(UserProfiles.PreferredReportType.JSON)
        );
        assertEq(
            uint8(userProfiles.getUser(user7).preferredReportType),
            uint8(UserProfiles.PreferredReportType.JSON)
        );
        assertEq(
            uint8(userProfiles.getUser(user8).preferredReportType),
            uint8(UserProfiles.PreferredReportType.JSON)
        );
        assertEq(
            uint8(userProfiles.getUser(user9).preferredReportType),
            uint8(UserProfiles.PreferredReportType.JSON)
        );
        assertEq(
            uint8(userProfiles.getUser(user10).preferredReportType),
            uint8(UserProfiles.PreferredReportType.JSON)
        );
    }

    function testUserCannotTakeDeactivatedNickname() public {
        _registerUser(user);

        vm.startPrank(user);
        userProfiles.deactivateUser(user);
        vm.stopPrank();

        vm.expectRevert(UserProfiles.NicknameAlreadyTaken.selector);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();
    }

    function testRegisterWithVeryLongNickname() public {
        bytes memory packed = abi.encodePacked(
            "0123456789",
            "0123456789",
            "0123456789",
            "0123456789",
            "0123456789"
        );
        string memory nickname = string(packed);

        vm.startPrank(user);
        vm.expectRevert(UserProfiles.NicknameTooLong.selector);
        userProfiles.registerUser(
            nickname,
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();
    }
}
