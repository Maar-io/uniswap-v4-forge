// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

import {IUniswapV4Router04} from "hookmate/interfaces/router/IUniswapV4Router04.sol";
import {AddressConstants} from "hookmate/constants/AddressConstants.sol";

/// @notice Shared configuration between scripts
contract BaseScript is Script {
    IPermit2 immutable permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IPoolManager immutable poolManager;
    IPositionManager immutable positionManager;
    IUniswapV4Router04 immutable swapRouter;
    address immutable deployerAddress;

    /////////////////////////////////////
    // --- Configure These ---
    /////////////////////////////////////
    // IERC20 internal constant token0 = IERC20(0x036CbD53842c5426634e7929541eC2318f3dCF7e); // USDC on Base Sepolia
    // IERC20 internal constant token1 = IERC20(0x5f6D35D1Add891416969194709ddd374B6D26253); // MUSD on Base Sepolia
    /////////////////////////////////////
    // IERC20 internal constant token0 = IERC20(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238); // USDC on Sepolia
    // IERC20 internal constant token1 = IERC20(0x65675DCB0558030eaE5fc3E42a41df576cc437Ef); // MUSD on Sepolia

    IERC20 internal constant token0 = IERC20(0x0000000000000000000000000000000000000000); // ETH
    IERC20 internal constant token1 = IERC20(0x65675DCB0558030eaE5fc3E42a41df576cc437Ef); // MUSD on Sepolia

    IHooks constant hookContract = IHooks(address(0));
    /////////////////////////////////////

    Currency immutable currency0;
    Currency immutable currency1;
    uint24 lpFee = 500;        
    int24 tickSpacing = 100;     

    constructor() {
        // Use hookmate for Pool Manager and Position Manager (these work)
        poolManager = IPoolManager(AddressConstants.getPoolManagerAddress(block.chainid));
        positionManager = IPositionManager(payable(AddressConstants.getPositionManagerAddress(block.chainid)));
        
        // Handle swap router with fallback for Base Sepolia
        address swapRouterAddr;

        if (block.chainid == 84532) {
            // Base Sepolia - use hardcoded address since hookmate doesn't support it
            swapRouterAddr = 0x492E6456D9528771018DeB9E87ef7750EF184104;
        } else {
            // For other chains, try hookmate
            swapRouterAddr = AddressConstants.getV4SwapRouterAddress(block.chainid);
        }
        swapRouter = IUniswapV4Router04(payable(swapRouterAddr));

        deployerAddress = getDeployer();

        (currency0, currency1) = getCurrencies();

        vm.label(address(token0), "Token0");
        vm.label(address(token1), "Token1");

        vm.label(address(deployerAddress), "Deployer");
        vm.label(address(poolManager), "PoolManager");
        vm.label(address(positionManager), "PositionManager");
        vm.label(address(swapRouter), "SwapRouter");
        vm.label(address(hookContract), "HookContract");
    }

    function getCurrencies() public pure returns (Currency, Currency) {
        require(address(token0) != address(token1));

        if (token0 < token1) {
            return (Currency.wrap(address(token0)), Currency.wrap(address(token1)));
        } else {
            return (Currency.wrap(address(token1)), Currency.wrap(address(token0)));
        }
    }

    function getDeployer() public returns (address) {
        address[] memory wallets = vm.getWallets();

        require(wallets.length > 0, "No wallets found");
        console.log("Using Deployer wallet: %s", wallets[0]);

        return wallets[0];  
    }
}