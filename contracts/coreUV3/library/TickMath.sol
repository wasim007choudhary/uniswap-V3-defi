// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library TickMath {
    error TickMath___getSqrtPriceRatioAtTick__TickOutOfMaxBoundSetByTheProtocol();

    int24 internal constant MIN_VALID_TICK = -887272; // min tick limit or uniswap limit no more tick beyond that and also the last initlizable tick which can be converted or priceroot can be taken from
    int24 internal constant MAX_VALID_TICK = -MIN_VALID_TICK; //same shit but it is for maximumn limit

    uint160 internal constant MIN_SQRT_RATIO = 4295128739; // the minimum v3 suported sqrtPrice here supported..or basically is the sqrtPrice of MIN_VALID_TICK. It is * 2^96 encided value tho here
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342; // same thing but relating to the  Max part.GGs easy!

    /// basisially does say sqrt(1.0001 ^ tick) * 2^96 OR << 96 same thing
    function getSqrtPriceRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96OfTheTick) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick)); // r4moves the neagtive sign or whatsoevr..it only looks at the number iykwim!..if psotive then ok..if neative then remove thaty sign , hence absTick i.e abosuluteTick
        if (
            absTick <= MAX_SQRT_RATIO //ase abs will always be uint256 because of the above shit, we dont need to worry about the shit as max here = min as we removed that thing {
        ) {
            revert TickMath___getSqrtPriceRatioAtTick__TickOutOfMaxBoundSetByTheProtocol();
        }

        /*absTick & 0x1 != 0

        meaning bit index 0 is 1, and bit index 0 corresponds to:

         2^0=1

        Therefore the algorithm needs the precomputed factor for exponent 1.

        Let's see the actual number

        Mathematically:

        1/sqrt1.0001 = approx 0.9999500037496875... $$

        Because ratio is Q128.128, Uniswap encodes it by multiplying by:

        $$ 2^{128} $$

        So:

        $$ 0.9999500037496875... x 2^{128} $$

        produces approximately:

         340265354078544963557816517032075149313

        which in hexadecimal is:

        0xfffcb933bd6fad37aa2d162d1a594001

        So this giant hex number is just the encoded version of that mathematical factor.
        It is precalculated and used as factors when multiplying to rach the sqrtPrice of a given tick*/
        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
    }
}

