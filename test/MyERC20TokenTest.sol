// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MyERC20Token} from "../src/MyERC20Token.sol";

contract MyERC20TokenTest is Test {
    MyERC20Token public token;

    function setUp() public {
        token = new MyERC20Token();
    }
}