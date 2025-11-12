// SPDX-License-Identifier: MIT
// @dev This contract has been adapted to fit with foundry
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ERC677Receiver {
    function onTokenTransfer(
        address _sender,
        uint256 _value,
        bytes calldata _data
    ) external;
}

contract LinkToken is ERC20 {}
