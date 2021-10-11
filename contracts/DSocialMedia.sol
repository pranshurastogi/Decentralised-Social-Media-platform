// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "./ERC20Token.sol";

contract NFTPost is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ERC721URIStorageUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _idCounter;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct Post {
        uint256 id;
        uint256 createDate;
        bool visible;
        address creator;
        string description;
        string content;
    }

    struct Vote {
        uint256 postId;
        uint256 upVote;
        uint256 downVote;
    }

    struct User {
        uint256 userId;
        address userAddress;
        string profilePic;
        string Alias;
        UserStatus status;
    }

    struct Violation {
        uint256[] postIds;
        uint256 count;
        address postCreator;
    }

    uint256 private downVoteThreshold;
    uint256 private numberOfExcuses;
    uint256 private suspensionPeriod;
    uint256 private upVoteThreshold;
    ERC20 public token;

    enum UserStatus {
        NotActive,
        Active,
        Suspend
    }

    mapping(uint256 => Post) userById;

    mapping(address => User[]) userDetails;

    mapping(string => bool) private userAlias;

    event UserAdded(uint256, address);

    Post[] private posts;

    mapping(uint256 => Post) postById;
    mapping(address => Post[]) userPosts;
    mapping(uint256 => Vote) voteMap;
    mapping(address => Violation) postViolation;
    mapping(uint256 => uint256) currentPrice;

    /// @notice Emitted when the new post is created
    /// @param postId The unique identifier of post
    /// @param createDate The date of post creation
    /// @param creator The address of post creator
    /// @param description The description of the post
    /// @param contentUri The IPFS content uri
    event PostAdded(
        uint256 indexed postId,
        uint256 indexed createDate,
        address indexed creator,
        string description,
        string contentUri
    );

    /// @notice Emitted when any post is voted
    /// @param postId The unique identifier of post
    /// @param upVote The kind of vote, true = upVote, false = downVote
    /// @param voter The address of the voter
    event PostVote(uint256 indexed postId, bool upVote, address indexed voter);

    /// @notice Emitted when any post is reported for violation
    /// @param postIds The post ids that are considered violated
    /// @param count The counter tracking the number of violations by user
    /// @param postCreator The address of the post(s) creator
    event PostViolation(
        uint256[] postIds,
        uint256 indexed count,
        address indexed postCreator
    );

    function initialize(address _tokenAddress) public initializer {
        __ERC721_init("NonFungibleToken", "NFT");
        token = ERC20(_tokenAddress);
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        upVoteThreshold = 25;
        downVoteThreshold = 5;
        numberOfExcuses = 1;
        suspensionPeriod = 7;
    }

    /// @inheritdoc UUPSUpgradeable
    /// @dev The contract upgrade authorization handler. Only the users with role 'UPGRADER_ROLE' are allowed to upgrade the contract
    /// @param newImplementation The address of the new implementation contract
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /// @notice Called by owner to pause, transitons the contract to stopped state
    /// @dev This function can be accessed by the user with role PAUSER_ROLE
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Called by owner to unpause, transitons the contract back to normal state
    /// @dev This function can be accessed by the user with role PAUSER_ROLE
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function getupVoteThreshold() public view returns (uint256) {
        return upVoteThreshold;
    }

    function getDownVoteThreshold() public view returns (uint256) {
        return downVoteThreshold;
    }

    /// @notice Function to set down vote threshold
    /// @dev This function can be accessed by the user with role ADMIN
    function setDownVoteThreshold(uint256 _limit)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        downVoteThreshold = _limit;
    }

    /// @notice Function to set up vote threshold
    /// @dev This function can be accessed by the user with role ADMIN
    function setUpVoteThreshold(uint256 _limit)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        upVoteThreshold = _limit;
    }

    function getNumberOfExcuses() public view returns (uint256) {
        return numberOfExcuses;
    }

    /// @notice Function to set number of excuses for post violations
    /// @dev This function can be accessed by the user with role ADMIN
    function setNumberOfExcuses(uint256 _excuses)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        numberOfExcuses = _excuses;
    }

    function getSuspensionPeriod() public view returns (uint256) {
        return suspensionPeriod;
    }

    /// @notice Function to set the suspension period in days for each post violation
    /// @dev This function can be accessed by the user with role ADMIN
    function setSuspensionPeriod(uint256 _duration)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        suspensionPeriod = _duration;
    }

    /// @dev Post mappings to maintain
    function postOperations(Post memory post) internal {
        posts.push(post);
        userPosts[msg.sender].push(post);
        postById[post.id] = post;
    }

    /// @notice Emitted when any post is reported for violation
    /// @param _profilePic Profile image of user, will be stored on ipfs
    /// @param _alias Alias here is for unique user name
    function RegisterUsers(string memory _profilePic, string memory _alias)
        external
    {
        bool isUser = isUserExists(msg.sender);
        require(!isUser, "User already registered");
        require(!userAlias[_alias], "Not avaliable");
        userAlias[_alias] = true;
        uint256 userId = incrementAndGet();
        userDetails[msg.sender].push(
            User(userId, msg.sender, _profilePic, _alias, UserStatus.Active)
        );
        emit UserAdded(userId, msg.sender);
    }

    /// @notice Check whethe user exist or not, return boolean value
    /// @param _userAddress address of the user
    function isUserExists(address _userAddress) public view returns (bool) {
        User[] memory details = userDetails[_userAddress];
        for (uint256 i = 0; i < details.length; i++) {
            if (details[i].status == UserStatus.Active) return (true);
        }
        return (false);
    }

    /// @notice Allows user to delete their info
    function deleteUsers() public {
        User[] storage details = userDetails[msg.sender];
        User memory deleteUser;

        for (uint256 i = 0; i < details.length; i++) {
            deleteUser = details[i];
            details[i] = details[details.length - 1];
            details[details.length - 1] = deleteUser;
        }

        details.pop();
    }

    /// @dev Increment and get the counter, which is used as the unique identifier for post
    /// @return The unique identifier
    function incrementAndGet() internal returns (uint256) {
        _idCounter.increment();
        return _idCounter.current();
    }

    /// @notice Create a post with any multimedia and description. The multimedia should be stored in external storage and the record pointer to be used
    /// @dev Require a valid and not empty multimedia uri pointer. Emits PostAdded event.
    /// @param _description The description of the uploaded multimedia
    /// @param _contentUri The uri of the multimedia record captured in external storage
    function createPost(string memory _description, string memory _contentUri)
        external
    {
        require(bytes(_contentUri).length > 0, "Empty content uri");
        uint256 postId = incrementAndGet();
        Post memory post = Post(
            postId,
            block.timestamp,
            true,
            msg.sender,
            _description,
            _contentUri
        );

        postOperations(post);

        emit PostAdded(
            postId,
            block.timestamp,
            msg.sender,
            _description,
            _contentUri
        );
    }

    /// @notice Fetch the post record by its unique identifier
    /// @param _id The unique identifier of the post
    /// @return The post record
    function getPostById(uint256 _id) external view returns (Post memory) {
        return postById[_id];
    }

    /// @notice Fetch all the post records created by user
    /// @param _user The address of the user to fetch the post records
    /// @return The list of post records
    function getPostsByUser(address _user)
        external
        view
        returns (Post[] memory)
    {
        return userPosts[_user];
    }

    /// @notice Fetch all the posts created accross users
    /// @return The list of post records
    function getAllPosts() external view returns (Post[] memory) {
        return posts;
    }

    /// @notice Right to up vote or down vote any posts.
    /// @dev The storage vote instance is matched on identifier and updated with the vote. Emits PostVote event
    /// @param _postId The unique identifier of post
    /// @param _upVote True to upVote, false to downVote
    function vote(uint256 _postId, bool _upVote) external {
        Vote storage voteInstance = voteMap[_postId];
        voteInstance.postId = _postId;
        if (_upVote) voteInstance.upVote += 1;
        else voteInstance.downVote += 1;
    }

    /// @notice Fetch the number of votes by post id
    /// @param _postId The unique identifier of the post
    /// @return The vote record
    function getVoteByPostId(uint256 _postId)
        external
        view
        returns (Vote memory)
    {
        return voteMap[_postId];
    }

    function postViolationReport(uint256 _postId)
        external
        returns (uint256 _suspensionDays, bool ban)
    {
        Post memory post = postById[_postId];

        require(post.id == _postId, "Check the post id");

        Violation storage violation = postViolation[post.creator];
        violation.postIds.push(_postId);
        violation.count += 1;
        violation.postCreator = post.creator;

        post.visible = false;
        postOperations(post);

        emit PostViolation(
            violation.postIds,
            violation.count,
            violation.postCreator
        );

        if (violation.count <= numberOfExcuses) {
            return (suspensionPeriod, false);
        } else {
            return (0, true);
        }
    }

    /// @notice Allow user to minf NFT of their post if they get enough upvotes
    /// @param tokenURI Post metadata (stored on ipfs)
    /// @param _id The unique identifier of the post
    /// @param _amount amount to set as price of NFT
    /// @return The Item id
    function mintNFT(
        string memory tokenURI,
        uint256 _id,
        uint256 _amount
    ) public returns (uint256) {
        Vote storage voteInstance = voteMap[_id];

        require(voteInstance.upVote == upVoteThreshold, "Not enough votes");
        _idCounter.increment();
        uint256 newItemId = _idCounter.current();

        _mint(postById[_id].creator, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setNftPrice(_id, _amount);
        return newItemId;
    }

    /// @notice  ERC721Upgradeable and ERC721Upgradeable include supportsInterface so we need to override them.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getNftPrice(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId));

        return currentPrice[_tokenId];
    }

    function setNftPrice(uint256 _tokenId, uint256 _amount) internal {
        require(_exists(_tokenId));

        require(_amount > 0);
        currentPrice[_tokenId] = _amount;
    }

    function buyNFT(uint256 _tokenId, uint256 _amount) public {
        require(_exists(_tokenId));
        require(_amount >= currentPrice[_tokenId]);
        token.transfer(postById[_tokenId].creator, _amount);
        safeTransferFrom(postById[_tokenId].creator, msg.sender, _tokenId);
    }
}

