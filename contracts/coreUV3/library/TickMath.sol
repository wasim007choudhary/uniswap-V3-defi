// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library TickMath {
    int24 internal constant MIN_VALID_TICK = -887272; // min tick limit or uniswap limit no more tick beyond that and also the last initlizable tick which can be converted or priceroot can be taken from
    int24 internal constant MAX_VALID_TICK = -MIN_VALID_TICK; //same shit but it is for maximumn limit
}
