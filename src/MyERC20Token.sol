// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// 定义一个接口，确保目标合约有 tokensReceived 方法
interface ITokenReceiver {
    function tokensReceived(
        address operator,
        address from,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

contract MyERC20Token is ERC20, IERC721Receiver {
    constructor() ERC20("MyERC20Token", "MET") {
        _mint(msg.sender, 1000000 * 10**decimals()); // 初始化代币
        // nftMarket = _nftMarket;  // 保存 NFTMarket 合约地址
    }

    event LogMessage(string message);
    event LogReceived(address operator, address from, uint256 tokenId, bytes data);

    // 自定义代币转账的逻辑（处理转账后的其他操作）

    function transferWithCall(
        address nftMarket,
        address to,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        // 1. 检查发起者是否有足够的余额
        uint256 senderBalance = balanceOf(msg.sender);
        require(senderBalance >= amount, "Insufficient balance");

        // 2. 执行 ERC20 的 `transferFrom` 方法进行代币转账
        bool transferSuccess = transfer(to, amount);
        require(transferSuccess, "Transfer failed");

        emit LogMessage("--------002---------");
        // 3. 如果目标地址是合约且实现了 ITokenReceiver 接口，则调用 tokensReceived
        // bool success;
        if (isContract(nftMarket)) {
            bool success = ITokenReceiver(nftMarket).tokensReceived(
                address(this),
                msg.sender,
                amount,
                data
            );
            require(success, "Failed to call tokensReceived on target contract");
        }
        // require(success, "Failed to call tokensReceived on target contract");
        return true;
    }

    // 判断地址是否为合约地址
    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        emit LogReceived(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }
}