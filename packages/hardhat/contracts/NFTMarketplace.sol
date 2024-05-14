// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemSold;

    address payable private admin;
    uint256 listingPrice = 0.001 ether;

    constructor() {
        admin = payable(msg.sender);
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint tokenId;
        address payable seller;
        address payable owner;
        uint price;
        bool sold;
    }

    mapping(uint => MarketItem) private idToMarketItem;

    event MarketItemCreated(uint indexed itemId, address indexed nftContract, uint indexed tokenId, address seller, address owner, uint price, bool sold);
    event MarketItemSold(uint indexed itemId, address indexed nftContract, uint indexed tokenId, address seller, address owner, uint price);

    function createMarketItem(address nftContract, uint tokenId, uint price) external payable {
        require(msg.value == listingPrice, "Price must be equal to listing price");

        _itemIds.increment();
        uint itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        emit MarketItemCreated(itemId, nftContract, tokenId, msg.sender, address(0), price, false);
    }

    function buyMarketItem(uint itemId) external payable {
        MarketItem storage item = idToMarketItem[itemId];
        require(item.seller != address(0), "Item must exist");
        require(msg.value == item.price, "Price must be equal to item price");
        require(item.sold == false, "Item already sold");

        item.sold = true;
        item.owner = payable(msg.sender);
        _itemSold.increment();
        
        (bool success, ) = item.seller.call{value: item.price}("");
        require(success, "Transfer failed");

        emit MarketItemSold(itemId, item.nftContract, item.tokenId, item.seller, msg.sender, item.price);
    }

    function setListingPrice(uint256 price) external onlyOwner {
        listingPrice = price;
    }

    function fetchMarketItems() external view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 1; i <= itemCount; i++) {
            if (idToMarketItem[i].owner == address(0)) {
                MarketItem storage currentItem = idToMarketItem[i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchMyNFTs() external view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint itemCountForOwner = 0;
        uint currentIndex = 0;

        for (uint i = 1; i <= itemCount; i++) {
            if (idToMarketItem[i].owner == msg.sender) {
                itemCountForOwner += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCountForOwner);
        for (uint i = 1; i <= itemCount; i++) {
            if (idToMarketItem[i].owner == msg.sender) {
                MarketItem storage currentItem = idToMarketItem[i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }
}