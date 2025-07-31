// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {LocalAddresses} from "./LocalAddresses.s.sol";
import {MyToken} from "../../src/MyToken.sol";

contract LocalhostHelpers is Script, LocalAddresses {
    using CurrencyLibrary for Currency;

    // constructor() {
    //     deployerAddress = getDeployer();
    // }

    function _mintLiquidityParams(
        PoolKey memory poolKey,
        int24 _tickLower,
        int24 _tickUpper,
        uint256 liquidity,
        uint256 amount0Max,
        uint256 amount1Max,
        address recipient,
        bytes memory hookData
    ) internal pure returns (bytes memory, bytes[] memory) {
        bytes memory actions = abi.encodePacked(
            uint8(Actions.MINT_POSITION),
            uint8(Actions.SETTLE_PAIR),
            uint8(Actions.SWEEP),
            uint8(Actions.SWEEP)
        );

        bytes[] memory params = new bytes[](4);
        params[0] = abi.encode(
            poolKey,
            _tickLower,
            _tickUpper,
            liquidity,
            amount0Max,
            amount1Max,
            recipient,
            hookData
        );
        params[1] = abi.encode(poolKey.currency0, poolKey.currency1);
        params[2] = abi.encode(poolKey.currency0, recipient);
        params[3] = abi.encode(poolKey.currency1, recipient);

        return (actions, params);
    }

    function tokenApprovals(IERC20 token0, IERC20 token1) public {
        // Only approve ERC20 tokens, skip native ETH (address(0))
        if (address(token0) != address(0)) {
            token0.approve(address(permit2), type(uint256).max);
            permit2.approve(
                address(token0),
                address(positionManager),
                type(uint160).max,
                type(uint48).max
            );
        }

        if (address(token1) != address(0)) {
            token1.approve(address(permit2), type(uint256).max);
            permit2.approve(
                address(token1),
                address(positionManager),
                type(uint160).max,
                type(uint48).max
            );
        }

        console2.log("Token approvals completed");
    }

    function _logInitialInfo() internal view {
        console2.log("=== Starting Pool Creation and Liquidity Addition ===");
        console2.log("Chain ID:", block.chainid);
        console2.log("Deployer Address:", deployerAddress);
        console2.log("");
    }

    function _checkTokenBalance(
        address token,
        uint256 amount,
        string memory name
    ) internal view {
        uint256 balance = IERC20(token).balanceOf(deployerAddress);

        console2.log(name, "Balance:", balance);
        console2.log("Deployer has enough ", name, "? : ", balance >= amount);
        console2.log("");
    }

    function _createPoolKey(Currency currency0, Currency currency1, uint24 fee, int24 spacing) internal pure returns (PoolKey memory) {
        return
            PoolKey({
                currency0: currency0,
                currency1: currency1,
                fee: fee,
                tickSpacing: spacing,
                hooks: hookContract
            });
    }

    function _logPoolConfig(PoolKey memory poolKey, uint160 price) internal pure {
        console2.log("=== Pool Configuration ===");
        console2.log("Fee:", poolKey.fee);
        console2.log("Tick Spacing:", uint256(int256(poolKey.tickSpacing)));
        console2.log("Starting Price (sqrtPriceX96):", price);
        console2.log("Hooks Contract:", address(poolKey.hooks));
        console2.log("");
    }

    function _calculateTicks(int24 spacing, uint160 startPrice) internal pure returns (int24, int24) {
        int24 currentTick = TickMath.getTickAtSqrtPrice(startPrice);
        console2.log("=== Tick Calculations ===");
        console2.log(
            "Current Tick (from starting price):",
            int256(currentTick)
        );

        int24 tickL =
            ((currentTick - 5000 * spacing) / spacing) *
            spacing;
        int24 tickU =
            ((currentTick + 5000 * spacing) / spacing) *
            spacing;

        console2.log("Tick Lower:", int256(tickL));
        console2.log("Tick Upper:", int256(tickU));
        console2.log("Tick Range:", int256(tickU - tickL));
        console2.log("");
        return (tickL, tickU);

    }

    function deployToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 mintAmount
    ) public returns (IERC20) {
        MyToken token = new MyToken(name, symbol, decimals, mintAmount);
        console2.log("Token contract deployed at:", address(token));
        return IERC20(address(token));
    }

    function getCurrencies(
        address token0,
        address token1
    ) public pure returns (Currency, Currency) {
        require(address(token0) != address(token1));

        if (token0 < token1) {
            return (
                Currency.wrap(address(token0)),
                Currency.wrap(address(token1))
            );
        } else {
            return (
                Currency.wrap(address(token1)),
                Currency.wrap(address(token0))
            );
        }
    }

    // function getDeployer() public returns (address) {
    //     address[] memory wallets = vm.getWallets();

    //     require(wallets.length > 0, "No wallets found");
    //     console.log("Using Deployer wallet: %s", wallets[0]);

    //     return wallets[0];
    // }

    function getDeployer() public pure returns (address) {
        return 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Anvil account[0]
    }
}
