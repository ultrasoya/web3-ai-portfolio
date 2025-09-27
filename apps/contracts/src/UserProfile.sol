// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

/**
 * @title UserProfile
 * @author Your Name
 * @notice This contract manages user profiles for the Web3 AI Portfolio platform
 * @dev Allows users to register, update their preferences, and track their report history
 */
contract UserProfile {
    /**
     * @notice User profile structure containing all user-related information
     * @param nickname Display name chosen by the user
     * @param registrationDate Unix timestamp when the user registered
     * @param preferredReportType User's preferred format for reports
     * @param focusArea User's area of interest in the Web3 space
     * @param lastReportId ID of the most recent report generated for this user
     */
    struct User {
        string nickname;
        uint64 registrationDate;
        PreferredReportType preferredReportType;
        FocusArea focusArea;
        uint lastReportId;
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

    /// @notice Address of the contract owner who can update report IDs
    address public immutable i_owner;

    /// @notice Mapping from user addresses to their profile information
    mapping(address => User) public users;

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

    /**
     * @notice Modifier that ensures only unregistered users can call the function
     * @dev Reverts with AlreadyRegistered if the user is already registered
     */
    modifier onlyUnregisteredUser() {
        if (users[msg.sender].registrationDate != 0) {
            revert AlreadyRegistered();
        }
        _;
    }

    /**
     * @notice Modifier that ensures only registered users can call the function
     * @dev Reverts with NotRegistered if the user is not registered
     */
    modifier onlyRegisteredUser() {
        if (users[msg.sender].registrationDate == 0) {
            revert NotRegistered();
        }
        _;
    }

    /**
     * @notice Modifier that ensures only the contract owner can call the function
     * @dev Reverts with NotOwner if the caller is not the owner
     */
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    /**
     * @notice Constructor that sets the contract owner to the deployer
     * @dev The deployer becomes the owner and can update report IDs
     */
    constructor() {
        i_owner = msg.sender;
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
    ) public onlyUnregisteredUser {
        users[msg.sender] = User(
            nickname,
            uint64(block.timestamp),
            preferredReportType,
            focusArea,
            0
        );

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
    function updateNickname(string memory nickname) public onlyRegisteredUser {
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
     * @dev Only the contract owner can call this function
     * @dev Reverts if the user is not registered
     * @dev Emits LastReportIdUpdated event upon successful update
     */
    function updateLastReportId(
        address userAddress,
        uint lastReportId
    ) public onlyOwner {
        if (users[userAddress].registrationDate == 0) {
            revert NotRegistered();
        }
        users[userAddress].lastReportId = lastReportId;

        emit LastReportIdUpdated(userAddress, lastReportId);
    }

    function checkUserRegistered(
        address userAddress
    ) external view returns (bool) {
        return users[userAddress].registrationDate != 0;
    }
}
