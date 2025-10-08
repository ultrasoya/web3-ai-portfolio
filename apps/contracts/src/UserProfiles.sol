// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

/**
 * @title UserProfiles
 * @author Your Name
 * @notice This contract manages user profiles for the Web3 AI Portfolio platform
 * @dev Allows users to register, update their preferences, and track their report history
 */
contract UserProfiles {
    /**
     * @notice User profiles structure containing all user-related information
     * @param nickname Display name chosen by the user
     * @param registrationDate Unix timestamp when the user registered
     * @param preferredReportType User's preferred format for reports
     * @param focusArea User's area of interest in the Web3 space
     * @param lastReportId ID of the most recent report generated for this user
     */
    struct User {
        string nickname;
        uint40 registrationDate;
        PreferredReportType preferredReportType;
        FocusArea focusArea;
        uint lastReportId;
        bool isActive;
    }
    /**
     * @notice Enumeration of available report formats
     */
    enum PreferredReportType {
        JSON,
        PDF,
        NFT
    }

    /**
     * @notice Enumeration of user focus areas in the Web3 ecosystem
     */
    enum FocusArea {
        DeFi,
        NFT,
        Tokens,
        Portfolio
    }

    /// @notice Address of the contract owner
    address public immutable i_owner;

    /// @notice Address of the report manager
    address public immutable i_reportManager;

    /// @notice Mapping from user addresses to their profile information
    mapping(address => User) public users;

    /// @notice Mapping from nickname to boolean to track taken nicknames
    mapping(bytes32 => bool) public nicknames;

    /**
     * @notice Emitted when a new user registers
     * @param userAddress Address of the newly registered user
     * @param nickname Display name chosen by the user
     * @param preferredReportType User's preferred report format
     * @param focusArea User's area of interest
     */
    event UserRegistered(
        address indexed userAddress,
        string nickname,
        PreferredReportType preferredReportType,
        FocusArea focusArea
    );

    /**
     * @notice Emitted when a user updates their nickname
     * @param userAddress Address of the user
     * @param nickname New nickname
     */
    event NicknameUpdated(address indexed userAddress, string nickname);

    /**
     * @notice Emitted when a user updates their preferred report type
     * @param userAddress Address of the user
     * @param preferredReportType New preferred report type
     */
    event PreferredReportTypeUpdated(
        address indexed userAddress,
        PreferredReportType preferredReportType
    );

    /**
     * @notice Emitted when a user updates their focus area
     * @param userAddress Address of the user
     * @param focusArea New focus area
     */
    event FocusAreaUpdated(address indexed userAddress, FocusArea focusArea);

    /**
     * @notice Emitted when the last report ID is updated for a user
     * @param userAddress Address of the user
     * @param lastReportId New last report ID
     */
    event LastReportIdUpdated(address indexed userAddress, uint lastReportId);

    /// @notice Thrown when a user tries to register but is already registered
    error AlreadyRegistered();

    /// @notice Thrown when an operation requires registration but user is not registered
    error NotRegistered();

    /// @notice Thrown when a non-owner tries to call an owner-only function
    error NotOwner();

    /// @notice Thrown when a non-authorized report manager tries to call an authorized report manager-only function
    error NotAuthorizedReportManager();

    /// @notice Thrown when a nickname is already taken
    error NicknameAlreadyTaken();

    /// @notice Thrown when a non-user caller tries to call a user-only function
    error NonUserCaller();

    /// @notice Thrown when a nickname is empty
    error EmptyNickname();

    /**
     * @notice Modifier that ensures only the report manager can call the function
     * @dev Reverts with NotAuthorizedReportManager if the caller is not the report manager
     */
    modifier onlyAuthorizedReportManager() {
        if (msg.sender != i_reportManager) {
            revert NotAuthorizedReportManager();
        }
        _;
    }

    /**
     * @notice Modifier that ensures only unregistered users can call the function
     * @dev Reverts with AlreadyRegistered if the user is already registered
     */
    modifier onlyUnregisteredUser() {
        if (users[msg.sender].isActive) {
            revert AlreadyRegistered();
        }
        _;
    }

    /**
     * @notice Modifier that ensures only registered users can call the function
     * @dev Reverts with NotRegistered if the user is not registered
     */
    modifier onlyRegisteredUser() {
        if (!users[msg.sender].isActive) {
            revert NotRegistered();
        }
        _;
    }

    /**
     * @notice Modifier that ensures only unique nicknames can call the function
     * @dev Reverts with NicknameAlreadyTaken if the nickname is already taken
     */
    modifier onlyUniqueNickname(string memory nickname) {
        if (nicknames[keccak256(bytes(nickname))]) {
            revert NicknameAlreadyTaken();
        }
        _;
    }

    modifier onlyNonEmptyNickname(string memory nickname) {
        if (keccak256(bytes(nickname)) == keccak256(bytes(""))) {
            revert EmptyNickname();
        }
        _;
    }

    /**
     * @notice Constructor that sets the report manager
     * @dev The report manager can update report IDs
     */
    constructor(address _reportManager) {
        i_reportManager = _reportManager;
    }

    /**
     * @notice Registers a new user with the provided information
     * @param nickname Display name chosen by the user
     * @param preferredReportType User's preferred format for reports (JSON, PDF, or NFT)
     * @param focusArea User's area of interest (DeFi, NFT, Tokens, or Portfolio)
     * @dev Only unregistered users can call this function
     * @dev Emits UserRegistered event upon successful registration
     */
    function registerUser(
        string memory nickname,
        PreferredReportType preferredReportType,
        FocusArea focusArea
    )
        public
        onlyUnregisteredUser
        onlyUniqueNickname(nickname)
        onlyNonEmptyNickname(nickname)
    {
        users[msg.sender] = User(
            nickname,
            uint40(block.timestamp),
            preferredReportType,
            focusArea,
            0,
            true
        );
        nicknames[keccak256(bytes(nickname))] = true;

        emit UserRegistered(
            msg.sender,
            nickname,
            preferredReportType,
            focusArea
        );
    }

    /**
     * @notice Retrieves user profile information by address
     * @param userAddress The address of the user to query
     * @return User struct containing all user profile information
     * @dev Returns empty struct if user is not registered
     */
    function getUser(address userAddress) public view returns (User memory) {
        return users[userAddress];
    }

    /**
     * @notice Updates the user's preferred report type
     * @param preferredReportType New preferred report type (JSON, PDF, or NFT)
     * @dev Only registered users can call this function
     * @dev Emits PreferredReportTypeUpdated event upon successful update
     */
    function updatePreferredReportType(
        PreferredReportType preferredReportType
    ) public onlyRegisteredUser {
        users[msg.sender].preferredReportType = preferredReportType;

        emit PreferredReportTypeUpdated(msg.sender, preferredReportType);
    }

    /**
     * @notice Updates the user's nickname
     * @param nickname New display name for the user
     * @dev Only registered users can call this function
     * @dev Emits NicknameUpdated event upon successful update
     */
    function updateNickname(
        string memory nickname
    )
        public
        onlyRegisteredUser
        onlyUniqueNickname(nickname)
        onlyNonEmptyNickname(nickname)
    {
        nicknames[keccak256(bytes(users[msg.sender].nickname))] = false;

        nicknames[keccak256(bytes(nickname))] = true;
        users[msg.sender].nickname = nickname;

        emit NicknameUpdated(msg.sender, nickname);
    }

    /**
     * @notice Updates the user's focus area
     * @param focusArea New focus area (DeFi, NFT, Tokens, or Portfolio)
     * @dev Only registered users can call this function
     * @dev Emits FocusAreaUpdated event upon successful update
     */
    function updateFocusArea(FocusArea focusArea) public onlyRegisteredUser {
        users[msg.sender].focusArea = focusArea;

        emit FocusAreaUpdated(msg.sender, focusArea);
    }

    /**
     * @notice Updates the last report ID for a specific user
     * @param userAddress Address of the user to update
     * @param lastReportId ID of the most recent report generated for this user
     * @dev Only the report manager can call this function
     * @dev Reverts with NotRegistered if the user is not registered
     * @dev Emits LastReportIdUpdated event upon successful update
     */
    function updateLastReportId(
        address userAddress,
        uint lastReportId
    ) external onlyAuthorizedReportManager {
        if (users[userAddress].registrationDate == 0) {
            revert NotRegistered();
        }
        users[userAddress].lastReportId = lastReportId;

        emit LastReportIdUpdated(userAddress, lastReportId);
    }

    /**
     * @notice Checks if a user is registered and active in the system
     * @param userAddress Address of the user to check
     * @return True if the user is registered (has isActive flag set to true), false otherwise
     * @dev This is a view function that doesn't modify state
     */
    function checkUserRegisteredAndActive(
        address userAddress
    ) external view returns (bool) {
        return users[userAddress].isActive;
    }

    /**
     * @notice Deactivates a user account
     * @param userAddress Address of the user to deactivate
     * @dev Only registered users can call this function
     * @dev Sets the user's isActive flag to false
     */
    function deactivateUser(address userAddress) public onlyRegisteredUser {
        if (msg.sender != userAddress) {
            revert NonUserCaller();
        }
        users[userAddress].isActive = false;
    }

    /**
     * @notice Activates a user account
     * @param userAddress Address of the user to activate
     * @dev Only registered users can call this function
     * @dev Sets the user's isActive flag to true
     */
    function activateUser(address userAddress) public onlyRegisteredUser {
        if (msg.sender != userAddress) {
            revert NonUserCaller();
        }
        users[userAddress].isActive = true;
    }
}
