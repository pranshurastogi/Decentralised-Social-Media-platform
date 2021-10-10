/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/// @title SocialMedia
/// @notice SocialMedia content creation and voting
/// @dev This contract keeps track of all the posts created by registered users
contract SocialMedia is Initializable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _idCounter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint private downVoteThreshold; 
    uint private numberOfExcuses;
    uint private suspensionPeriod;

    struct Post {
        uint id;
        uint createDate;
        bool visible;
        address creator;
        string description;
        string content;
    }
    
    struct Vote {
        uint postId;
        uint upVote;
        uint downVote;
    }

    struct Violation {
        uint[] postIds;
        uint count;
        address postCreator;
    }
    
    Post[] private posts;

    mapping(uint => Post) postById;
    mapping(address => Post[]) userPosts;
    mapping(uint => Vote) voteMap;
    mapping(address => Violation) postViolation;

    /// @notice Emitted when the new post is created
    /// @param postId The unique identifier of post
    /// @param createDate The date of post creation
    /// @param creator The address of post creator
    /// @param description The description of the post
    /// @param contentUri The IPFS content uri
    event PostAdded(
        uint indexed postId,
        uint indexed createDate,
        address indexed creator,
        string description,
        string contentUri
    );
    
    /// @notice Emitted when any post is voted
    /// @param postId The unique identifier of post
    /// @param upVote The kind of vote, true = upVote, false = downVote
    /// @param voter The address of the voter
    event PostVote(
        uint indexed postId,
        bool upVote,
        address indexed voter
    );

    /// @notice Emitted when any post is reported for violation
    /// @param postIds The post ids that are considered violated
    /// @param count The counter tracking the number of violations by user
    /// @param postCreator The address of the post(s) creator
    event PostViolation(
        uint[] postIds,
        uint indexed count,
        address indexed postCreator
    );

    /// @notice The starting point of the contract, which defines the initial values
    /// @dev This is an upgradeable contract, DO NOT have constructor, and use this function for 
    ///     initialization of this and inheriting contracts
    function initialize()
        initializer
        public
    {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        downVoteThreshold = 5;
        numberOfExcuses = 1;
        suspensionPeriod = 7;
    }

    /// @inheritdoc UUPSUpgradeable
    /// @dev The contract upgrade authorization handler. Only the users with role 'UPGRADER_ROLE' are allowed to upgrade the contract
    /// @param newImplementation The address of the new implementation contract
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
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
    
    function getDownVoteThreshold()
        view
        public
        returns (uint)
    {
        return downVoteThreshold;
    }

    /// @notice Function to set down vote threshold
    /// @dev This function can be accessed by the user with role ADMIN
    function setDownVoteThreshold(uint _limit)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        downVoteThreshold = _limit;
    }

    function getNumberOfExcuses()
        view
        public
        returns (uint)
    {
        return numberOfExcuses;
    }

    /// @notice Function to set number of excuses for post violations
    /// @dev This function can be accessed by the user with role ADMIN
    function setNumberOfExcuses(uint _excuses)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        numberOfExcuses = _excuses;
    }

    function getSuspensionPeriod()
        view
        public
        returns (uint)
    {
        return suspensionPeriod;
    }

    /// @notice Function to set the suspension period in days for each post violation
    /// @dev This function can be accessed by the user with role ADMIN
    function setSuspensionPeriod(uint _duration)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        suspensionPeriod = _duration;
    }

    /// @dev Post mappings to maintain
    function postOperations(Post memory post) 
        internal
    {
        posts.push(post);
        userPosts[msg.sender].push(post);
        postById[post.id] = post;
    }
    
    /// @dev Increment and get the counter, which is used as the unique identifier for post
    /// @return The unique identifier
    function incrementAndGet()
        internal
        returns (uint)
    {
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
        uint postId = incrementAndGet();
        Post memory post = Post(postId, block.timestamp, true, msg.sender, _description, _contentUri);

        postOperations(post);
        
        emit PostAdded(postId, block.timestamp, msg.sender, _description, _contentUri);
    }
    
    /// @notice Fetch the post record by its unique identifier
    /// @param _id The unique identifier of the post
    /// @return The post record
    function getPostById(uint _id)
        external
        view
        returns(Post memory)
    {
        return postById[_id];
    }
    
    /// @notice Fetch all the post records created by user
    /// @param _user The address of the user to fetch the post records
    /// @return The list of post records
    function getPostsByUser(address _user)
        external
        view
        returns(Post[] memory)
    {
        return userPosts[_user];
    }
    
    /// @notice Fetch all the posts created accross users
    /// @return The list of post records
    function getAllPosts()
        external
        view
        returns (Post[] memory)
    {
        return posts;
    }
    
    /// @notice Right to up vote or down vote any posts.
    /// @dev The storage vote instance is matched on identifier and updated with the vote. Emits PostVote event
    /// @param _postId The unique identifier of post
    /// @param _upVote True to upVote, false to downVote
    function vote(uint _postId, bool _upVote)
        external
    {
        Vote storage voteInstance = voteMap[_postId];
        voteInstance.postId = _postId;
        if(_upVote)
            voteInstance.upVote += 1;
        else
            voteInstance.downVote += 1;
        
        emit PostVote(_postId, _upVote, msg.sender);
    }

    function getVoteByPostId(uint _postId)
        view
        external
        returns (Vote memory)
    {
        return voteMap[_postId];
    }

    function postViolationReport(uint _postId)
        external
        returns (uint _suspensionDays, bool ban)
    {
        Post memory post = postById[_postId];
        require(post.id == _postId, "Check the post id");

        Violation storage violation = postViolation[post.creator];
        violation.postIds.push(_postId);
        violation.count += 1;
        violation.postCreator = post.creator;

        post.visible = false;
        postOperations(post);

        emit PostViolation(violation.postIds, violation.count, violation.postCreator);

        if (violation.count <= numberOfExcuses) {
            return (suspensionPeriod, false);
        } else {
            // ban the user permanently from application
            // TODO add the user address to blacklist data structure
            return (0, true);
        }
    }
}
