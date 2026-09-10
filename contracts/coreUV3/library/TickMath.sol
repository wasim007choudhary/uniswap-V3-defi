// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library TickMath {
    int24 internal constant MIN_VALID_TICK = -887272; // min tick limit or uniswap limit no more tick beyond that and also the last initlizable tick which can be converted or priceroot can be taken from
    int24 internal constant MAX_VALID_TICK = -MIN_VALID_TICK; //same shit but it is for maximumn limit

    uint160 internal constant MIN_SQRT_RATIO = 4295128739; // the minimum v3 suported sqrtPrice here supported..or basically is the sqrtPrice of MIN_VALID_TICK
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342; // same thing but for the Max part.GGs easy!

    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96OfTheTick) {}
}
