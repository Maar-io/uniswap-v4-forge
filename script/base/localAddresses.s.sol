// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

import {MyToken} from "../../src/MyToken.sol";

/// @notice Shared addresses for local node
contract LocalAddresses {
    IPermit2 immutable permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    address immutable deployerAddress;

    IPoolManager immutable poolManager = IPoolManager(0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32); // Soneium
    IPositionManager immutable positionManager = IPositionManager(payable(0x1b35d13a2E2528f192637F14B05f0Dc0e7dEB566)); // Soneium


    IERC20 internal constant tokenETH = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 internal constant tokenUSDC = IERC20(0xbA9986D2381edf1DA03B0B9c1f8b00dc4AacC369); // USDC on Soneium mainnet (forked)
   
}
