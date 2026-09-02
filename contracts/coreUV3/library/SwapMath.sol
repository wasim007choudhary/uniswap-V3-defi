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

        bool max = nextSqrtRatioPriceX96 == targetSqrtRatioPriceX96;
    }
}

