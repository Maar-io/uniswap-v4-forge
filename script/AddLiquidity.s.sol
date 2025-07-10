// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";

import {BaseScript} from "./base/BaseScript.s.sol";
import {LiquidityHelpers} from "./base/LiquidityHelpers.s.sol";

contract AddLiquidity is BaseScript, LiquidityHelpers {
    using CurrencyLibrary for Currency;

    int24 tickSpacing = 1;
    uint160 startingPrice = 2 ** 96;

    uint256 public token0Amount = 50e6;   // 50 USDC
    uint256 public token1Amount = 50e18;  // 50 MUSD

    int24 tickLower;
    int24 tickUpper;

    function run() external {
        console2.log("=== Adding Liquidity to Existing Pool ===");
        
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: hookContract
        });

        // Calculate ticks
        int24 currentTick = TickMath.getTickAtSqrtPrice(startingPrice);
        tickLower = ((currentTick - 5000 * tickSpacing) / tickSpacing) * tickSpacing;
        tickUpper = ((currentTick + 5000 * tickSpacing) / tickSpacing) * tickSpacing;

        // Prepare liquidity params
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            startingPrice,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            token0Amount,
            token1Amount
        );

        uint256 amount0Max = token0Amount + 1;
        uint256 amount1Max = token1Amount + 1;
        bytes memory hookData = new bytes(0);

        (bytes memory actions, bytes[] memory mintParams) = _mintLiquidityParams(
            poolKey, tickLower, tickUpper, liquidity, amount0Max, amount1Max, deployerAddress, hookData
        );

        console2.log("=== Executing Liquidity Addition ===");
        
        vm.startBroadcast();
        
        tokenApprovals();
        
        // Only add liquidity (no pool initialization)
        positionManager.modifyLiquidities(
            abi.encode(actions, mintParams), 
            block.timestamp + 3600
        );
        
        console2.log(unicode"✅ Liquidity added successfully!");
        
        vm.stopBroadcast();
    }
}