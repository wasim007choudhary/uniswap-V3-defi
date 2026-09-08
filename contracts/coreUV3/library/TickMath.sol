// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library TickMath {
    int24 internal constant MIN_VALID_TICK = -887272;
    int24 internal constant MAX_VALID_TICK = -MIN_VALID_TICK;
}
