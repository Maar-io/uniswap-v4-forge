// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";

import {BaseScript} from "./base/BaseScript.s.sol";

contract SwapScript is BaseScript {
    using CurrencyLibrary for Currency;

    function run() external {
        console2.log("=== Starting MUSD to USDC Swap ===");
        console2.log("Deployer Address:", deployerAddress);
        console2.log("");

        // Check balances BEFORE swap
        console2.log("=== BEFORE SWAP ===");
        uint256 usdcBalanceBefore = IERC20(Currency.unwrap(currency0)).balanceOf(deployerAddress);
        uint256 musdBalanceBefore = IERC20(Currency.unwrap(currency1)).balanceOf(deployerAddress);
        console2.log("USDC Balance Before:", usdcBalanceBefore);
        console2.log("MUSD Balance Before:", musdBalanceBefore);
        console2.log("Has enough MUSD (1e18)?", musdBalanceBefore >= 1e18);
        console2.log("");

        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: hookContract
        });
        bytes memory hookData = new bytes(0);

        console2.log("=== SWAP CONFIGURATION ===");
        console2.log("Amount In (MUSD): 1e18");
        console2.log("Min Amount Out (USDC): 0");
        console2.log("Zero for One:", false);
        console2.log("Pool Fee:", lpFee);
        console2.log("");

        vm.startBroadcast();

        console2.log("Setting token approvals...");
        // We'll approve both, just for testing.
        token1.approve(address(swapRouter), type(uint256).max);
        token0.approve(address(swapRouter), type(uint256).max);
        console2.log("Approvals set");

        console2.log("Executing swap...");
        // Execute swap
        swapRouter.swapExactTokensForTokens({
            amountIn: 1e18,
            amountOutMin: 0, // 0.95 USDC minimum (6 decimals)
            zeroForOne: false, // false: MUSD (currency1) → USDC (currency0)
            poolKey: poolKey,
            hookData: hookData,
            receiver: deployerAddress, // Changed from address(this) to deployerAddress
            deadline: block.timestamp + 3600 // Changed from +1 to +3600 for safety
        });
        console2.log("Swap completed!");

        vm.stopBroadcast();

        // Check balances AFTER swap
        console2.log("=== AFTER SWAP ===");
        uint256 usdcBalanceAfter = IERC20(Currency.unwrap(currency0)).balanceOf(deployerAddress);
        uint256 musdBalanceAfter = IERC20(Currency.unwrap(currency1)).balanceOf(deployerAddress);
        console2.log("USDC Balance After:", usdcBalanceAfter);
        console2.log("MUSD Balance After:", musdBalanceAfter);
        console2.log("");

        // Calculate actual swap amounts
        uint256 usdcReceived = usdcBalanceAfter - usdcBalanceBefore;
        uint256 musdUsed = musdBalanceBefore - musdBalanceAfter;

        console2.log("=== SWAP RESULTS ===");
        console2.log("MUSD Used:", musdUsed);
        console2.log("USDC Received:", usdcReceived);
        console2.log("");

        // Conclusion
        console2.log("=== CONCLUSION ===");
        if (musdUsed == 1e18) {
            console2.log(unicode"✅ Correct amount of MUSD used (1.0)");
        } else {
            console2.log(unicode"❌ Unexpected MUSD amount used");
        }

        if (usdcReceived >= 0.95e6) {
            console2.log(unicode"✅ Received acceptable USDC amount (>= 0.95)");
        } else {
            console2.log(unicode"❌ Received less USDC than minimum");
        }

        if (usdcReceived > 0 && musdUsed > 0) {
            uint256 effectivePrice = (usdcReceived * 1e18) / musdUsed;
            console2.log("Effective Price (USDC per MUSD):", effectivePrice);
            console2.log(unicode"✅ SWAP SUCCESSFUL!");
        } else {
            console2.log(unicode"❌ SWAP FAILED - No tokens exchanged");
        }

        console2.log("=== END ===");
    }
}