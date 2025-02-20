// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OICQ is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 public mintFee; // 铸造费用（以 ETH 为单位）

    // 定义一个事件来记录 铸造
    event Minted(address indexed owner, uint256 tokenId, string uri, uint256 timestamp);

    // 定义一个事件来记录每次修改 tokenURI
    event TokenURIUpdated(address indexed owner, uint256 tokenId, string uri, uint256 timestamp);

    event LogMessage(string message);

    constructor(string memory name, string memory symbol, address initialOwner, uint256 _mintFee) ERC721(name, symbol) Ownable(initialOwner) {
        mintFee = (_mintFee * 10 ** 18) / 100; // 将 ETH 转换为 wei（1 ETH = 10^18 wei）
    }

    function safeMint(address to, uint256 tokenId, string memory uri) public payable {
        // 检查用户支付的 ETH 是否足够（自动转换为 wei）
        require(msg.value >= mintFee, "Insufficient ETH sent for minting");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit Minted(to, tokenId, uri, block.timestamp);
    }

    // 允许合约所有者提取合约中的 ETH
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address _owner = _ownerOf(tokenId);
        return _isAuthorized(_owner, spender, tokenId);
    }

    // 合约所有者可以任意转移 NFT
    function transferNFT(address from, address to, uint256 tokenId) public onlyOwner {
        _transfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // 修改 NFT 的 tokenURI（仅 NFT 拥有者可调用）
    function setTokenURI(uint256 tokenId, string memory uri) public {
        require(ownerOf(tokenId) == msg.sender || owner() == msg.sender, "Only the owner can set the tokenURI");
        _setTokenURI(tokenId, uri); // 修改指定 tokenId 的 URI
        emit TokenURIUpdated(msg.sender, tokenId, uri, block.timestamp);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
