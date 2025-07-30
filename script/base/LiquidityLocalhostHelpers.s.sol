// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console2} from "forge-std/Script.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";

import {BaseLocalhostScript} from "./BaseLocalhostScript.s.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {LocalAddresses} from "./localAddresses.s.sol";

contract LiquidityLocalhostHelpers is LocalAddresses{
    using CurrencyLibrary for Currency;

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
            uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR), uint8(Actions.SWEEP), uint8(Actions.SWEEP)
        );

        bytes[] memory params = new bytes[](4);
        params[0] = abi.encode(poolKey, _tickLower, _tickUpper, liquidity, amount0Max, amount1Max, recipient, hookData);
        params[1] = abi.encode(poolKey.currency0, poolKey.currency1);
        params[2] = abi.encode(poolKey.currency0, recipient);
        params[3] = abi.encode(poolKey.currency1, recipient);

        return (actions, params);
    }

    function tokenApprovals(IERC20 token0, IERC20 token1) public {
        // Only approve ERC20 tokens, skip native ETH (address(0))
        if (address(token0) != address(0)) {
            token0.approve(address(permit2), type(uint256).max);
            permit2.approve(address(token0), address(positionManager), type(uint160).max, type(uint48).max);
        }

        if (address(token1) != address(0)) {
            token1.approve(address(permit2), type(uint256).max);
            permit2.approve(address(token1), address(positionManager), type(uint160).max, type(uint48).max);
        }

        console2.log("Token approvals completed");
    }
}