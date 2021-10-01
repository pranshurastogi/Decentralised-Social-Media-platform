// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTPost{
      using Counters for Counters.Counter;
  Counters.Counter private _NftPostIds; 

    struct NftPost{
        uint post_id;
        address NFTAddress;
        uint tokenId;
        address creator;
        uint timestamp;

    }

    mapping(uint => NftPost[]) NftPostId;
    
    function createPost(
    address nftContract,
    uint256 tokenId
  ) public   {
    

    _NftPostIds.increment();
    uint256 post_id = _NftPostIds.current();
  

    NftPostId[post_id].push(NftPost(post_id, nftContract,tokenId,msg.sender, block.timestamp));

    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
}

  function getAllNFTsByUser(uint256 postId) public view returns (NftPost[] memory) {
        return NftPostId[postId];

  }

  


}