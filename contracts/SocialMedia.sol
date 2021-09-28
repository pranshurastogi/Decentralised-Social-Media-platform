// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SocialMedia {

    struct Post {
        uint id;
        string description;
        string content;
        address creator;
        uint createDate;
    }
    
    struct Vote {
        uint id;
        uint upVote;
        uint downVote;
    }
    
    mapping(address => Post[]) userPosts;
    
    function createPost(string memory _contentUri) external {
        
    }
    
    function getPostById(uint _id) external returns(Post memory) {
        
    }
    
    function getPostsByUser(address _user) external returns(Post[] memory) {
        
    }
    
    function getAllPosts() external {
        
    }
    
    function vote(uint id, bool upVote) external {
        
    }
}
