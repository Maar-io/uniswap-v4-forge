// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";

contract MusdTest is Test {
    MyToken public token;
    uint256 public constant INITIAL_SUPPLY = 100_000 * 10 ** 6;

    function setUp() public {
        token = new MyToken("TestTokenMUSD", "MUSD", 6, INITIAL_SUPPLY);
    }

    function test_Mint() public {
        token.mint(address(this), 100);
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY + 100);
    }
}
