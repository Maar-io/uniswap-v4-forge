// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";

import {BaseScript} from "./base/BaseScript.s.sol";

interface IPoolManager {
    struct SwapParams {
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
    }
}

struct TestSettings {
    bool takeClaims;
    bool settleUsingBurn;
}

interface IPoolSwapTest {
    function swap(
        PoolKey memory key,
        IPoolManager.SwapParams memory params,
        TestSettings memory testSettings,
        bytes memory hookData
    ) external payable returns (int256 delta);
}

contract SwapScript is BaseScript {
    using CurrencyLibrary for Currency;

    function run() external {
        console2.log("=== Starting MUSD to USDC Swap (PoolSwapTest) ===");
        console2.log("Deployer Address:", deployerAddress);
        address poolSwapTest = 0x8B5bcC363ddE2614281aD875bad385E0A785D3B9;
        console2.log("PoolSwapTest:", poolSwapTest);
        console2.log("");

        // Check balances BEFORE swap
        console2.log("=== BEFORE SWAP ===");
        uint256 usdcBalanceBefore = IERC20(Currency.unwrap(currency0)).balanceOf(deployerAddress);
        uint256 musdBalanceBefore = IERC20(Currency.unwrap(currency1)).balanceOf(deployerAddress);
        console2.log("USDC Balance Before:", usdcBalanceBefore);
        console2.log("MUSD Balance Before:", musdBalanceBefore);
        console2.log("Has enough MUSD (1e6)?", musdBalanceBefore >= 1e6);
        // Check MUSD allowance for PoolSwapTest
        uint256 musdAllowance = IERC20(Currency.unwrap(currency1)).allowance(deployerAddress, poolSwapTest);
        console2.log("MUSD Allowance for PoolSwapTest:", musdAllowance);
        console2.log("");

        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: hookContract
        });

        // Approve PoolSwapTest to spend MUSD (input token)
        console2.log("Setting token approval for PoolSwapTest...");
        token1.approve(poolSwapTest, type(uint256).max);
        console2.log("Approval set");

        // Prepare swap params and test settings
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: false, // MUSD -> USDC
            amountSpecified: int256(1e5),
            sqrtPriceLimitX96: 0 // no price limit
        });
        TestSettings memory testSettings = TestSettings({
            takeClaims: false,
            settleUsingBurn: false
        });
        bytes memory hookData = new bytes(0);

        // Swap: MUSD (currency1) -> USDC (currency0)
        console2.log("Executing PoolSwapTest swap...");
        int256 delta = IPoolSwapTest(poolSwapTest).swap(
            poolKey,
            params,
            testSettings,
            hookData
        );
        console2.log("Swap completed! Delta:", delta);

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
        if (musdUsed == 1e6) {
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