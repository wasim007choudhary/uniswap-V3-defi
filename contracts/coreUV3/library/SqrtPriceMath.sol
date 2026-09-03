// SPDX-License-Identifier: MIT
import {MyCustomFullMath} from "contracts/coreUV3/library/MyCustomFullMATH.sol";
import {MyCustomMath} from "contracts/coreUV3/library/MyCustomMath.sol";
import {FixedPointQ96} from "contracts/coreUV3/library/FixedPoint96.sol";
import {MyCustomSafeCast} from "contracts/coreUV3/library/MyCustomSafeCast.sol";
import {MyCustomUnsafeMath} from "contracts/coreUV3/library/MyCustomUnsafeMath.sol";
pragma solidity ^0.8.20;

library SqrtPriceMath {
    using MyCustomSafeCast for uint256;

    /**
     * @notice Calculates the next sqrt price after adding or removing token0.
     *
     * @dev This function calculates how the Q64.96 square-root price changes
     *      when `amount` of token0 is added to or removed from the active
     *      liquidity position.
     *
     *      The fundamental token0 price-movement formula is:
     *
     *          sqrt(P_next) = (L × sqrt(P_current))
     *                         / (L ± amount × sqrt(P_current))
     *
     *      Where:
     *
     *          L                = active liquidity
     *          sqrt(P_current)  = current square-root price
     *          amount           = amount of token0 being added or removed
     *          sqrt(P_next)     = resulting square-root price
     *
     *      The sign depends on whether token0 is being added or removed:
     *
     *      ADD TOKEN0:
     *
     *          sqrt(P_next)
     *              =
     *          (L × sqrt(P_current))
     *          ─────────────────────────────────
     *          (L + amount × sqrt(P_current))
     *
     *          Adding token0 makes the sqrt price MOVE DOWN.
     *
     *      REMOVE TOKEN0:
     *
     *          sqrt(P_next)
     *              =
     *          (L × sqrt(P_current))
     *          ─────────────────────────────────
     *          (L - amount × sqrt(P_current))
     *
     *          Removing token0 makes the sqrt price MOVE UP.
     *
     *      The price is represented as a Q64.96 fixed-point number:
     *
     *          sqrtPriceQ96 = sqrt(P) × 2^96
     *
     *      Therefore the implementation scales the liquidity by 2^96:
     *
     *          numerator1 = L × 2^96
     *
     *      which is implemented as:
     *
     *          uint256(liquidity) << FixedPointQ96.RESOLUTION
     *
     *      Since:
     *
     *          RESOLUTION = 96
     *
     *      this is equivalent to:
     *
     *          uint256(liquidity) × 2^96
     *
     *      ---------------------------------------------------------------
     *      ZERO AMOUNT
     *      ---------------------------------------------------------------
     *
     *      If `amount == 0`, no token0 is being added or removed, so the
     *      sqrt price must remain unchanged.
     *
     *      The function immediately returns `sqrtPriceQ96`.
     *
     *      This short circuit is important because performing the normal
     *      integer calculation with zero could involve rounding and therefore
     *      is not guaranteed to reproduce the exact input price representation.
     *
     *      ---------------------------------------------------------------
     *      ADDING TOKEN0
     *      ---------------------------------------------------------------
     *
     *      The direct formula requires:
     *
     *          amount × sqrtPriceQ96
     *
     *      and then:
     *
     *          numerator1 + product
     *
     *      Older Solidity versions did not automatically revert on arithmetic
     *      overflow, so the original Uniswap implementation manually detected
     *      overflow.
     *
     *      This Solidity 0.8.20 implementation uses `unchecked` intentionally
     *      for those operations.
     *
     *      This is NOT because overflow is considered safe.
     *
     *      Instead, the ADD branch intentionally allows the intermediate
     *      calculation to overflow so that the overflow can be detected and
     *      the function can switch to an algebraically equivalent fallback
     *      formula.
     *
     *      The multiplication is checked using:
     *
     *          (product = amount × sqrtPriceQ96) / amount
     *              == sqrtPriceQ96
     *
     *      If the multiplication overflowed, the division-back result will
     *      no longer equal the original `sqrtPriceQ96`.
     *
     *      If the multiplication is valid, the function then calculates:
     *
     *          denominator = numerator1 + product
     *
     *      and checks:
     *
     *          denominator >= numerator1
     *
     *      If the addition overflowed, the wrapped result becomes smaller than
     *      `numerator1`, so the check fails.
     *
     *      If both intermediate calculations are valid, the direct formula is:
     *
     *          sqrt(P_next)
     *              =
     *          numerator1 × sqrtPriceQ96
     *          ─────────────────────────────
     *          numerator1 + product
     *
     *      and is calculated with `MyCustomFullMath.mulDivRoundUp()`.
     *
     *      ---------------------------------------------------------------
     *      ADD FALLBACK FORMULA
     *      ---------------------------------------------------------------
     *
     *      If either intermediate calculation would overflow, the function
     *      does NOT revert.
     *
     *      The mathematical operation itself can still be valid, so the
     *      function uses an algebraically equivalent formula that avoids the
     *      dangerous multiplication:
     *
     *          (L × sqrt(P))
     *          ─────────────────────────────
     *          (L + amount × sqrt(P))
     *
     *      Divide the numerator and denominator by sqrt(P):
     *
     *                    L
     *          ─────────────────────────
     *          (L / sqrt(P)) + amount
     *
     *      Therefore the same result can be calculated as:
     *
     *          numerator1
     *          ─────────────────────────────
     *          (numerator1 / sqrtPriceQ96) + amount
     *
     *      This fallback is NOT an approximation.
     *
     *      It is algebraically equivalent to the direct formula.
     *
     *      `MyCustomUnsafeMath.divRoundingUp()` is used because the result
     *      must be rounded UP.
     *
     *      ---------------------------------------------------------------
     *      REMOVING TOKEN0
     *      ---------------------------------------------------------------
     *
     *      When token0 is removed, the formula becomes:
     *
     *          sqrt(P_next)
     *              =
     *          numerator1 × sqrtPriceQ96
     *          ─────────────────────────────
     *          numerator1 - product
     *
     *      where:
     *
     *          product = amount × sqrtPriceQ96
     *
     *      The denominator must remain strictly positive:
     *
     *          numerator1 > product
     *
     *      because:
     *
     *          numerator1 == product
     *              → denominator == 0
     *
     *          numerator1 < product
     *              → denominator would be negative mathematically
     *
     *      Therefore the REMOVE branch reverts unless both conditions hold:
     *
     *          product / amount == sqrtPriceQ96
     *
     *          AND
     *
     *          numerator1 > product
     *
     *      Unlike the ADD branch, there is no useful overflow fallback for
     *      the removal calculation.
     *
     *      A valid removal requires:
     *
     *          amount × sqrt(P) < L
     *
     *      and `L` is a `uint128`.
     *
     *      Therefore a valid product is smaller than the uint128 liquidity
     *      value and cannot require a uint256-overflowing product.
     *
     *      ---------------------------------------------------------------
     *      ROUNDING
     *      ---------------------------------------------------------------
     *
     *      The function name contains `RoundingUp` because the resulting
     *      sqrt price is always calculated with rounding UP.
     *
     *      This is important because Solidity integer division normally
     *      rounds DOWN by discarding the fractional part.
     *
     *      Uniswap V3 deliberately chooses the rounding direction required
     *      by the surrounding swap mathematics so that the calculation does
     *      not produce an unsafe amount of token movement.
     *
     *      ---------------------------------------------------------------
     *      UINT160 RESULT
     *      ---------------------------------------------------------------
     *
     *      The resulting sqrt price is returned as `uint160`.
     *
     *      In the ADD branch, token0 is added and the sqrt price moves DOWN.
     *      Since the current sqrt price already fits into `uint160`, the
     *      resulting lower price also fits into `uint160`.
     *
     *      Therefore the direct ADD result can safely use:
     *
     *          uint160(...)
     *
     *      In the REMOVE branch, token0 is removed and the sqrt price moves UP.
     *      The resulting value can therefore be larger than the current
     *      `uint160` value.
     *
     *      The REMOVE branch consequently uses:
     *
     *          .toUint160()
     *
     *      so that the conversion explicitly checks that the calculated
     *      result fits within the uint160 range.
     *
     * @param sqrtPriceQ96 Current sqrt price encoded as Q64.96:
     *                     `sqrt(P_current) × 2^96`.
     * @param liquidity    Current active liquidity used for this price movement.
     * @param amount       Amount of token0 being added or removed.
     * @param add          `true` when token0 is added, `false` when token0 is removed.
     *
     * @return sqrtPriceNextQ96 The resulting sqrt price encoded as Q64.96.
     */
    function getNextSqrtPriceFromAmount0RoundingUp(uint160 sqrtPriceQ96, uint128 liquidity, uint256 amount, bool add)
        internal
        pure
        returns (uint160)
    {
        /**
         * @dev If no token0 is added or removed:
         *
         *      amount = 0
         *
         *      Therefore:
         *
         *      sqrt(P_next) = sqrt(P_current)
         *
         *      We return the exact input representation instead of performing
         *      another rounded calculation.
         */
        if (amount == 0) return sqrtPriceQ96;

        /**
         * @dev Convert liquidity into the Q96-scaled form required by the
         *      token0 price formula:
         *
         *          numerator1 = L × 2^96
         *
         *      `RESOLUTION = 96`, so:
         *
         *          liquidity << 96
         *
         *      is equivalent to:
         *
         *          liquidity × 2^96
         */
        uint256 numerator1 = uint256(liquidity) << FixedPointQ96.RESOLUTION;

        if (add) {
            /**
             * @dev ADD TOKEN0:
             *
             *      Token0 is entering the pool.
             *      The sqrt price therefore moves DOWN.
             *
             *      Formula:
             *
             *          sqrt(P_next)
             *              =
             *          numerator1 × sqrtPriceQ96
             *          ─────────────────────────────
             *          numerator1 + amount × sqrtPriceQ96
             *
             *      We first try to calculate:
             *
             *          product = amount × sqrtPriceQ96
             *
             *      `unchecked` is intentional.
             *
             *      We must be able to observe an overflowing intermediate
             *      multiplication and fall back to the equivalent formula
             *      instead of allowing Solidity 0.8.20 to revert immediately.
             */
            uint256 product;

            unchecked {
                /**
                 * @dev Check whether:
                 *
                 *          amount × sqrtPriceQ96
                 *
                 *      fit inside uint256 without overflowing.
                 *
                 *      If the multiplication is valid:
                 *
                 *          product / amount == sqrtPriceQ96
                 *
                 *      If it overflowed, the wrapped product divided by
                 *      `amount` will not recover the original sqrt price.
                 */
                if ((product = amount * sqrtPriceQ96) / amount == sqrtPriceQ96) {
                    /**
                     * @dev Direct denominator:
                     *
                     *          denominator
                     *              =
                     *          numerator1 + product
                     *
                     *      Which represents:
                     *
                     *          L × 2^96 + amount × sqrtPriceQ96
                     */
                    uint256 denominator = numerator1 + product;

                    /**
                     * @dev Detect overflow of:
                     *
                     *          numerator1 + product
                     *
                     *      A valid addition must produce a value at least
                     *      as large as `numerator1`.
                     *
                     *      If the addition wrapped around, `denominator`
                     *      becomes smaller than `numerator1` and the direct
                     *      calculation is skipped.
                     */
                    if (denominator >= numerator1) {
                        /**
                         * @dev Direct formula:
                         *
                         *          sqrt(P_next)
                         *              =
                         *          numerator1 × sqrtPriceQ96
                         *          ─────────────────────────────
                         *          denominator
                         *
                         *      `mulDivRoundUp()` calculates the multiplication
                         *      and division with full precision and rounds UP.
                         */
                        return uint160(MyCustomFullMath.mulDivRoundUp(numerator1, sqrtPriceQ96, denominator));
                    }
                }
            }

            /**
             * @dev FALLBACK:
             *
             *      The direct formula could not safely calculate one of its
             *      intermediate values.
             *
             *      Instead of reverting, use the algebraically equivalent form:
             *
             *                         numerator1
             *          ─────────────────────────────────────
             *          (numerator1 / sqrtPriceQ96) + amount
             *
             *      This avoids:
             *
             *          amount × sqrtPriceQ96
             *
             *      and therefore avoids the intermediate multiplication that
             *      caused the direct path to be unusable.
             *
             *      `divRoundingUp()` rounds the result UP.
             */
            return uint160(MyCustomUnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPriceQ96) + amount));
        } else {
            /**
             * @dev REMOVE TOKEN0:
             *
             *      Token0 is leaving the pool.
             *      The sqrt price therefore moves UP.
             *
             *      Formula:
             *
             *          sqrt(P_next)
             *              =
             *          numerator1 × sqrtPriceQ96
             *          ─────────────────────────────
             *          numerator1 - amount × sqrtPriceQ96
             *
             *      Unlike the ADD branch, this operation is only valid when:
             *
             *          numerator1 > amount × sqrtPriceQ96
             *
             *      because the denominator must remain strictly positive.
             */
            uint256 product;

            unchecked {
                /**
                 * @dev We intentionally use `unchecked` so that an overflowing
                 *      multiplication can be detected by the division-back check
                 *      instead of automatically reverting before the check runs.
                 *
                 *      Both conditions must hold:
                 *
                 *      1. Multiplication did not overflow:
                 *
                 *          product / amount == sqrtPriceQ96
                 *
                 *      2. The denominator remains positive:
                 *
                 *          numerator1 > product
                 *
                 *      If either condition fails, the requested token0 removal
                 *      is invalid and the function reverts.
                 */
                require((product = amount * sqrtPriceQ96) / amount == sqrtPriceQ96 && numerator1 > product);
            }

            /**
             * @dev Valid removal guarantees:
             *
             *          numerator1 > product
             *
             *      Therefore this subtraction cannot underflow:
             *
             *          denominator = numerator1 - product
             *
             *      Mathematically this represents:
             *
             *          L - amount × sqrt(P)
             */
            uint256 denominator = numerator1 - product;

            /**
             * @dev Calculate:
             *
             *          sqrt(P_next)
             *              =
             *          numerator1 × sqrtPriceQ96
             *          ─────────────────────────────
             *          denominator
             *
             *      The result is rounded UP.
             *
             *      Because removing token0 makes the sqrt price move UP,
             *      the resulting value is not automatically guaranteed to fit
             *      into uint160.
             *
             *      `toUint160()` therefore performs the explicit safe narrowing
             *      conversion.
             */
            return MyCustomFullMath.mulDivRoundUp(numerator1, sqrtPriceQ96, denominator).toUint160();
        }
    }

    /**
     * @notice Calculates the next sqrt price after adding or removing token1.
     *
     * @dev Token1 changes the sqrt price linearly:
     *      sqrtPriceNext = sqrtPriceCurrent ± amount / liquidity.
     *
     *      When adding token1, the sqrt price increases and the quotient
     *      is rounded down so the final sqrt price does not move above
     *      the exact mathematical result.
     *
     *      When removing token1, the sqrt price decreases and the quotient
     *      is rounded up so the final sqrt price does not remain above
     *      the exact mathematical result.
     *
     *      For smaller amounts, the calculation uses a cheaper shift-and-divide
     *      path. For larger amounts, FullMath is used to safely handle the
     *      multiplication by Q96 without overflowing a uint256 intermediate.
     *
     *      The function always returns the final sqrt price rounded down.
     *
     * @param sqrtPriceQ96 The current sqrt price, stored in Q64.96 format.
     * @param liquidity The amount of active liquidity available for this price movement.
     * @param amount The amount of token1 being added or removed.
     * @param add True when token1 is added; false when token1 is removed.
     *
     * @return The new sqrt price after the token1 amount is applied.
     *
     * @custom:note If token1 is added, the sqrt price moves up.
     * @custom:note If token1 is removed, the sqrt price moves down.
     * @custom:note The final sqrt price is always rounded down.
     *
     * @custom:deep-dive For the full line-by-line dissection, numerical examples,
     * rounding intuition, branch analysis, and reverse engineering of this
     * function, see:
     * `notes/CoreLibFunctions/SqrtPriceMath/3.SPM__fun2.md`
     */
    function getNextSqrtPriceFromAmount1RoundingDown(uint160 sqrtPriceQ96, uint128 liquidity, uint256 amount, bool add)
        internal
        pure
        returns (uint160)
    {
        if (add) {
            uint256 quotient;
            if (amount <= type(uint160).max) {
                quotient = (amount << FixedPointQ96.RESOLUTION) / liquidity;
            } else {
                quotient = MyCustomFullMath.mulDiv(amount, FixedPointQ96.Q96, liquidity);
            }
            return (sqrtPriceQ96 + quotient).toUint160();
        } else {
            uint256 quotient;
            if (amount <= type(uint160).max) {
                quotient = MyCustomUnsafeMath.divRoundingUp(amount << FixedPointQ96.RESOLUTION, liquidity);
            } else {
                quotient = MyCustomFullMath.mulDivRoundUp(amount, FixedPointQ96.Q96, liquidity);
            }
            require(sqrtPriceQ96 > quotient);
            return uint160(sqrtPriceQ96 - quotient);
        }
    }
}
