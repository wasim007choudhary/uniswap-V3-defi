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
    error TickMath___getTickAtSqrtPriceRatio__SqrtRootPriceRatioOutOfBounds();

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

    /**
     * @dev
     * Find the tick that belongs to a given square-root price.
     *
     * We are doing the reverse of `getSqrtPriceRatioAtTick()`.
     *
     * That function does:
     *
     *     tick -> square-root price
     *
     * This function does:
     *
     *     square-root price -> tick
     *
     * The big idea is:
     *
     *     sqrtPriceRatio
     *          ↓
     *       make ratio
     *          ↓
     *     find biggest bit
     *          ↓
     *       normalize
     *          ↓
     *       find log2
     *          ↓
     *   convert log to tick system
     *          ↓
     *    get two tick guesses
     *          ↓
     *      check the guess
     *          ↓
     *       final tick
     *
     *
     * @custom:dissection For complete line-by-line dissection and reverse-engineering of the function, visit:
     *      `notes/CoreLibFunctions/TickMath/4.getTickAtSqrtPriceRatio_Fun.md`
     */

    function getTickAtSqrtPriceRatio(uint160 sqrtPriceRatio) internal pure returns (int24 tick) {
        /**
         * @dev
         * Make sure the square-root price is inside the allowed range.
         *
         * The function only works when:
         *
         *     sqrtPriceRatio >= MIN_SQRT_RATIO
         *     sqrtPriceRatio <  MAX_SQRT_RATIO
         *
         * If the price is too small or too large, we stop immediately.
         */
        if (sqrtPriceRatio < MIN_SQRT_RATIO || sqrtPriceRatio >= MAX_SQRT_RATIO) {
            revert TickMath___getTickAtSqrtPriceRatio__SqrtRootPriceRatioOutOfBounds();
        }

        /**
         * @dev
         * Convert the Q64.96 square-root price into a Q128.128 value.
         *
         * The input is stored like this:
         *
         *     sqrtPriceRatio = sqrt(P) * 2^96
         *
         * We shift left by 32 bits:
         *
         *     sqrtPriceRatio << 32
         *
         * which means:
         *
         *     sqrt(P) * 2^96 * 2^32
         *
         *     = sqrt(P) * 2^128
         *
         * So we change:
         *
         *     Q64.96 -> Q128.128
         *
         * Why?
         *
         * Because the logarithm calculation that comes next needs this
         * larger scaling.
         */
        uint256 ratio = uint256(sqrtPriceRatio) << 32;

        /**
         * @dev
         * Make a working copy of `ratio`.
         *
         * We are going to change `r` many times while searching for the
         * most significant bit and calculating the logarithm.
         *
         * We keep `ratio` unchanged because we need the original value
         * later when we normalize the number.
         */
        uint256 r = ratio;

        /**
         * @dev
         * Store the position of the most significant bit.
         *
         * The most significant bit means:
         *
         *     "Where is the highest 1-bit?"
         *
         * Example:
         *
         *     13 = 1101
         *
         * The bits are:
         *
         *     bit 3   bit 2   bit 1   bit 0
         *       1       1       0       1
         *
         * So the highest set bit is bit 3.
         *
         * We can also say:
         *
         *     2^3 <= 13 < 2^4
         *
         *     8 <= 13 < 16
         *
         * Therefore:
         *
         *     mostSignificantBit = 3
         *
         * We start from zero because we have not found the bit yet.
         */
        uint256 mostSignificantBit = 0;

        /**
         * @dev
         * Check whether `r` is bigger than 2^128.
         *
         * The hexadecimal value:
         *
         *     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
         *
         * is:
         *
         *     2^128 - 1
         *
         * So:
         *
         *     r > 2^128 - 1
         *
         * means:
         *
         *     r >= 2^128
         *
         * This tells us that the highest 1-bit is at least bit 128.
         *
         * `gt()` returns only:
         *
         *     1 -> true
         *     0 -> false
         *
         * Then:
         *
         *     shl(7, 1) = 128
         *     shl(7, 0) = 0
         *
         * So `f` becomes either:
         *
         *     128
         *
         * or:
         *
         *     0
         *
         * If it is 128, we shift `r` right by 128 bits.
         *
         * This lets the next checks work on a smaller range.
         */
        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))

            mostSignificantBit := or(mostSignificantBit, f)

            r := shr(f, r)
        }

        /**
         * @dev
         * Now check whether the remaining value is bigger than 2^64 - 1.
         *
         *     0xFFFFFFFFFFFFFFFF = 2^64 - 1
         *
         * If true:
         *
         *     f = 64
         *
         * If false:
         *
         *     f = 0
         *
         * So we are now checking whether the most significant bit is
         * at least 64 positions higher than the current range.
         */
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))

            mostSignificantBit := or(mostSignificantBit, f)

            r := shr(f, r)
        }

        /**
         * @dev
         * Check the next 32-bit range.
         *
         *     0xFFFFFFFF = 2^32 - 1
         *
         * If `r` is bigger than this value, we know the highest bit is
         * at least 32 positions into the current range.
         *
         * `shl(5, ...)` gives:
         *
         *     32 or 0
         *
         * We add that result to `mostSignificantBit`.
         */
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))

            mostSignificantBit := or(mostSignificantBit, f)

            r := shr(f, r)
        }

        /**
         * @dev
         * Check the next 16-bit range.
         *
         *     0xFFFF = 2^16 - 1
         *
         * The answer from `gt()` is 0 or 1.
         *
         * After:
         *
         *     shl(4, ...)
         *
         * `f` becomes:
         *
         *     16 or 0
         */
        assembly {
            let f := shl(4, gt(r, 0xFFFF))

            mostSignificantBit := or(mostSignificantBit, f)

            r := shr(f, r)
        }

        /**
         * @dev
         * Check the next 8-bit range.
         *
         *     0xFF = 2^8 - 1
         *
         * So this tells us whether the highest bit is at least
         * 8 positions into the current range.
         */
        assembly {
            let f := shl(3, gt(r, 0xFF))

            mostSignificantBit := or(mostSignificantBit, f)

            r := shr(f, r)
        }

        /**
         * @dev
         * Check the next 4-bit range.
         *
         *     0xF = 15 = 2^4 - 1
         *
         * If `r > 15`, we know we need to move by 4 bits.
         *
         * Therefore `f` becomes:
         *
         *     4 or 0
         */
        assembly {
            let f := shl(2, gt(r, 0xF))

            mostSignificantBit := or(mostSignificantBit, f)

            r := shr(f, r)
        }

        /**
         * @dev
         * Check the next 2-bit range.
         *
         *     0x3 = 3 = 2^2 - 1
         *
         * If:
         *
         *     r > 3
         *
         * then the highest bit is at least 2 positions into the
         * current range.
         *
         * Therefore:
         *
         *     f = 2 or 0
         */
        assembly {
            let f := shl(1, gt(r, 0x3))

            mostSignificantBit := or(mostSignificantBit, f)

            r := shr(f, r)
        }

        /**
         * @dev
         * Finally check whether `r` is bigger than 1.
         *
         *     r > 1
         *
         * means the highest bit is bit 1.
         *
         * If false, the highest bit is bit 0.
         *
         * Here we do not need `shl()` because:
         *
         *     gt() already gives us 1 or 0
         *
         * and that is exactly the amount we need to add.
         */
        assembly {
            let f := gt(r, 0x1)

            mostSignificantBit := or(mostSignificantBit, f)
        }

        /**
         * @dev
         * Normalize the ratio.
         *
         * We want the highest 1-bit to be at:
         *
         *     bit 127
         *
         * There are two cases.
         *
         * Case 1:
         *
         *     mostSignificantBit >= 128
         *
         * Then the highest bit is too far to the left.
         *
         * So we shift right:
         *
         *     ratio >> (mostSignificantBit - 127)
         *
         *
         * Case 2:
         *
         *     mostSignificantBit < 128
         *
         * Then the highest bit is too far to the right.
         *
         * So we shift left:
         *
         *     ratio << (127 - mostSignificantBit)
         *
         *
         * After this:
         *
         *     highest 1-bit = bit 127
         *
         * This makes the number easy to work with during the
         * logarithm calculation.
         */
        if (mostSignificantBit >= 128) {
            r = ratio >> (mostSignificantBit - 127);
        } else {
            r = ratio << (127 - mostSignificantBit);
        }

        /**
         * @dev
         * Create the starting part of log2.
         *
         * We already know where the highest bit was.
         *
         * For a number x:
         *
         *     MSB(x) = floor(log2(x))
         *
         * But our ratio is scaled by 2^128.
         *
         * So we subtract 128:
         *
         *     mostSignificantBit - 128
         *
         * This gives the integer part of the logarithm relative to
         * the Q128.128 scaling.
         *
         * Then:
         *
         *     << 64
         *
         * means multiply by 2^64.
         *
         * This gives `log_2` 64 fractional bits.
         *
         * Think of it as:
         *
         *     integer part | fractional part
         *                   ^
         *                binary point
         *
         * The fractional part will be filled in by the repeated
         * squaring steps below.
         */
        int256 log_2 = (int256(mostSignificantBit) - 128) << 64;

        /**
         * @dev
         * Start finding the fractional part of log2.
         *
         * We square `r`.
         *
         * Why square?
         *
         * Because:
         *
         *     r = 2^f
         *
         * then:
         *
         *     r^2 = 2^(2f)
         *
         * So squaring doubles the hidden logarithm fraction.
         *
         * Example:
         *
         *     r = 1.5
         *
         *     r^2 = 2.25
         *
         * Since:
         *
         *     2.25 >= 2
         *
         * we know that:
         *
         *     log2(1.5) >= 0.5
         *
         * so the first binary fractional bit is `1`.
         *
         * `shr(127, ...)` moves the squared value back into the
         * correct scaled position.
         *
         * Then:
         *
         *     shr(128, r)
         *
         * extracts the important bit.
         *
         * So `f` becomes:
         *
         *     0 or 1
         *
         * That bit is stored in bit 63 of `log_2`.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(63, f))

            r := shr(f, r)
        }

        /**
         * @dev
         * Find the next fractional bit of log2.
         *
         * The previous step stored its bit in position 63.
         *
         * This step stores the new bit in position 62.
         *
         * We square again because squaring doubles the remaining
         * logarithm fraction again.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(62, f))

            r := shr(f, r)
        }

        /**
         * @dev
         * Find the next fractional bit.
         *
         * This bit is stored at position 61.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(61, f))

            r := shr(f, r)
        }

        /**
         * @dev
         * Find the next fractional bit.
         *
         * This bit is stored at position 60.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(60, f))

            r := shr(f, r)
        }

        /**
         * @dev
         * Find the next fractional bit.
         *
         * This bit is stored at position 59.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(59, f))

            r := shr(f, r)
        }

        /**
         * @dev
         * Find the next fractional bit.
         *
         * This bit is stored at position 58.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(58, f))

            r := shr(f, r)
        }

        /**
         * @dev
         * Find the next fractional bit.
         *
         * This bit is stored at position 57.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(57, f))

            r := shr(f, r)
        }

        /**
         * @dev
         * Find the next fractional bit.
         *
         * This bit is stored at position 56.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(56, f))

            r := shr(f, r)
        }

        /**
         * @dev
         * Find the next fractional bit.
         *
         * This bit is stored at position 55.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(55, f))

            r := shr(f, r)
        }

        /**
         * @dev
         * Find the next fractional bit.
         *
         * This bit is stored at position 54.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(54, f))

            r := shr(f, r)
        }

        /**
         * @dev
         * Find the next fractional bit.
         *
         * This bit is stored at position 53.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(53, f))

            r := shr(f, r)
        }

        /**
         * @dev
         * Find the next fractional bit.
         *
         * This bit is stored at position 52.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(52, f))

            r := shr(f, r)
        }

        /**
         * @dev
         * Find the next fractional bit.
         *
         * This bit is stored at position 51.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(51, f))

            r := shr(f, r)
        }

        /**
         * @dev
         * Find the last fractional bit we need.
         *
         * This bit is stored at position 50.
         *
         * We do not shift `r` afterwards because there is no next
         * squaring step.
         */
        assembly {
            r := shr(127, mul(r, r))

            let f := shr(128, r)

            log_2 := or(log_2, shl(50, f))
        }

        /**
         * @dev
         * Convert the base-2 logarithm into the logarithm used by the
         * Uniswap tick system.
         *
         * Uniswap's price system is based on:
         *
         *     1.0001^tick
         *
         * Because we are working with the square-root price, we use:
         *
         *     sqrt(1.0001)^tick
         *
         * We already calculated:
         *
         *     log2(sqrtPrice)
         *
         * Now we convert that logarithm into the new base using a
         * precomputed fixed-point constant.
         *
         * Think of it as:
         *
         *     "We measured the number using base 2.
         *      Now convert that measurement into the tick scale."
         *
         * The multiplication is done with integer arithmetic, so the
         * fixed-point scaling keeps the fractional information.
         */
        int256 log_sqrt10001 = log_2 * 255738958999603826347141;

        /**
         * @dev
         * Create the lower tick guess.
         *
         * `log_sqrt10001` is still scaled by 2^128.
         *
         * The subtraction moves the value slightly downward before
         * removing the fixed-point scaling.
         *
         * Then:
         *
         *     >> 128
         *
         * removes the 128 fractional bits.
         *
         * So the result becomes an integer tick.
         *
         * Think of this as:
         *
         *     "Give me a tick that is safely on the lower side."
         */
        int24 lowerThanTrueTick = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);

        /**
         * @dev
         * Create the higher tick guess.
         *
         * This time we add a constant before removing the Q128 scaling.
         *
         * So this gives us a tick on the upper side.
         *
         * Think of it as:
         *
         *     "Give me another possible tick that is safely on the
         *      higher side."
         *
         * Now we have two possible answers:
         *
         *     lowerThanTrueTick
         *     higherThanTrueTick
         */
        int24 higherThanTrueTick = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        /**
         * @dev
         * Choose the final tick.
         *
         * First ask:
         *
         *     Are the two guesses the same?
         *
         * If yes:
         *
         *     lowerThanTrueTick == higherThanTrueTick
         *
         * then there is no decision to make.
         *
         * We simply return that tick.
         *
         * If they are different, we check the higher tick.
         *
         * We calculate:
         *
         *     getSqrtPriceRatioAtTick(higherThanTrueTick)
         *
         * and compare that price with our original:
         *
         *     sqrtPriceRatio
         *
         * If:
         *
         *     priceOfHigherTick <= sqrtPriceRatio
         *
         * then the higher tick is still valid, so we return it.
         *
         * Otherwise the higher tick is too high, so we return the lower tick.
         *
         * Think of it as having two guesses:
         *
         *     lower = 5
         *     higher = 6
         *
         * We ask:
         *
         *     "Does tick 6's price still fit inside our target price?"
         *
         * If yes:
         *
         *     answer = 6
         *
         * If no:
         *
         *     answer = 5
         *
         * This gives us the correct boundary tick.
         */
        tick = lowerThanTrueTick == higherThanTrueTick
            ? lowerThanTrueTick
            : getSqrtPriceRatioAtTick(higherThanTrueTick) <= sqrtPriceRatio ? higherThanTrueTick : lowerThanTrueTick;
    }
}
