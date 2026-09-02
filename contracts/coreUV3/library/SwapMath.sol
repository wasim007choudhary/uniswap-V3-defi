// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {MyCustomFullMath} from "contracts/coreUV3/library/MyCustomFullMath.sol";
import {SqrtPriceMath} from "contracts/coreUV3/library/SqrtPriceMath.sol";

library SwapMath {
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
        bool zeroForOne = currentSqrtRatioPriceX96 >= targetSqrtRatioPriceX96;
        bool exactIn = amountRemaining >= 0;

        if (exactIn) {
            uint256 amountRemainingAfterFeeDeduction =
                MyCustomFullMath.mulDiv(uint256(amountRemaining), 1e6 - feePips, 1e6);

            // Calculate the input required to reach the target price.
            if (zeroForOne) {
                // swap token0 for token1
                amountIn = SqrtPriceMath.getAmount0Delta(
                    targetSqrtRatioPriceX96,
                    /**
                     * lower price
                     */
                    currentSqrtRatioPriceX96,
                    /**
                     * upper price
                     */
                    liquidity,
                    true
                ); // Δx = L(1/√Plower - 1/√Pupper): token0 (x) is the input token
            } else {
                // swap token1 for token0
                amountIn = SqrtPriceMath.getAmount1Delta(
                    currentSqrtRatioPriceX96,
                    /**
                     * upperprice
                     */
                    targetSqrtRatioPriceX96,
                    /**
                     * lower price
                     */
                    liquidity,
                    true
                ); // Δy = L(√Pupper - √Plower): token1 (y) is the input token
            }
            // If enough input is available, reach the target price; otherwise, calculate the next price reachable with the available input.
            if (amountRemainingAfterFeeDeduction >= amountIn) {
                nextSqrtRatioPriceX96 = targetSqrtRatioPriceX96;
            } else {
                nextSqrtRatioPriceX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                    currentSqrtRatioPriceX96, amountRemainingAfterFeeDeduction, liquidity, zeroForOne
                );
            }
        } else {
            // Exact Out: the output amount is specified, so we calculate how much output can be obtained before reaching the target price.
            if (zeroForOne) {
                // swap token0 for token1...below we will calculate how much token1 need to be outputted to hit the target Price
                amountOut = SqrtPriceMath.getAmount1Delta(
                    currentSqrtRatioPriceX96,
                    /**
                     * upperprice
                     */
                    targetSqrtRatioPriceX96,
                    /**
                     * lower price
                     */
                    liquidity,
                    false
                ); // Δy = L(√Pupper - √Plower): token1 (y) is the output token
            } else {
                // swap token1 for token0...below we will calculate how much token0 need to be outputted to hit the target Price
                amountOut = SqrtPriceMath.getAmount0Delta(
                    targetSqrtRatioPriceX96,
                    /**
                     * lower price
                     */
                    currentSqrtRatioPriceX96,
                    /**
                     * upperprice
                     */
                    liquidity,
                    false
                ); // Δx = L(1/√Plower - 1/√Pupper): token0 (x) is the output token
            }

            // If the requested output is enough to reach the target, reach the target; otherwise, calculate the next price required to obtain the requested output.
            if (uint256(-amountRemaining) >= amountOut) {
                nextSqrtRatioPriceX96 = targetSqrtRatioPriceX96;
            } else {
                nextSqrtRatioPriceX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                    currentSqrtRatioPriceX96, uint256(-amountRemaining), liquidity, zeroForOne
                );
            }
        }
        ///////////////////////////////////////////////////////////////

        bool max = nextSqrtRatioPriceX96 == targetSqrtRatioPriceX96;
        // `max = true`  → we reached the target price.
        // `max = false` → we stopped before the target at an intermediate price.

        if (zeroForOne) {
            // `zeroForOne = true` → Token0 → Token1.
            // Token0 is INPUT and Token1 is OUTPUT.
            // Price moves downward.

            if (max && exactIn) {
                // We reached the target AND this is Exact In.
                // `amountIn` was already calculated for the full
                // Current → Target movement, so keep that value.
                amountIn = amountIn;
            } else {
                // Otherwise, calculate the Token0 input for the
                // ACTUAL Current → Next price movement.
                // `true` = round UP because this is an input amount.
                amountIn =
                    SqrtPriceMath.getAmount0Delta(nextSqrtRatioPriceX96, currentSqrtRatioPriceX96, liquidity, true);
            }

            if (max && !exactIn) {
                // We reached the target AND this is Exact Out.
                // `amountOut` was already calculated for the full
                // Current → Target movement, so keep that value.
                amountOut = amountOut;
            } else {
                // Otherwise, calculate the Token1 output for the
                // ACTUAL Current → Next price movement.
                // `false` = round DOWN because this is an output amount.
                amountOut =
                    SqrtPriceMath.getAmount1Delta(currentSqrtRatioPriceX96, nextSqrtRatioPriceX96, liquidity, false);
            }
        } else {
            // `zeroForOne = false` → Token1 → Token0.
            // Token1 is INPUT and Token0 is OUTPUT.
            // Price moves upward.

            if (max && exactIn) {
                // We reached the target AND this is Exact In.
                // `amountIn` was already calculated for the full
                // Current → Target movement, so keep that value.
                amountIn = amountIn;
            } else {
                // Otherwise, calculate the Token1 input for the
                // ACTUAL Current → Next price movement.
                // `true` = round UP because this is an input amount.
                amountIn =
                    SqrtPriceMath.getAmount1Delta(nextSqrtRatioPriceX96, currentSqrtRatioPriceX96, liquidity, true);
            }

            if (max && !exactIn) {
                // We reached the target AND this is Exact Out.
                // `amountOut` was already calculated for the full
                // Current → Target movement, so keep that value.
                amountOut = amountOut;
            } else {
                // Otherwise, calculate the Token0 output for the
                // ACTUAL Current → Next price movement.
                // `false` = round DOWN because this is an output amount.
                amountOut =
                    SqrtPriceMath.getAmount0Delta(currentSqrtRatioPriceX96, nextSqrtRatioPriceX96, liquidity, false);
            }
        }
        //////////////////////////////////////////////////////////
        if (!exactIn && amountOut > uint256(-amountRemaining)) {
            amountOut = uint256(-amountRemaining);
        }
        if (exactIn && nextSqrtRatioPriceX96 != targetSqrtRatioPriceX96) {
            feeAmountTaken = uint256(amountRemaining) - amountIn;
        } else {
            // If we reached the target price, the fee amount taken is simply the difference between the input and output amounts.
            feeAmountTaken = MyCustomFullMath.mulDivRoundUp(amountIn, feePips, 1e6 - feePips);
        }
    }
}

