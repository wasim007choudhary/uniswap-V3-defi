// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title FixedPointQ96
 * @notice Provides constants for working with Q64.96 binary fixed-point numbers.
 *
 * @dev Solidity works with whole numbers, but Uniswap V3 needs to work
 *      with prices that can contain fractional values.
 *
 *      Instead of storing a square-root price as a normal decimal number,
 *      Uniswap V3 multiplies it by 2^96 and stores the result as an integer.
 *
 *      In other words:
 *
 *          sqrtPriceX96 = sqrt(price) * 2^96
 *
 *      When the stored value needs to be understood as the original
 *      square-root price, it can conceptually be divided by 2^96:
 *
 *          sqrt(price) = sqrtPriceX96 / 2^96
 *
 *      This library provides two constants used for this system:
 *
 *
 *      1. `RESOLUTION = 96`
 *
 *         This tells us that 96 binary bits are used for the fractional
 *         part of the fixed-point number.
 *
 *         It is called `RESOLUTION` because it determines how finely
 *         fractional values can be represented. We could have named it
 *         `FRACTIONAL_BITS` or `FRACTIONAL_PRECISION`, but Uniswap V3
 *         calls it `RESOLUTION`, so we follow that naming convention.
 *
 *         It is also used when the code needs to shift a number by
 *         96 bits:
 *
 *             value << RESOLUTION
 *
 *         which is the same as:
 *
 *             value << 96
 *
 *         We use `96` here, rather than `2^96`, because the shift
 *         operator and the scaling factor have different meanings.
 *
 *         `value << 96` means:
 *
 *             "Move the bits 96 positions to the left."
 *
 *         It is mathematically equivalent to multiplying the value
 *         by 2^96:
 *
 *             value << 96 = value * 2^96
 *
 *         But `value << 2^96` would mean something completely different:
 *
 *             "Move the bits 2^96 positions to the left."
 *
 *         Therefore:
 *
 *             `96`   → tells the shift operator HOW MANY positions to move.
 *             `2^96` → is the actual SCALING VALUE.
 *
 *         This is why `RESOLUTION` stores `96`, while `Q96` stores `2^96`.
 *
 *
 *      2. `Q96 = 2^96`
 *
 *         This is the actual scaling number used when a calculation needs
 *         to multiply or divide by the fixed-point scale.
 *
 *         `Q96` is written as a hexadecimal number:
 *
 *             0x1000000000000000000000000
 *
 *         This hexadecimal value is exactly equal to:
 *
 *             2^96
 *
 *         Therefore, these are simply different ways of writing the same
 *         number:
 *
 *             2^96
 *             = 79228162514264337593543950336
 *             = 0x1000000000000000000000000
 *
 *         Uniswap could conceptually have written:
 *
 *             2 ** 96
 *
 *         but instead writes the already-calculated integer value in
 *         hexadecimal. The hexadecimal form makes it clear that this is
 *         a binary, power-of-two scaling constant.
 *
 *
 *      `RESOLUTION` and `Q96` therefore represent two different things:
 *
 *          RESOLUTION = 96      → how many bits to shift
 *          Q96        = 2^96    → the actual scaling value
 *
 *         They cannot simply be replaced by one another.
 *
 *         For example:
 *
 *             value << RESOLUTION
 *
 *         needs `96`, because the shift operator asks:
 *
 *             "How many positions should I shift?"
 *
 *         While:
 *
 *             FullMath.mulDiv(amount, Q96, liquidity)
 *
 *         needs the actual scaling value, `2^96`.
 *
 *      This library is used by SqrtPriceMath.sol.
 */

library FixedPointQ96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

