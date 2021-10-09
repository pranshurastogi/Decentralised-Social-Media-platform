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

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    CountersUpgradeable.Counter private _idCounter;

    struct Post {
        uint id;
        string description;
        string content;
        address creator;
        uint createDate;
        bool visible;
    }
    
    struct Vote {
        uint id;
        uint upVote;
        uint downVote;
    }
    
    Post[] private posts;

    mapping(uint => Post) postById;
    mapping(address => Post[]) userPosts;
    mapping(uint => Vote) voteMap;

    /// @notice Emitted when the new post is created
    /// @param postId The unique identifier of post
    /// @param creator The address of post creator
    /// @param createDate The date of post creation
    /// @param description The description of the post
    /// @param contentUri The IPFS content uri
    event PostAdded(
        uint indexed postId,
        address indexed creator,
        uint indexed createDate,
        string description,
        string contentUri
    );
    
    /// @notice Emitted when any post is voted
    /// @param postId The unique identifier of post
    /// @param voter The address of the voter
    /// @param upVote The kind of vote, true = upVote, false = downVote
    event PostVote(
        uint indexed postId,
        address indexed voter,
        bool upVote
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
        Post memory post = Post(postId, _description, _contentUri, msg.sender, block.timestamp, true);

        posts.push(post);
        userPosts[msg.sender].push(post);
        postById[postId] = post;

        emit PostAdded(postId, msg.sender, block.timestamp, _description, _contentUri);
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
    /// @param _id The unique identifier of post
    /// @param _upVote True to upVote, false to downVote
    function vote(uint _id, bool _upVote)
        external
    {
        Vote storage voteInstance = voteMap[_id];
        if(_upVote)
            voteInstance.upVote = voteInstance.upVote++;
        else
            voteInstance.downVote = voteInstance.downVote++;
        
        emit PostVote(_id, msg.sender, _upVote);
    }
}
