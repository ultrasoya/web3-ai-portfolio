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

    function setUp() public {
        reportsManager = makeAddr("reportManager");
        userProfiles = new UserProfiles(reportsManager);
        user = makeAddr("user");
    }

    function testRegisterUser() public {
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

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
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

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
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );

        userProfiles.deactivateUser(user);

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
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

        UserProfiles.User memory userProfile = userProfiles.getUser(user);
        assertEq(userProfile.registrationDate, timestamp);
    }

    function testRegisteredUserHasActiveStatus() public {
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

        bool isActive = userProfiles.checkUserRegisteredAndActive(user);
        assertTrue(isActive);
    }

    function testUserDataIsValid() public {
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

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
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

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
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

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
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );

        userProfiles.deactivateUser(user);

        vm.expectRevert(UserProfiles.NotRegisteredOrActive.selector);
        userProfiles.updatePreferredReportType(
            UserProfiles.PreferredReportType.NFT
        );
        vm.stopPrank();
    }

    function testUserUpdateNickname() public {
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

        vm.startPrank(user);
        userProfiles.updateNickname("Jane Doe");
        vm.stopPrank();

        UserProfiles.User memory userProfile = userProfiles.getUser(user);
        assertEq(userProfile.nickname, "Jane Doe");
    }

    function testUserUpdateNicknameEvent() public {
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectEmit(true, true, true, true);
        emit UserProfiles.NicknameUpdated(user, "Jane Doe");
        userProfiles.updateNickname("Jane Doe");
        vm.stopPrank();
    }

    function testFreeOldNickname() public {
        address user2 = makeAddr("user2");
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );

        userProfiles.updateNickname("Jane Doe");
        vm.stopPrank();

        assertEq(userProfiles.nicknames("John Doe"), false);

        vm.startPrank(user2);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

        UserProfiles.User memory userProfile = userProfiles.getUser(user);
        UserProfiles.User memory userProfile2 = userProfiles.getUser(user2);

        assertEq(userProfile.nickname, "Jane Doe");
        assertEq(userProfile2.nickname, "John Doe");
    }

    function testUpdateNonUniqueNickname() public {
        address user2 = makeAddr("user2");
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

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
        vm.startPrank(user);
        userProfiles.registerUser(
            "John Doe",
            UserProfiles.PreferredReportType.JSON,
            UserProfiles.FocusArea.DeFi
        );
        vm.stopPrank();

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
}
