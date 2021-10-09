/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract RegisterUser is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    CountersUpgradeable.Counter private _idCounter;

    struct User {
        uint256 userId;
        address userAddress;
        string profilePic;
        string Alias;
        bool exists;
    }




    struct Post {
        uint id;
        string description;
        string content;
        address creator;
        uint createDate;
        bool visible;
        uint upVote;
        uint downVote;
    }
    
    Post[] private posts;

    mapping(address => User[]) userDetails;
        mapping(address => Post[]) userPosts;
    mapping(uint => Post) postById;

    event UserAdded(uint256, address);
      event PostVote(
        uint indexed postId,
        address indexed voter,
        bool upVote
    );

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }


    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function incrementAndGet() internal returns (uint256) {
        _idCounter.increment();
        return _idCounter.current();
    }

    function RegisterUsers(string memory _profilePic, string memory _alias)
        external
    {
        uint256 userId = incrementAndGet();
        userDetails[msg.sender].push(
            User(userId, msg.sender, _profilePic, _alias, true)
        );
        emit UserAdded(userId, msg.sender);
    }

    function isUserExists(address _userAddress) external view returns (bool) {
        User[] memory details = userDetails[_userAddress];
        for (uint256 i = 0; i < details.length; i++) {
            if (details[i].exists == true) return (true);
        }
        return (false);
    }

    function deleteStruct() public {
        User[] storage details = userDetails[msg.sender];
        User memory deleteUser;

        for (uint256 i = 0; i < details.length; i++) {
            deleteUser = details[i];
            details[i] = details[details.length - 1];
            details[details.length - 1] = deleteUser;
        }

        details.pop();
    }

          function createPost(string memory _description, string memory _contentUri)
        external
    {
        require(bytes(_contentUri).length > 0, "Empty content uri");
        uint postId = incrementAndGet();
        Post memory post = Post(postId, _description, _contentUri, msg.sender, block.timestamp, true,0,0);

        posts.push(post);
        userPosts[msg.sender].push(post);
        postById[postId] = post;

    }
   function getPostById(uint _id)
        external
        view
        returns(Post memory)
    {
        return postById[_id];
    }
        function upVote(uint256 _id) public {
        
    postById[_id].upVote = postById[_id].upVote++;
        
    }

    function downVote(uint256 _id) public {

    postById[_id].downVote = postById[_id].downVote++;
        
    }
    function getVote(uint256 _id) public view returns(uint) {
return postById[_id].downVote;
    }

    function suspendUser() public {

    }
}
