// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {

    uint8 private myDecimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 initialAmount
    ) ERC20(name, symbol) {
        myDecimals = decimals_;
        _mint(msg.sender, initialAmount * 10 ** decimals_);
    }

    function mint(address to, uint256 amount) public{
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return myDecimals;
    }
}
