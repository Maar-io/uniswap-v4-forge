// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {LocalAddresses} from "./localAddresses.s.sol";

import {MyToken} from "../../src/MyToken.sol";

/// @notice Shared configuration between scripts
contract BaseLocalhostScript is Script, LocalAddresses {
    IERC20 internal tokenMUSD;
    Currency internal currency0;
    Currency internal currency1;

    constructor() {
        deployerAddress = getDeployer();

        vm.label(address(tokenETH), "TokenETH");
        vm.label(address(tokenUSDC), "TokenUSDC");
        vm.label(address(tokenMUSD), "TokenMUSD");
        vm.label(address(deployerAddress), "Deployer");
        vm.label(address(poolManager), "PoolManager");
        vm.label(address(positionManager), "PositionManager");
        vm.label(address(hookContract), "HookContract");
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
