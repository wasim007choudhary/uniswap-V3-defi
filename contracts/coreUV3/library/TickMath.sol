// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @notice must visit: `notes/CoreLibFunctions/TickMath` to fully graps as everything is dissected and reverse enginnered, and with reports with optimizzations too proivided
 */
library TickMath {
    /**
     * @notice Thrown when a tick is outside the maximum range supported by the protocol.
     *
     * @dev
     * TickMath only supports ticks from:
     *
     *     -887272
     *
     * up to:
     *
     *      887272
     *
     * Anything outside this range cannot be converted by this function.
     */
    error TickMath___getSqrtPriceRatioAtTick__TickOutOfMaxBoundSetByTheProtocol();

    /**
     * @notice The smallest tick supported by this TickMath implementation.
     *
     * @dev
     * This is the lower end of the valid tick range.
     *
     *     MIN_VALID_TICK = -887272
     *
     * A tick smaller than this is not supported by the protocol's
     * TickMath price range.
     */
    int24 internal constant MIN_VALID_TICK = -887272;

    /**
     * @notice The largest tick supported by this TickMath implementation.
     *
     * @dev
     * This is the upper end of the valid tick range.
     *
     * It is the opposite of MIN_VALID_TICK:
     *
     *     MAX_VALID_TICK = -MIN_VALID_TICK
     *
     * Therefore:
     *
     *     MIN_VALID_TICK = -887272
     *     MAX_VALID_TICK =  887272
     */
    int24 internal constant MAX_VALID_TICK = -MIN_VALID_TICK;

    /**
     * @notice The smallest supported square-root price, encoded as Q64.96.
     *
     * @dev
     * This is the sqrt-price produced by MIN_VALID_TICK.
     *
     * The mathematical value is:
     *
     *     sqrt(1.0001 ^ MIN_VALID_TICK)
     *
     * But the value stored on-chain is its Q64.96 encoding:
     *
     *     sqrtPriceX96 = sqrt(1.0001 ^ MIN_VALID_TICK) * 2^96
     *
     * In simple words:
     * this is the lowest sqrt-price that this TickMath implementation supports.
     */
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    /**
     * @notice The largest supported square-root price, encoded as Q64.96.
     *
     * @dev
     * This is the sqrt-price produced by MAX_VALID_TICK.
     *
     * The mathematical value is:
     *
     *     sqrt(1.0001 ^ MAX_VALID_TICK)
     *
     * and the stored Q64.96 value is:
     *
     *     sqrtPriceX96 = sqrt(1.0001 ^ MAX_VALID_TICK) * 2^96
     *
     * In simple words:
     * this is the highest sqrt-price that this TickMath implementation supports.
     */
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /**
     * @notice Converts a tick into its corresponding square-root price.
     *
     * @dev
     * A tick represents price using:
     *
     *     price = 1.0001 ^ tick
     *
     * The function needs the square root of that price:
     *
     *     sqrtPrice = sqrt(1.0001 ^ tick)
     *
     * The result is returned in Q64.96 form:
     *
     *     sqrtPriceX96 = sqrt(1.0001 ^ tick) * 2^96
     *
     * The calculation is done in several simple steps:
     *
     * 1. Take the absolute value of the tick.
     *
     *    Example:
     *
     *        -13 -> 13
     *         13 -> 13
     *
     *    We do this because the calculation below only needs to know
     *    which powers of two make up the tick's magnitude.
     *
     * 2. Check that the tick is inside the allowed range.
     *
     *    Since:
     *
     *        absTick = |tick|
     *
     *    checking:
     *
     *        absTick <= MAX_VALID_TICK
     *
     *    is enough to enforce both:
     *
     *        -887272 <= tick <= 887272
     *
     * 3. Break absTick into powers of two using its binary bits.
     *
     *    For example:
     *
     *        13 = 8 + 4 + 1
     *
     *    which means:
     *
     *        bit 3 = 1
     *        bit 2 = 1
     *        bit 1 = 0
     *        bit 0 = 1
     *
     *    Each set bit tells us which precomputed factor we need.
     *
     * 4. Multiply the matching precomputed factors.
     *
     *    These factors represent:
     *
     *        1 / sqrt(1.0001 ^ (2^i))
     *
     *    They are stored as Q128.128 encoded integers.
     *
     * 5. After every multiplication, shift right by 128 bits.
     *
     *    Two Q128.128 values contain two 2^128 scaling factors.
     *
     *        2^128 * 2^128 = 2^256
     *
     *    Shifting right by 128 removes one of those scale factors
     *    and brings the result back to Q128.128 scaling.
     *
     * 6. After all selected factors are multiplied, the result represents:
     *
     *        1 / sqrt(1.0001 ^ absTick)
     *
     * 7. If the original tick is positive, flip that reciprocal so that
     *    we get the required positive-tick square-root price:
     *
     *        sqrt(1.0001 ^ tick)
     *
     * 8. Finally, convert the Q128.128 result into the Q64.96 result
     *    expected by the rest of Uniswap V3.
     *
     *    The shift is:
     *
     *        >> 32
     *
     *    because:
     *
     *        2^128 / 2^32 = 2^96
     *
     *    so the fixed-point scale changes from 2^128 to 2^96.
     *
     * @param tick The tick whose square-root price should be calculated.
     *
     * @return sqrtPriceX96OfTheTick The square-root price for the tick,
     *         encoded as a Q64.96 uint160 value.
     *
     *
     * @custom:dissection For complete line-by-line dissection and reverse-engineering of the function, visit:
     *      `notes/CoreLibFunctions/TickMath/3.getSqrtPriceRatioAtTick_Fun.md`
     */
    function getSqrtPriceRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96OfTheTick) {
        /**
         * @dev
         * Get the absolute value of the tick.
         *
         * This removes the negative sign if the tick is negative.
         *
         * Example:
         *
         *     tick = -7 -> absTick = 7
         *     tick =  7 -> absTick = 7
         *
         * Think of it as:
         *
         *     tick    = which side of zero?
         *     absTick = how far from zero?
         *
         * We keep the original `tick` unchanged because its sign
         * is needed later.
         */
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));

        /**
         * @dev
         * Make sure the tick is inside the protocol's supported range.
         *
         * Because:
         *
         *     absTick = |tick|
         *
         * this one comparison represents:
         *
         *     -887272 <= tick <= 887272
         *
         * If the tick is too far from zero, the function reverts.
         */
        if (absTick > uint256(int256(MAX_VALID_TICK))) {
            revert TickMath___getSqrtPriceRatioAtTick__TickOutOfMaxBoundSetByTheProtocol();
        }

        /**
         * @dev
         * Create the starting Q128.128 ratio.
         *
         * We first check bit index 0:
         *
         *     0x1 = 1 = 2^0
         *
         * So this asks:
         *
         *     "Is the 1-component present in absTick?"
         *
         * If the bit is set, we use the precomputed factor:
         *
         *     1 / sqrt(1.0001^1)
         *
         * encoded as:
         *340265354078545014477014422800776036353
         *     (1 / sqrt(1.0001)) * 2^128 which gives after rounding down Decimal = 340265354078545014477014422800776036353 and in hex 0xfffcb933bd6fad37aa2d162d1a594001
         *
         * The large hexadecimal number is simply that already-calculated
         * value written as an integer in hexadecimal.
         *
         * If the bit is not set, we start with:
         *
         *     2^128
         *
         * which is the Q128.128 encoding of the mathematical value 1:
         *
         *     1 * 2^128 = 2^128
         *
         * So:
         *
         *     bit 0 = 1 -> use the first factor
         *     bit 0 = 0 -> use the neutral factor 1
         *
         * `ratio` is still a uint256 variable.
         * Q128.128 describes how the integer is interpreted,
         * not the Solidity bit-width of the variable.
         */
        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;

        /**
         * @dev
         * Check bit index 1.
         *
         *     0x2 = 2 = 2^1
         *
         * If this bit is 1, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^2) * 2^128
         */
        if (absTick & 0x2 != 0) {
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        }

        /**
         * @dev
         * Check bit index 2.
         *
         *     0x4 = 4 = 2^2
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^4) * 2^128
         */
        if (absTick & 0x4 != 0) {
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        }

        /**
         * @dev
         * Check bit index 3.
         *
         *     0x8 = 8 = 2^3
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^8) * 2^128
         */
        if (absTick & 0x8 != 0) {
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        }

        /**
         * @dev
         * Check bit index 4.
         *
         *     0x10 = 16 = 2^4
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^16) * 2^128
         */
        if (absTick & 0x10 != 0) {
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        }

        /**
         * @dev
         * Check bit index 5.
         *
         *     0x20 = 32 = 2^5
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^32) * 2^128
         */
        if (absTick & 0x20 != 0) {
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        }

        /**
         * @dev
         * Check bit index 6.
         *
         *     0x40 = 64 = 2^6
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^64) * 2^128
         */
        if (absTick & 0x40 != 0) {
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        }

        /**
         * @dev
         * Check bit index 7.
         *
         *     0x80 = 128 = 2^7
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^128) * 2^128
         */
        if (absTick & 0x80 != 0) {
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        }

        /**
         * @dev
         * Check bit index 8.
         *
         *     0x100 = 256 = 2^8
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^256) * 2^128
         */
        if (absTick & 0x100 != 0) {
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        }

        /**
         * @dev
         * Check bit index 9.
         *
         *     0x200 = 512 = 2^9
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^512) * 2^128
         */
        if (absTick & 0x200 != 0) {
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        }

        /**
         * @dev
         * Check bit index 10.
         *
         *     0x400 = 1024 = 2^10
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^1024) * 2^128
         */
        if (absTick & 0x400 != 0) {
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        }

        /**
         * @dev
         * Check bit index 11.
         *
         *     0x800 = 2048 = 2^11
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^2048) * 2^128
         */
        if (absTick & 0x800 != 0) {
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        }

        /**
         * @dev
         * Check bit index 12.
         *
         *     0x1000 = 4096 = 2^12
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^4096) * 2^128
         */
        if (absTick & 0x1000 != 0) {
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        }

        /**
         * @dev
         * Check bit index 13.
         *
         *     0x2000 = 8192 = 2^13
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^8192) * 2^128
         */
        if (absTick & 0x2000 != 0) {
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        }

        /**
         * @dev
         * Check bit index 14.
         *
         *     0x4000 = 16384 = 2^14
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^16384) * 2^128
         */
        if (absTick & 0x4000 != 0) {
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        }

        /**
         * @dev
         * Check bit index 15.
         *
         *     0x8000 = 32768 = 2^15
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^32768) * 2^128
         */
        if (absTick & 0x8000 != 0) {
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        }

        /**
         * @dev
         * Check bit index 16.
         *
         *     0x10000 = 65536 = 2^16
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^65536) * 2^128
         */
        if (absTick & 0x10000 != 0) {
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        }

        /**
         * @dev
         * Check bit index 17.
         *
         *     0x20000 = 131072 = 2^17
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^131072) * 2^128
         */
        if (absTick & 0x20000 != 0) {
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        }

        /**
         * @dev
         * Check bit index 18.
         *
         *     0x40000 = 262144 = 2^18
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^262144) * 2^128
         */
        if (absTick & 0x40000 != 0) {
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        }

        /**
         * @dev
         * Check bit index 19.
         *
         *     0x80000 = 524288 = 2^19
         *
         * If set, multiply ratio by the precomputed encoded factor for:
         *
         *     1 / sqrt(1.0001^524288) * 2^128
         */
        if (absTick & 0x80000 != 0) {
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;
        }

        /**
         * @dev
         * At this point we have built the reciprocal form:
         *
         *     1 / sqrt(1.0001^absTick)
         *
         * using the factors for every power of two that was present
         * in absTick.
         *
         * Remember:
         *
         *     negative tick -> reciprocal is already what we need
         *
         *     positive tick -> we need to flip the reciprocal
         *
         * For a positive tick, divide uint256 max by `ratio` to perform
         * the scaled reciprocal operation and obtain the positive form.
         */
        if (tick > 0) {
            ratio = type(uint256).max / ratio;
        }

        /**
         * @dev
         * Convert the Q128.128 ratio into the Q64.96 sqrt-price format.
         *
         * `ratio` is currently scaled by 2^128.
         *
         * We want the final value scaled by 2^96.
         *
         * Therefore we remove:
         *
         *     128 - 96 = 32
         *
         * bits of scaling:
         *
         *     ratio >> 32
         *
         * The lowest 32 bits are discarded by the shift.
         *
         * Before throwing those bits away, we check whether any of them
         * contained a value.
         *
         * If all 32 discarded bits were zero, the conversion was exact,
         * so we add nothing.
         *
         * If any discarded bit was non-zero, the original value had some
         * fractional remainder, so we add 1.
         *
         * This is equivalent to rounding the converted value upward:
         *
         *     ceil(ratio / 2^32)
         *
         * Finally, the value is stored as uint160 because the resulting
         * square-root price uses Q64.96 representation and fits within
         * 160 bits.
         */
        sqrtPriceX96OfTheTick = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }
}
