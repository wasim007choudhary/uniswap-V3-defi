// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {MyCustomSafeCast} from "contracts/coreUV3/library/MyCustomSafeCast.sol";
import {TickMath} from "contracts/coreUV3/library/TickMath.sol";
import {LiquidityMath} from "contracts/coreUV3/library/LiquidityMath.sol";

library Tick {
    using MyCustomSafeCast for int256;

    /**
     * @dev Tick Information stored for each initialized individual tick
     * @custom:dissection Visit : `notes/CoreLibFunctions/Tick.sol/1.struct.md` for compete reverse-engineering/dissection of this struct with examples etc
     */
    struct TickInfo {
        /// @notice The total liquidity from all positions that use this tick
        ///         as either their lower or upper boundary.
        /// @dev This value can never be negative because it represents the
        ///      total amount of position liquidity referencing this tick.
        uint128 liquidityGross;

        /// @notice The net change in active liquidity when this tick is crossed.
        /// @dev The value is signed because crossing a tick can either add or
        ///      remove liquidity depending on whether the tick is a lower or
        ///      upper boundary and on the direction of the price movement.
        int128 liquidityNet;

        /// @notice The cumulative fee growth per unit of liquidity for token0
        ///         on the other/outside side of this tick, relative to the
        ///         current tick.
        /// @dev "Outside" is relative and can refer to either the left or right
        ///      side of the tick depending on where the current tick is.
        ///      The value has relative meaning and depends on when this tick
        ///      was initialized.
        uint256 feeGrowthOutside0X128;

        /// @notice The cumulative fee growth per unit of liquidity for token1
        ///         on the other/outside side of this tick, relative to the
        ///         current tick.
        /// @dev "Outside" is relative and can refer to either the left or right
        ///      side of the tick depending on where the current tick is.
        ///      The value has relative meaning and depends on when this tick
        ///      was initialized.
        uint256 feeGrowthOutside1X128;

        /// @notice The cumulative tick value accumulated over time on the
        ///         other/outside side of this tick.
        /// @dev The outside side can be either the left or right side of the
        ///      tick depending on where the current tick is relative to it.
        ///      This value is used as part of Uniswap V3's time-weighted
        ///      oracle accounting.
        int56 tickCumulativeOutside;

        /// @notice The cumulative seconds spent per unit of liquidity on the
        ///         other/outside side of this tick.
        /// @dev "Outside" is relative and can refer to either the left or right
        ///      side of the tick depending on where the current tick is.
        ///      For example, if 10 seconds pass with 2 units of liquidity,
        ///      the conceptual seconds-per-liquidity value is 10 / 2 = 5.
        ///      The value is cumulative and is stored using X128 fixed-point
        ///      representation.
        uint160 secondsPerLiquidtyOutsideX128;

        /// @notice The cumulative number of seconds spent on the other/outside
        ///         side of this tick, relative to the current tick.
        /// @dev The outside side can be either the left or right side depending
        ///      on where the current tick is.
        uint32 secondOutside;

        /// @notice Whether this tick is currently initialized.
        /// @dev A tick is initialized when its gross liquidity is non-zero.
        ///      The boolean is also stored explicitly to help avoid unnecessary
        ///      storage writes during tick-crossing operations.
        bool initialized;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Calculates the maximum liquidity that can be stored at any individual tick
     *         for a given tick spacing.
     * @dev Determines the minimum and maximum valid ticks aligned to `tickSpacing`,
     *      calculates the total number of usable tick positions (including both
     *      endpoints), and divides the maximum `uint128` value by that count to
     *      derive the per-tick liquidity limit.
     * @param tickSpacing The spacing between usable/initializable ticks.
     * @return maxLiqPerTick The maximum `liquidityGross` that can be stored at one tick.
     *
     * @custom:dissection Visit : `notes/CoreLibFunctions/Tick.sol/2.tickSpacingToMaxLiquidityPerTick_Fun.md` in the repo for compete reverse-engineering/dissection of this struct with examples etc
     */
    function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing) internal pure returns (uint128 maxLiqPerTick) {
        int24 minValidTick = (TickMath.MIN_VALID_TICK / tickSpacing) * tickSpacing;

        int24 maxValidTick = (TickMath.MAX_VALID_TICK / tickSpacing) * tickSpacing;

        // This answers: How many usable tick positions exist between `minValidTick`
        // and `maxValidTick`?
        //
        // The `+1` is required because the division gives the number of gaps/intervals.
        // For example:
        //
        // A ... (1) ... B ... (2) ... C
        //
        // There are 2 gaps, but 3 tick positions: A, B, and C.
        uint24 maxMinTickDiff = uint24((maxValidTick - minValidTick) / tickSpacing) + 1;

        // Gives the maximum amount of liquidity that can be stored at one tick.
        // Conceptually, the maximum uint128 value is divided across the number
        // of usable tick positions to establish the per-tick liquidity limit.
        maxLiqPerTick = type(uint128).max / maxMinTickDiff;
    }
}
