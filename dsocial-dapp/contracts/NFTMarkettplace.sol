// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ERC20.sol";

contract NFTMarket {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds; //Id for each individual item
    Counters.Counter private _itemsSold; // No of items sold

    address payable owner; // Owner is the owner of the contract who makes commission on every transaction
    uint256 listingPrice = 0.5 ether; //listing price put by seller
    ERC20Token public tokenAddress; // ERC20 Token address for payment method

    constructor(address _tokenAddress) {
        owner = payable(msg.sender);
        tokenAddress = ERC20Token(_tokenAddress); 
    }

    struct Items {
        uint256 itemId; 
        address NFTAddress;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => Items) ItemId;

    event ItemsCreated(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address NFTAddress,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    // 2 function
    // 1st is for creating a market item and putting it for a sale
    //creating a market sale for buy and selling an item bw parties

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable {
        require(price > 0, "Price must be at least 1 wei");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        ItemId[itemId] = Items(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId); // Transfer ownership of nft from msg.sender to this contract

        emit ItemsCreated(
            itemId,
            tokenId,
            nftContract,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(address nftContract, uint256 itemId)
        public
        payable
    {
        uint256 price = ItemId[itemId].price;
        uint256 tokenId = ItemId[itemId].tokenId;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );
        tokenAddress.transfer(ItemId[itemId].seller, msg.value);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        ItemId[itemId].owner = payable(msg.sender);
        ItemId[itemId].sold = true;
        _itemsSold.increment();
        payable(owner).transfer(listingPrice);
    }
}
