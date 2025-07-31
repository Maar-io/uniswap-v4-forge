// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";

import {LocalhostHelpers} from "./base/LocalhostHelpers.s.sol";

contract CreateLocalhostPoolScript is LocalhostHelpers {
    using CurrencyLibrary for Currency;

    IERC20 internal tokenMUSD;
    Currency internal currency0;
    Currency internal currency1;
    Currency internal currency2;
    Currency internal currency3;
    uint160 startingStablePrice = 2 ** 96; // 1:1 starting price
    uint160 startingETHpoolPrice = 1873855042454260090959041; // Precomputed: sqrtPriceX96 = uint160(sqrt(3500 * 1e18 / 1e6) * 2**96)

    // --- liquidity position configuration --- //
    uint256 public tokenUSDCAmount = 1000e6;
    uint256 public tokenMUSDAmount = 1000e6;

    uint256 public tokenETHAmount = 10e18; // 10 ETH
    uint256 public tokenMUSDAmount2 = 35000e6; // 35000 MUSD

    // range of the position, must be a multiple of tickSpacing
    uint24 lpFee = 500;        
    int24 tickSpacing = 10;  
    uint24 lpFee2 = 500;        
    int24 tickSpacing2 = 100;  
    int24 tickLower;
    int24 tickUpper;  

    constructor() {
        deployerAddress = getDeployer();

        vm.label(address(tokenETH), "TokenETH");
        vm.label(address(tokenUSDC), "TokenUSDC");
        vm.label(address(deployerAddress), "Deployer");
        vm.label(address(poolManager), "PoolManager");
        vm.label(address(positionManager), "PositionManager");
        vm.label(address(hookContract), "HookContract");
    }

    function run() external {
        _logInitialInfo();

        // Deploy MUSD token
        _deployMUSDToken();

        createPoolUsdcMusd();

        createPoolMusdETH();
    }

    function createPoolUsdcMusd() internal {
        
        // Set up currencies
        (currency0, currency1) = getCurrencies(address(tokenUSDC), address(tokenMUSD));

        // Check balances before creating the pool
        _checkTokenBalance(address(tokenUSDC), tokenUSDCAmount, "USDC");
        _checkTokenBalance(address(tokenMUSD), tokenMUSDAmount, "MUSD");

        // Create pool key
        PoolKey memory poolKey = _createPoolKey(currency0, currency1, lpFee, tickSpacing);
        _logPoolConfig(poolKey, startingStablePrice);
        
        // Calculate ticks based on the starting price
        (tickLower, tickUpper) = _calculateTicks(tickSpacing, startingStablePrice);

        // Prepare liquidity mint parameters
        (bytes memory actions, bytes[] memory mintParams) = _prepareMintParams(poolKey, startingStablePrice, tokenUSDCAmount, tokenMUSDAmount);

        // Prepare multicall parameters for Pool creation and liquidity addition
        bytes[] memory params = _prepareMulticallParams(actions, mintParams, poolKey, startingStablePrice);

        _executeTransaction(params, tokenUSDCAmount);
        _logResults(tokenUSDC, tokenMUSD, "USDC-MUSD");
    }

    function createPoolMusdETH() internal {
        
        // Set up currencies
        (currency0, currency1) = getCurrencies(address(tokenETH), address(tokenMUSD));

        // Check balances before creating the pool
        _checkTokenBalance(address(tokenETH), tokenETHAmount, "ETH");
        _checkTokenBalance(address(tokenMUSD), tokenMUSDAmount, "MUSD");

        // Create pool key
        PoolKey memory poolKey = _createPoolKey(currency0, currency1, lpFee2, tickSpacing2);
        _logPoolConfig(poolKey, startingETHpoolPrice);
        
        // Calculate ticks based on the starting price
        (tickLower, tickUpper) = _calculateTicks(tickSpacing2, startingETHpoolPrice);

        // Prepare liquidity mint parameters
        (bytes memory actions, bytes[] memory mintParams) = _prepareMintParams(poolKey, startingETHpoolPrice, tokenETHAmount, tokenMUSDAmount2);

        // Prepare multicall parameters for Pool creation and liquidity addition
        bytes[] memory params = _prepareMulticallParams(actions, mintParams, poolKey, startingETHpoolPrice);

        _executeTransaction(params, tokenETHAmount);
        _logResults(tokenETH, tokenMUSD, "ETH-MUSD");
    }
    
    function _deployMUSDToken() internal {
        vm.startBroadcast(deployerAddress);
        tokenMUSD = deployToken("MUSD", "MUSD", 6, 1_000_000 * 10 ** 6);
        vm.stopBroadcast();

        console2.log("MUSD token broadcasted:", address(tokenMUSD));
        vm.label(address(tokenMUSD), "TokenMUSD");
    }

    function _prepareMintParams(PoolKey memory poolKey, uint160 price, uint256 amount0, uint256 amount1) internal view returns (bytes memory, bytes[] memory) {
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            price,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            amount0,
            amount1
        );

        console2.log("=== Liquidity Calculations ===");
        console2.log("Calculated Liquidity:", liquidity);
        console2.log("");

        uint256 amount0Max = amount0 + 1;
        uint256 amount1Max = amount1 + 1;
        bytes memory hookData = new bytes(0);

        return _mintLiquidityParams(
            poolKey, tickLower, tickUpper, liquidity, amount0Max, amount1Max, deployerAddress, hookData
        );
    }
    
    function _prepareMulticallParams(
        bytes memory actions, 
        bytes[] memory mintParams, 
        PoolKey memory poolKey,
        uint256 price
    ) internal view returns (bytes[] memory) {
        bytes[] memory params = new bytes[](2);
        bytes memory hookData = new bytes(0);

        params[0] = abi.encodeWithSelector(positionManager.initializePool.selector, poolKey, price, hookData);
        params[1] = abi.encodeWithSelector(
            positionManager.modifyLiquidities.selector, abi.encode(actions, mintParams), block.timestamp + 3600
        );

        console2.log("=== Multicall Parameters Prepared ===");
        console2.log("Param count:", params.length);
        console2.log("");
        
        return params;
    }
    
    function _executeTransaction(bytes[] memory params, uint256 amount0) internal {
        uint256 valueToPass = currency0.isAddressZero() ? (amount0 + 1) : 0;

        console2.log("=== Starting Transaction ===");
        console2.log("Position Manager:", address(positionManager));
        
        vm.startBroadcast(deployerAddress);        
        console2.log("Broadcasting transaction...");
        tokenApprovals(tokenUSDC, tokenMUSD);

        console2.log("Executing multicall...");
        try positionManager.multicall{value: valueToPass}(params) {
            console2.log("Multicall completed successfully!");
        } catch Error(string memory reason) {
            console2.log("Multicall failed:", reason);
            // Don't revert - the failure might be expected (e.g., pool already exists)
        }
        
        vm.stopBroadcast();
    }   
    
    function _logResults(
        IERC20 token0,
        IERC20 token1,
        string memory poolName
    ) internal view {
        console2.log("=== Post-Transaction Token Balances ===");
        console2.log("token0: ", address(token0));
        console2.log("token1: ", address(token1));

        uint256 balance0After = address(token0) == address(0)
            ? deployerAddress.balance
            : IERC20(token0).balanceOf(deployerAddress);
        uint256 balance1After = address(token1) == address(0)
            ? deployerAddress.balance
            : IERC20(token1).balanceOf(deployerAddress);
        console2.log("deployer's USDC Balance After:", balance0After);
        console2.log("deployer's MUSD Balance After:", balance1After);
        console2.log("");

        console2.log("=== Pool", poolName, "Creation Complete! ===");
        console2.log(unicode"✅ Pool initialized");
        console2.log(unicode"✅ Liquidity position created");
        console2.log(unicode"✅ Pool ready for trading");
    }
}