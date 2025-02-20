// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarket is Ownable {
    IERC20 public paymentToken; // ERC20 代币
    IERC721 public nftContract; // ERC721 NFT 合约

    struct Listing {
        uint256 price; // 上架价格
        address seller; // 卖家地址
    }

    // 记录每个 NFT 是否上架
    mapping(uint256 => Listing) public listings;

    // 用于存储所有上架的 tokenId
    uint256[] public listedTokenIds;

    event NFTListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );
    event NFTSold(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    );
    event ListingRemoved(uint256 indexed tokenId);
    event LogMessage(string message);
    event LogMessage(address message);
    // 构造函数
    constructor(
        address _paymentToken,
        address _nftContract,
        address initialOwner
    ) Ownable(initialOwner) {
        paymentToken = IERC20(_paymentToken);
        nftContract = IERC721(_nftContract);
        transferOwnership(initialOwner); // 设置初始所有者
    }

    // 上架 NFT
    function list(uint256 tokenId, uint256 price) external {
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        require(price > 0, "Price must be greater than 0");

        listings[tokenId] = Listing({price: price, seller: msg.sender});

        // 将 NFT 从卖家转移到合约，直到交易完成
        // nftContract.approve(address(this), tokenId);
        // nftContract.transferFrom(msg.sender, address(this), tokenId);

        // 将 tokenId 添加到上架列表
        listedTokenIds.push(tokenId);

        emit NFTListed(tokenId, msg.sender, price);
    }

    // 购买 NFT
    function buyNFT(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "This NFT is not for sale");

        // 转账支付代币
        require(
            paymentToken.transferFrom(
                msg.sender,
                listing.seller,
                listing.price
            ),
            "Payment failed"
        );

        // 转移 NFT 到买家
        nftContract.transferFrom(listing.seller, msg.sender, tokenId);

        // 移除上架信息
        delete listings[tokenId];

        // 从上架列表中移除该 tokenId
        _removeListedTokenId(tokenId);

        emit NFTSold(tokenId, msg.sender, listing.price);
    }

    // 撤销上架 NFT
    function removeListing(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.seller == msg.sender, "You are not the seller");

        // 将 NFT 返回卖家
        // nftContract.safeTransferFrom(address(this), msg.sender, tokenId);

        // 删除上架信息
        delete listings[tokenId];

        // 从上架列表中移除该 tokenId
        _removeListedTokenId(tokenId);

        emit ListingRemoved(tokenId);
    }

    // 获取上架的 NFT 列表
    function getListedNFTs() external view returns (uint256[] memory) {
        return listedTokenIds;
    }

    // 获取指定 tokenId 的上架信息
    function getListing(uint256 tokenId)
        external
        view
        returns (uint256 price, address seller)
    {
        Listing memory listing = listings[tokenId];
        return (listing.price, listing.seller);
    }

    // 辅助函数：从上架列表中移除指定的 tokenId
    function _removeListedTokenId(uint256 tokenId) internal {
        for (uint256 i = 0; i < listedTokenIds.length; i++) {
            if (listedTokenIds[i] == tokenId) {
                // 用最后一个元素替换删除的元素
                listedTokenIds[i] = listedTokenIds[listedTokenIds.length - 1];
                // 删除最后一个元素
                listedTokenIds.pop();
                break;
            }
        }
    }

    // 设置 ERC20 代币接收者方法（ERC20 扩展的 tokensReceived）
    function tokensReceived(
        address operator,
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        
        require(msg.sender == address(paymentToken), "Only the NFTMarket can call this function");
        // 处理代币接收的逻辑，例如购买 NFT
        uint256 tokenId = abi.decode(data, (uint256));
        Listing memory listing = listings[tokenId];

        // 确保该 NFT 上架且价格匹配
        require(listing.price == amount, "Incorrect payment amount");
        require(listing.price > 0, "This NFT is not for sale");

        // // 转账支付代币
        // require(
        //     paymentToken.transferFrom(from, listing.seller, amount),
        //     "Payment failed"
        // );

        // 转移 NFT 到买家
        // nftContract.safeTransferFrom(address(this), from, tokenId);

        // 转移 NFT 到买家
        emit LogMessage(listing.seller);
        nftContract.transferFrom(listing.seller, from, tokenId);
        
        // 移除上架信息
        delete listings[tokenId];

        // 从上架列表中移除该 tokenId
        _removeListedTokenId(tokenId);

        emit NFTSold(tokenId, from, amount);
        return true;
    }
}
