// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/Script.sol";

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

import {BaseScript} from "./base/BaseScript.s.sol";

contract SwapScript is BaseScript {
    function run() external {
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: hookContract
        });
        bytes memory hookData = new bytes(0);

        vm.startBroadcast();

        // We'll approve both, just for testing.
        token1.approve(address(swapRouter), type(uint256).max);
        token0.approve(address(swapRouter), type(uint256).max);

        // Execute swap
        console2.log("Using timestamp:", block.timestamp);
        swapRouter.swapExactTokensForTokens({
            amountIn: 1e6,
            amountOutMin: 0,
            zeroForOne: false,
            poolKey: poolKey,
            hookData: hookData,
            receiver: address(this),
            deadline: block.timestamp + 3600
        });

        vm.stopBroadcast();
    }
}
