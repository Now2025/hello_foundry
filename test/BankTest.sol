// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;

    // 在每个测试用例之前运行，初始化Bank合约实例
    function setUp() public {
        bank = new Bank();
    }
    
    // 测试存入1个ETH
    function test_DepositETH() public {
        bank.depositETH{value: 1 ether}();
        assertEq(bank.balanceOf(address(this)), 1 ether);
    } 

    // 测试存入0个ETH时应抛出异常
    function test_DepositETH_Zero() public {
        vm.expectRevert("Deposit amount must be greater than 0");
        bank.depositETH{value: 0}();
    }

    // 测试多次存入ETH
    function test_DepositETH_Multiple() public {
        bank.depositETH{value: 1 ether}();
        bank.depositETH{value: 2 ether}();
        assertEq(bank.balanceOf(address(this)), 3 ether);
    }
}
