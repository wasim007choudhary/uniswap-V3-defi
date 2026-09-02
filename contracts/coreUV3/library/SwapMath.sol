// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {MyCustomFullMath} from "contracts/coreUV3/library/MyCustomFullMath.sol";
import {SqrtPriceMath} from "contracts/coreUV3/library/SqrtPriceMath.sol";

/**
 * @title SwapMath
 * @notice Contains mathematical logic used to calculate a single step of a
 *         Uniswap V3-style swap.
 *
 * @dev This library does NOT execute the entire swap.
 *      It calculates only one swap step between the current price and a
 *      target price while the pool has a specific amount of active liquidity.
 *
 *      The complete reverse engineering and detailed line-by-line
 *      explanation of `computeSwapStep()` is documented at:
 *
 *      notes/CoreLibFunctions/SwapMath__computeSwapStep
 *
 *  The internal function is broken down in diff notes go out amd checjk SqrtPriceMath section for more details on the math and logic behind the calculations.
 *
 */
library SwapMath {
    /**
     * @notice Calculates the result of one swap step between the current
     *         square-root price and a target square-root price.
     *
     * @dev The function first determines the swap direction and whether the
     *      swap is Exact Input or Exact Output.
     *
     *      For Exact Input:
     *      - The input amount after accounting for the fee is calculated.
     *      - The input required to reach the target price is calculated.
     *      - If enough input is available, the target is reached.
     *      - Otherwise, the next price reachable with the available input
     *        is calculated.
     *
     *      For Exact Output:
     *      - The output available before reaching the target price is
     *        calculated.
     *      - If the requested output is large enough to reach the target,
     *        the target is reached.
     *      - Otherwise, the next price required to obtain the requested
     *        output is calculated.
     *
     *      After the next price is known, the function calculates the actual
     *      token input and output for the Current → Next price movement.
     *
     *      The complete reverse engineering and detailed numerical
     *      explanation of this function is documented at:
     *
     *      notes/CoreLibFunctions/SwapMath__computeSwapStep
     *
     * @param currentSqrtRatioPriceX96 The current square-root price of the
     *        pool, encoded using the Q64.96 format.
     *
     * @param targetSqrtRatioPriceX96 The target square-root price for this
     *        swap step. This is the price that the current step attempts
     *        to reach.
     *
     * @param liquidity The active liquidity available in the current
     *        price range. This is the liquidity used for the calculations
     *        of this particular swap step.
     *
     * @param amountRemaining A signed amount that determines the swap type.
     *
     *        Positive or zero:
     *        Exact Input — the specified amount is the input available
     *        for the swap.
     *
     *        Negative:
     *        Exact Output — the absolute value represents the amount of
     *        output still requested.
     *
     * @param feePips The swap fee expressed using Uniswap's fee scale,
     *        where 1e6 represents 100%.
     *
     *        Examples:
     *        500   = 0.05%
     *        3000  = 0.30%
     *        10000 = 1%
     *
     * @return nextSqrtRatioPriceX96 The square-root price reached after
     *         executing this swap step.
     *
     * @return amountIn The amount of the input token consumed during
     *         this swap step.
     *
     * @return amountOut The amount of the output token produced during
     *         this swap step.
     *
     * @return feeAmountTaken The fee associated with the input consumed
     *         during this swap step.
     */
    function computeSwapStep(
        uint160 currentSqrtRatioPriceX96,
        uint160 targetSqrtRatioPriceX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    )
        internal
        pure
        returns (uint160 nextSqrtRatioPriceX96, uint256 amountIn, uint256 amountOut, uint256 feeAmountTaken)
    {
        /**
         * @dev `zeroForOne` determines the swap direction.
         *
         *      true:
         *          token0 → token1
         *          price moves downward
         *
         *      false:
         *          token1 → token0
         *          price moves upward
         */
        bool zeroForOne = currentSqrtRatioPriceX96 >= targetSqrtRatioPriceX96;

        /**
         * @dev `exactIn` determines what the trader specified.
         *
         *      true:
         *          trader specifies the input amount.
         *
         *      false:
         *          trader specifies the output amount.
         */
        bool exactIn = amountRemaining >= 0;

        if (exactIn) {
            /**
             * @dev Remove the fee portion from the remaining Exact Input
             *      amount to determine how much input can actually move
             *      the price.
             *
             *      This is NOT the fee itself.
             *
             *      amountRemainingAfterFeeDeduction
             *          = amountRemaining × (1e6 - feePips) / 1e6
             */
            uint256 amountRemainingAfterFeeDeduction =
                MyCustomFullMath.mulDiv(uint256(amountRemaining), 1e6 - feePips, 1e6);

            /**
             * @dev Calculate how much input is required to move the price
             *      all the way from Current → Target.
             */
            if (zeroForOne) {
                /**
                 * @dev zeroForOne = true:
                 *
                 *      token0 → token1
                 *      token0 is INPUT
                 *      token1 is OUTPUT
                 *      price moves downward
                 *
                 *      Δx = L(1/√Plower - 1/√Pupper)
                 *
                 *      `true` means round UP because token0 is the
                 *      input amount.
                 */
                amountIn = SqrtPriceMath.getAmount0Delta(
                    targetSqrtRatioPriceX96, currentSqrtRatioPriceX96, liquidity, true
                );
            } else {
                /**
                 * @dev zeroForOne = false:
                 *
                 *      token1 → token0
                 *      token1 is INPUT
                 *      token0 is OUTPUT
                 *      price moves upward
                 *
                 *      Δy = L(√Pupper - √Plower)
                 *
                 *      `true` means round UP because token1 is the
                 *      input amount.
                 */
                amountIn = SqrtPriceMath.getAmount1Delta(
                    currentSqrtRatioPriceX96, targetSqrtRatioPriceX96, liquidity, true
                );
            }

            /**
             * @dev Check whether the available input is enough to move
             *      the price all the way to the target.
             *
             *      If YES:
             *          Next = Target
             *
             *      If NO:
             *          calculate the actual Next price reachable with
             *          the available input.
             */
            if (amountRemainingAfterFeeDeduction >= amountIn) {
                nextSqrtRatioPriceX96 = targetSqrtRatioPriceX96;
            } else {
                nextSqrtRatioPriceX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                    currentSqrtRatioPriceX96, amountRemainingAfterFeeDeduction, liquidity, zeroForOne
                );
            }
        } else {
            /**
             * @dev Exact Output:
             *
             *      The output amount is specified by the trader.
             *
             *      First calculate how much output can be produced by
             *      moving the price all the way from Current → Target.
             */
            if (zeroForOne) {
                /**
                 * @dev zeroForOne = true:
                 *
                 *      token0 → token1
                 *      token1 is OUTPUT
                 *      price moves downward
                 *
                 *      Δy = L(√Pupper - √Plower)
                 *
                 *      `false` means round DOWN because token1 is
                 *      the output amount.
                 */
                amountOut = SqrtPriceMath.getAmount1Delta(
                    currentSqrtRatioPriceX96, targetSqrtRatioPriceX96, liquidity, false
                );
            } else {
                /**
                 * @dev zeroForOne = false:
                 *
                 *      token1 → token0
                 *      token0 is OUTPUT
                 *      price moves upward
                 *
                 *      Δx = L(1/√Plower - 1/√Pupper)
                 *
                 *      `false` means round DOWN because token0 is
                 *      the output amount.
                 */
                amountOut = SqrtPriceMath.getAmount0Delta(
                    targetSqrtRatioPriceX96, currentSqrtRatioPriceX96, liquidity, false
                );
            }

            /**
             * @dev Check whether the trader's requested output is enough
             *      to reach the target.
             *
             *      If YES:
             *          Next = Target
             *
             *      If NO:
             *          calculate the actual Next price required to
             *          obtain the requested output.
             */
            if (uint256(-amountRemaining) >= amountOut) {
                nextSqrtRatioPriceX96 = targetSqrtRatioPriceX96;
            } else {
                nextSqrtRatioPriceX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                    currentSqrtRatioPriceX96, uint256(-amountRemaining), liquidity, zeroForOne
                );
            }
        }

        ///////////////////////////////////////////////////////////////
        // At this point, `nextSqrtRatioPriceX96` is already known.
        //
        // `max = true`  → Current → Target was completed.
        // `max = false` → swap stopped before Target.
        //
        // The code below does NOT find Next again.
        // It calculates the token amounts corresponding to the
        // ACTUAL Current → Next price movement.
        ///////////////////////////////////////////////////////////////

        bool max = nextSqrtRatioPriceX96 == targetSqrtRatioPriceX96;

        /**
         * @dev `max = true`:
         *      the target price was reached.
         *
         *      `max = false`:
         *      the swap stopped at an intermediate price before
         *      reaching the target.
         */
        if (zeroForOne) {
            /**
             * @dev zeroForOne = true:
             *
             *      token0 → token1
             *      token0 = INPUT
             *      token1 = OUTPUT
             *      price moves downward.
             */

            if (max && exactIn) {
                /**
                 * @dev Target was reached and this is Exact Input.
                 *
                 *      `amountIn` was already calculated for the
                 *      complete Current → Target movement.
                 *
                 *      Since:
                 *
                 *          Next = Target
                 *
                 *      the previous amountIn is already the correct
                 *      amount for the actual movement.
                 */
                amountIn = amountIn;
            } else {
                /**
                 * @dev Otherwise, calculate token0 input for the
                 *      actual Current → Next price movement.
                 *
                 *      `true` = round UP because token0 is INPUT.
                 */
                amountIn =
                    SqrtPriceMath.getAmount0Delta(nextSqrtRatioPriceX96, currentSqrtRatioPriceX96, liquidity, true);
            }

            if (max && !exactIn) {
                /**
                 * @dev Target was reached and this is Exact Output.
                 *
                 *      `amountOut` was already calculated for the
                 *      complete Current → Target movement.
                 *
                 *      Since:
                 *
                 *          Next = Target
                 *
                 *      the previous amountOut is already the correct
                 *      amount for the actual movement.
                 */
                amountOut = amountOut;
            } else {
                /**
                 * @dev Otherwise, calculate token1 output for the
                 *      actual Current → Next price movement.
                 *
                 *      `false` = round DOWN because token1 is OUTPUT.
                 */
                amountOut =
                    SqrtPriceMath.getAmount1Delta(currentSqrtRatioPriceX96, nextSqrtRatioPriceX96, liquidity, false);
            }
        } else {
            /**
             * @dev zeroForOne = false:
             *
             *      token1 → token0
             *      token1 = INPUT
             *      token0 = OUTPUT
             *      price moves upward.
             */

            if (max && exactIn) {
                /**
                 * @dev Target was reached and this is Exact Input.
                 *
                 *      `amountIn` was already calculated for the
                 *      complete Current → Target movement.
                 *
                 *      Since:
                 *
                 *          Next = Target
                 *
                 *      the previous amountIn is already correct.
                 */
                amountIn = amountIn;
            } else {
                /**
                 * @dev Otherwise, calculate token1 input for the
                 *      actual Current → Next price movement.
                 *
                 *      `true` = round UP because token1 is INPUT.
                 */
                amountIn =
                    SqrtPriceMath.getAmount1Delta(nextSqrtRatioPriceX96, currentSqrtRatioPriceX96, liquidity, true);
            }

            if (max && !exactIn) {
                /**
                 * @dev Target was reached and this is Exact Output.
                 *
                 *      `amountOut` was already calculated for the
                 *      complete Current → Target movement.
                 *
                 *      Since:
                 *
                 *          Next = Target
                 *
                 *      the previous amountOut is already correct.
                 */
                amountOut = amountOut;
            } else {
                /**
                 * @dev Otherwise, calculate token0 output for the
                 *      actual Current → Next price movement.
                 *
                 *      `false` = round DOWN because token0 is OUTPUT.
                 */
                amountOut =
                    SqrtPriceMath.getAmount0Delta(currentSqrtRatioPriceX96, nextSqrtRatioPriceX96, liquidity, false);
            }
        }

        /**
         * @dev Exact Output safety cap.
         *
         *      `amountRemaining` is negative during Exact Output.
         *      Therefore `-amountRemaining` represents the positive
         *      amount of output still requested.
         *
         *      Never return more output than the trader requested.
         */
        if (!exactIn && amountOut > uint256(-amountRemaining)) {
            amountOut = uint256(-amountRemaining);
        }

        /**
         * @dev Calculate the fee taken during this swap step.
         *
         *      Partial Exact Input:
         *
         *          Next != Target
         *
         *      In this case, all remaining input available for the
         *      step was consumed, so:
         *
         *          fee = total input - input used for price movement
         *
         *      Otherwise, use the reverse fee calculation because
         *      `amountIn` represents the input after removing the fee:
         *
         *          fee = amountIn × fee / (1 - fee)
         *
         *      `mulDivRoundUp()` rounds the fee upward.
         */
        if (exactIn && nextSqrtRatioPriceX96 != targetSqrtRatioPriceX96) {
            feeAmountTaken = uint256(amountRemaining) - amountIn;
        } else {
            feeAmountTaken = MyCustomFullMath.mulDivRoundUp(amountIn, feePips, 1e6 - feePips);
        }
    }
}

