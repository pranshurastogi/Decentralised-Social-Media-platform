/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

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

    event PostAdded(
        uint indexed postId,
        address indexed creator,
        uint indexed createDate,
        string description,
        string contentUri
    );
    
    event PostVote(
        uint indexed postId,
        address indexed voter,
        bool upVote
    );

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
    
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
    
    function incrementAndGet()
        internal
        returns (uint _id)
    {
        _idCounter.increment();
        return _idCounter.current();
    }

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
    
    function getPostById(uint _id)
        external
        view
        returns(Post memory)
    {
        return postById[_id];
    }
    
    function getPostsByUser(address _user)
        external
        view
        returns(Post[] memory)
    {
        return userPosts[_user];
    }
    
    function getAllPosts()
        external
        view
        returns (Post[] memory)
    {
        return posts;
    }
    
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
