// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { OICQ } from "../src/NFT.sol";
import { MyERC20Token } from "../src/MyERC20Token.sol";

contract NFTTest is Test {
    OICQ public nft;
    MyERC20Token public token;

    function setUp() public {
        nft = new OICQ("Test NFT", "TEST", address(this), 100);
        token = new MyERC20Token();
    }

    /**
     * forge-config: default.fuzz.runs = 5
     * forge-config: default.fuzz.max-test-rejects = 100000
     */
    function test_safeMint(address to, uint256 tokenId, string memory uri) public {
        vm.assume(to != address(0));
        // 为随机地址分配 100 ether
        vm.deal(to, 100 ether);
        // 使用 vm.prank 让随机地址调用 safeMint
        vm.prank(to);
        nft.safeMint{ value: 1 ether }(to, tokenId, "test");
        // 断言随机地址的 NFT 余额为 1
        assertEq(nft.balanceOf(to), 1);
        // 断言随机地址的以太币余额为 99 ether
        assertEq(to.balance, 99 ether);
        assertEq(nft.tokenURI(tokenId), "test");
        nft.setTokenURI(tokenId, uri);
        assertEq(nft.tokenURI(tokenId), uri);
    }

    /**
     * forge-config: default.fuzz.runs = 5
     * forge-config: default.fuzz.max-test-rejects = 100000
     */
    function test_withdraw(address newOwner) public {
        vm.assume(newOwner != address(0));
        vm.expectRevert();
        nft.withdraw();

        vm.deal(address(nft), 100 ether);
        vm.deal(newOwner, 1 ether);
        nft.transferOwnership(newOwner);
        assertEq(nft.owner(), newOwner);
        vm.prank(address(nft));
        vm.prank(nft.owner());
        nft.withdraw();
        assertEq(newOwner.balance, 101 ether);
    }
    
    /**
     * forge-config: default.fuzz.runs = 5
     * forge-config: default.fuzz.max-test-rejects = 100000
     */
    function test_transferNFT(address from, address to, uint256 tokenId) public {
        vm.deal(address(nft), 100 ether);
        vm.assume(from != address(0));
        vm.assume(to != address(0));
        vm.deal(from, 1 ether);
        vm.prank(from);
        nft.safeMint{ value: 1 ether }(from, tokenId, "test");
        assertEq(nft.ownerOf(tokenId), from);
        nft.transferNFT(from, to, tokenId);
        assertEq(nft.ownerOf(tokenId), to);
    }
}
