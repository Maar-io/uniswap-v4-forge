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

contract CreatePoolAndAddLiquidityScript is BaseScript, LiquidityHelpers {
    using CurrencyLibrary for Currency;

    /////////////////////////////////////
    // --- Configure These ---
    /////////////////////////////////////

    uint160 startingPrice = 2 ** 96; // 1:1 starting price

    // --- liquidity position configuration --- //
    uint256 public token0Amount = 1000e6;
    uint256 public token1Amount = 1000e6;

    // range of the position, must be a multiple of tickSpacing
    int24 tickLower;
    int24 tickUpper;
    /////////////////////////////////////

    function run() external {
        _logInitialInfo();
        _checkBalances();

        PoolKey memory poolKey = _createPoolKey();
        _logPoolConfig(poolKey);

        _calculateTicks();

        (bytes memory actions, bytes[] memory mintParams) = _prepareMintParams(poolKey);
        bytes[] memory params = _prepareMulticallParams(actions, mintParams, poolKey);

        _executeTransaction(params);
        _logResults();
    }

    function _logInitialInfo() internal view {
        console2.log("=== Starting Pool Creation and Liquidity Addition ===");
        console2.log("Chain ID:", block.chainid);
        console2.log("Deployer Address:", deployerAddress);
        console2.log("");

        console2.log("=== Token Configuration ===");
        console2.log("Currency0 (USDC):", Currency.unwrap(currency0));
        console2.log("Currency1 (MUSD):", Currency.unwrap(currency1));
        console2.log("Token0 Amount:", token0Amount);
        console2.log("Token1 Amount:", token1Amount);
        console2.log("");
    }

    function _checkBalances() internal view {
        console2.log("=== Pre-Transaction Token Balances ===");
        uint256 balance0 = IERC20(Currency.unwrap(currency0)).balanceOf(deployerAddress);
        uint256 balance1 = IERC20(Currency.unwrap(currency1)).balanceOf(deployerAddress);
        console2.log("USDC Balance:", balance0);
        console2.log("MUSD Balance:", balance1);
        console2.log("Has enough USDC?", balance0 >= token0Amount);
        console2.log("Has enough MUSD?", balance1 >= token1Amount);
        console2.log("");
    }

    function _createPoolKey() internal view returns (PoolKey memory) {
        return PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: hookContract
        });
    }

    function _logPoolConfig(PoolKey memory poolKey) internal view {
        console2.log("=== Pool Configuration ===");
        console2.log("Fee:", poolKey.fee, "(0.01%)");
        console2.log("Tick Spacing:", uint256(int256(poolKey.tickSpacing)));
        console2.log("Starting Price (sqrtPriceX96):", startingPrice);
        console2.log("Hooks Contract:", address(poolKey.hooks));
        console2.log("");
    }

    function _calculateTicks() internal {
        int24 currentTick = TickMath.getTickAtSqrtPrice(startingPrice);
        console2.log("=== Tick Calculations ===");
        console2.log("Current Tick (from starting price):", int256(currentTick));

        tickLower = ((currentTick - 5000 * tickSpacing) / tickSpacing) * tickSpacing;
        tickUpper = ((currentTick + 5000 * tickSpacing) / tickSpacing) * tickSpacing;

        console2.log("Tick Lower:", int256(tickLower));
        console2.log("Tick Upper:", int256(tickUpper));
        console2.log("Tick Range:", int256(tickUpper - tickLower));
        console2.log("");
    }

    function _prepareMintParams(PoolKey memory poolKey) internal view returns (bytes memory, bytes[] memory) {
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            startingPrice,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            token0Amount,
            token1Amount
        );

        console2.log("=== Liquidity Calculations ===");
        console2.log("Calculated Liquidity:", liquidity);
        console2.log("");

        uint256 amount0Max = token0Amount + 1;
        uint256 amount1Max = token1Amount + 1;
        bytes memory hookData = new bytes(0);

        return _mintLiquidityParams(
            poolKey, tickLower, tickUpper, liquidity, amount0Max, amount1Max, deployerAddress, hookData
        );
    }

    function _prepareMulticallParams(bytes memory actions, bytes[] memory mintParams, PoolKey memory poolKey)
        internal
        view
        returns (bytes[] memory)
    {
        bytes[] memory params = new bytes[](2);
        bytes memory hookData = new bytes(0);

        params[0] = abi.encodeWithSelector(positionManager.initializePool.selector, poolKey, startingPrice, hookData);
        params[1] = abi.encodeWithSelector(
            positionManager.modifyLiquidities.selector, abi.encode(actions, mintParams), block.timestamp + 3600
        );

        console2.log("=== Multicall Parameters Prepared ===");
        console2.log("Param count:", params.length);
        console2.log("");

        return params;
    }

    function _executeTransaction(bytes[] memory params) internal {
        uint256 valueToPass = currency0.isAddressZero() ? (token0Amount + 1) : 0;

        console2.log("=== Starting Transaction ===");
        console2.log("Position Manager:", address(positionManager));

        vm.startBroadcast();

        console2.log("Broadcasting transaction...");
        tokenApprovals();
        console2.log("Token approvals completed");

        console2.log("Executing multicall...");
        positionManager.multicall{value: valueToPass}(params);
        console2.log("Multicall completed successfully!");

        vm.stopBroadcast();
    }

    function _logResults() internal view {
        console2.log("=== Post-Transaction Token Balances ===");
        uint256 balance0After = IERC20(Currency.unwrap(currency0)).balanceOf(deployerAddress);
        uint256 balance1After = IERC20(Currency.unwrap(currency1)).balanceOf(deployerAddress);
        console2.log("USDC Balance After:", balance0After);
        console2.log("MUSD Balance After:", balance1After);
        console2.log("");

        console2.log("=== Pool Creation Complete! ===");
        console2.log(unicode"✅ Pool initialized with 1:1 price ratio");
        console2.log(unicode"✅ Liquidity position created");
        console2.log(unicode"✅ Pool ready for trading");
    }
}
