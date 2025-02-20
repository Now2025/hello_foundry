// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { NFTMarket } from "../src/NFTMarket.sol";
import { MyERC20Token } from "../src/MyERC20Token.sol";
import { OICQ } from "../src/NFT.sol";

contract NFTMarketTest is Test {
    NFTMarket public nftMarket;
    MyERC20Token public token;
    OICQ public nft;

    function setUp() public {
        nft = new OICQ("Test NFT", "TEST", address(this), 100);
        token = new MyERC20Token();
        nftMarket = new NFTMarket(address(token), address(nft), address(this));
    }

    /**
     * forge-config: default.fuzz.runs = 5
     * forge-config: default.fuzz.max-test-rejects = 100000
     */
    function test_list(address nftAddress, uint256 tokenId) public {
        vm.assume(nftAddress != address(0));
        vm.deal(nftAddress, 100 ether);
        vm.prank(nftAddress);
        nft.safeMint{ value: 1 ether }(nftAddress, tokenId, "test");
        assertEq(nft.ownerOf(tokenId), nftAddress);
        vm.prank(nftAddress);
        nft.approve(address(nftMarket), tokenId);
        vm.prank(nftAddress);
        nftMarket.list(tokenId, 1 ether);
        (uint256 actualPrice, address actualSeller) = nftMarket.listings(tokenId);
        assertEq(actualPrice, 1 ether);
        assertEq(actualSeller, nftAddress);
    }

    /**
     * forge-config: default.fuzz.runs = 5
     * forge-config: default.fuzz.max-test-rejects = 100000
     */
    function test_buy(address buyer, address seller, uint256 tokenId) public {
        // 初始化
        vm.assume(buyer != address(0));
        vm.assume(seller != address(0));
        vm.assume(buyer != seller);
        vm.deal(buyer, 100 ether);
        vm.deal(seller, 100 ether);
        token.transfer(buyer, 10 ether);
        token.transfer(seller, 10 ether);
        console.log("token.balanceOf(buyer):", token.balanceOf(buyer));
        console.log("token.balanceOf(seller):", token.balanceOf(seller));
        // 铸造 上架
        vm.prank(seller);
        nft.safeMint{ value: 1 ether }(seller, tokenId, "test");
        vm.prank(seller);
        nft.approve(address(nftMarket), tokenId);
        vm.prank(seller);
        nftMarket.list(tokenId, 1 ether);

        // 购买
        console.log("buyer:", buyer);
        console.log("buyer.balance:", buyer.balance);

        vm.prank(buyer);
        token.approve(address(nftMarket), 100 ether);

        console.log("buyer.allowance:", token.allowance(buyer, address(nftMarket)));
        vm.prank(buyer);
        nftMarket.buyNFT(tokenId);
        assertEq(nft.ownerOf(tokenId), buyer);
        assertEq(nft.balanceOf(seller), 0);
        assertEq(nft.balanceOf(buyer), 1);
        assertEq(token.balanceOf(buyer), 9 ether);
        assertEq(token.balanceOf(seller), 11 ether);
    }
    /**
     * forge-config: default.fuzz.runs = 5
     * forge-config: default.fuzz.max-test-rejects = 100000
     */
    function test_removeListing(address seller, uint256 tokenId) public {
        vm.assume(seller != address(0));
        vm.deal(seller, 100 ether);
        vm.prank(seller);
        nft.safeMint{ value: 1 ether }(seller, tokenId, "test");
        vm.prank(seller);
        nft.approve(address(nftMarket), tokenId);
        vm.prank(seller);
        nftMarket.list(tokenId, 1 ether);
        vm.prank(seller);
        nftMarket.removeListing(tokenId);
        (uint256 actualPrice, address actualSeller) = nftMarket.listings(tokenId);
        assertEq(actualPrice, 0);
        assertEq(actualSeller, address(0));
    }

    /**
     * forge-config: default.fuzz.runs = 5
     * forge-config: default.fuzz.max-test-rejects = 100000
     */
    function test_tokensReceived(address buyer, address seller, uint256 tokenId) public {
        // 初始化
        vm.assume(buyer != address(0));
        vm.assume(seller != address(0));
        vm.assume(buyer != seller);
        vm.deal(buyer, 100 ether);
        vm.deal(seller, 100 ether);
        token.transfer(buyer, 10 ether);
        token.transfer(seller, 10 ether);
        // 铸造 上架
        vm.prank(seller);
        nft.safeMint{ value: 1 ether }(seller, tokenId, "test");
        vm.prank(seller);
        nft.approve(address(nftMarket), tokenId);
        vm.prank(seller);
        nftMarket.list(tokenId, 1 ether);
        // 购买
        vm.prank(buyer);
        token.transferWithCall(address(nftMarket), seller, 1 ether, abi.encode(tokenId));
        assertEq(nft.ownerOf(tokenId), buyer);
        assertEq(token.balanceOf(seller), 11 ether);
        assertEq(token.balanceOf(buyer), 9 ether);
        assertEq(token.balanceOf(address(nftMarket)), 0);
        assertEq(token.allowance(buyer, address(nftMarket)), 0);
        assertEq(token.allowance(seller, address(nftMarket)), 0);
        assertEq(nft.balanceOf(seller), 0);
        assertEq(nft.balanceOf(buyer), 1);
        (uint256 actualPrice, address actualSeller) = nftMarket.getListing(tokenId);
        assertEq(actualPrice, 0);
        console.log("actualSeller:", actualSeller);
        assertEq(actualSeller, address(0));
    }
}
