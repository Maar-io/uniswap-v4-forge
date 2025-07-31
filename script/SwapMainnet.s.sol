// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

import {BaseScript} from "./base/BaseScript.s.sol";

contract SwapScript is BaseScript {
    function run() external {
        IERC20 USDT = IERC20(0x3A337a6adA9d885b6Ad95ec48F9b75f197b5AE35);
        IERC20 USDCE = IERC20(0xbA9986D2381edf1DA03B0B9c1f8b00dc4AacC369);

        // poolkey 0x86d50269915c269f9c1a1ef9a4685133a1dd84ac109ab4964bdbec7a338608be
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(USDT)),
            currency1: Currency.wrap(address(USDCE)),
            fee: 500,
            tickSpacing: 60,
            hooks: hookContract // This must match the pool
        });
        bytes memory hookData = new bytes(0);

        vm.startBroadcast();

        // We'll approve both, just for testing.
        token1.approve(address(swapRouter), type(uint256).max);
        token0.approve(address(swapRouter), type(uint256).max);

        // Execute swap
        swapRouter.swapExactTokensForTokens({
            amountIn: 1e6,
            amountOutMin: 0, // Very bad, but we want to allow for unlimited price impact
            zeroForOne: true,
            poolKey: poolKey,
            hookData: hookData,
            receiver: address(this),
            deadline: block.timestamp + 3600
        });

        vm.stopBroadcast();
    }
}
