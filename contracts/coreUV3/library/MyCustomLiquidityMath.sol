// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Liquidity Math Library
 * @notice Provides arithmetic functions for updating liquidity using signed deltas.
 */
library MyCustomLiquidityMath {
    /**
     * @notice Adds a signed liquidity delta to the current liquidity.
     * @dev A negative delta decreases liquidity by its absolute value, while a
     *      non-negative delta increases liquidity. Solidity 0.8.20 automatically
     *      reverts on arithmetic overflow and underflow.
     * @param x The liquidity before applying the delta.
     * @param y The signed liquidity delta to apply to `x`.
     * @return z The resulting liquidity after applying `y` to `x`.
     */
    function deltaAddition(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            z = x - uint128(-y);
        } else {
            z = x + uint128(y);
        }
    }
}
