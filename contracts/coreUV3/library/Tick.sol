// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {MyCustomSafeCast} from "contracts/coreUV3/library/MyCustomSafeCast.sol";
import {TickMath} from "contracts/coreUV3/library/TickMath.sol";
import {MyCustomLiquidityMath} from "contracts/coreUV3/library/MyCustomLiquidityMath.sol";

library Tick {
    error Tick__updateTick__LiquidityLimitCrossedForASingleTick();

    using MyCustomSafeCast for int256;

    /**
     * @dev Tick Information stored for each initialized individual tick
     * @custom:dissection Visit : `notes/CoreLibFunctions/Tick.sol/1.struct.md` for compete reverse-engineering/dissection of this struct with examples etc
     */
    struct TickInfo {
        /**
         * @notice The total liquidity from all positions that use this tick
         *          as either their lower or upper boundary.
         *  @dev This value can never be negative because it represents the
         *       total amount of position liquidity referencing this tick.
         */
        uint128 liquidityGross;

        /**
         * @notice The net change in active liquidity when this tick is crossed.
         *  @dev The value is signed because crossing a tick can either add or
         *       remove liquidity depending on whether the tick is a lower or
         *      upper boundary and on the direction of the price movement.
         */
        int128 liquidityNet;

        /**
         * @notice The cumulative fee growth per unit of liquidity for token0
         *         on the other/outside side of this tick, relative to the
         *         current tick.
         * @dev "Outside" is relative and can refer to either the left or right
         *      side of the tick depending on where the current tick is.
         *      The value has relative meaning and depends on when this tick
         *      was initialized.
         */
        uint256 feeGrowthOutside0X128;

        /**
         * @notice The cumulative fee growth per unit of liquidity for token1
         *          on the other/outside side of this tick, relative to the
         *          current tick.
         *  @dev "Outside" is relative and can refer to either the left or right
         *       side of the tick depending on where the current tick is.
         *       The value has relative meaning and depends on when this tick
         *       was initialized.
         */
        uint256 feeGrowthOutside1X128;

        /**
         * @notice The cumulative tick value accumulated over time on the
         *          other/outside side of this tick.
         *  @dev The outside side can be either the left or right side of the
         *       tick depending on where the current tick is relative to it.
         *       This value is used as part of Uniswap V3's time-weighted
         *       oracle accounting.
         */
        int56 tickCumulativeOutside;

        /**
         * @notice The cumulative seconds spent per unit of liquidity on the
         *          other/outside side of this tick.
         *  @dev "Outside" is relative and can refer to either the left or right
         *       side of the tick depending on where the current tick is.
         *       For example, if 10 seconds pass with 2 units of liquidity,
         *       the conceptual seconds-per-liquidity value is 10 / 2 = 5.
         *       The value is cumulative and is stored using X128 fixed-point
         *       representation.
         */
        uint160 secondsPerLiquidtyOutsideX128;

        /**
         * @notice The cumulative number of seconds spent on the other/outside
         *          side of this tick, relative to the current tick.
         *  @dev The outside side can be either the left or right side depending
         *       on where the current tick is.
         */
        uint32 secondOutside;

        /**
         * @notice Whether this tick is currently initialized.
         *  @dev A tick is initialized when its gross liquidity is non-zero.
         *       The boolean is also stored explicitly to help avoid unnecessary
         *       storage writes during tick-crossing operations.
         */
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

    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Calculates the cumulative fee growth inside an LP's tick range.
     * @dev
     *      A = tickLower, B = tickUpper, C = currentTick.
     *
     *      Below A always means the left side of A.
     *      Above B always means the right side of B.
     *
     *      C only tells us how to interpret the stored feeGrowthOutside:
     *      - If C >= A, use lower.feeGrowthOutside directly for below.
     *      - If C < A, use feeGrowthGlobal - lower.feeGrowthOutside for below.
     *      - If C < B, use upper.feeGrowthOutside directly for above.
     *      - If C >= B, use feeGrowthGlobal - upper.feeGrowthOutside for above.
     *
     *      Finally:
     *      feeGrowthInside = feeGrowthGlobal - feeGrowthBelow - feeGrowthAbove.
     *
     *      The calculation is done separately for Token0 and Token1.
     *
     *
     * @param mapRef Mapping containing information for every initialized tick.
     * @param tickLower Lower tick of the LP position.
     * @param tickUpper Upper tick of the LP position.
     * @param currentTick Current pool tick.
     * @param feeGrowthGlobal0x128 Global cumulative fee growth for Token0 in X128 format.
     * @param feeGrowthGlobal1x128 Global cumulative fee growth for Token1 in X128 format.
     * @return feeGrowthInside0x128 Cumulative fee growth inside the range for Token0.
     * @return feeGrowthInside1x128 Cumulative fee growth inside the range for Token1.
     *
     *
     * @custom:dissection Visit : `notes/CoreLibFunctions/Tick.sol/3.getFeeGrowthInside.md` in the repo for compete reverse-engineering/dissection of this struct with examples etc.
     */
    function getFeeGrowthInside(
        mapping(int24 => Tick.TickInfo) storage mapRef,
        int24 tickLower,
        int24 tickUpper,
        int24 currentTick,
        uint256 feeGrowthGlobal0x128,
        uint256 feeGrowthGlobal1x128
    ) internal view returns (uint256 feeGrowthInside0x128, uint256 feeGrowthInside1x128) {
        Tick.TickInfo storage lower = mapRef[tickLower];
        Tick.TickInfo storage upper = mapRef[tickUpper];

        uint256 feeGrowthBelowLowe0x128;
        uint256 feeGrowthBelowLower1x128;

        if (currentTick >= tickLower) {
            feeGrowthBelowLowe0x128 = lower.feeGrowthOutside0X128;
            feeGrowthBelowLower1x128 = lower.feeGrowthOutside1X128;
        } else {
            feeGrowthBelowLowe0x128 = feeGrowthGlobal0x128 - lower.feeGrowthOutside0X128;
            feeGrowthBelowLower1x128 = feeGrowthGlobal1x128 - lower.feeGrowthOutside1X128;
        }

        uint256 feeGrowthAboveUpper0x128;
        uint256 feeGrowthAboveUpper1x128;

        /**
         * @dev Let A = lower, B = upper, C = current.
         *
         *      Below A = LEFT of A.
         *      Above B = RIGHT of B.
         *
         *      C does not change what below or above mean.
         *      C only tells us how to read feeGrowthOutside.
         *
         *      Below:
         *      C >= A → OUTSIDE
         *      C < A  → GLOBAL - OUTSIDE
         *
         *      Above:
         *      C < B  → OUTSIDE
         *      C >= B → GLOBAL - OUTSIDE
         *
         *      🔥 IMPORTANT:
         *
         *      When C is inside the range:
         *
         *              BELOW              INSIDE              ABOVE
         *
         *      ──────────A══════════════════C══════════════════B────────→
         *                ↑                                      ↑
         *              lower                                  upper
         *
         *      If we look at A:
         *
         *      <----till protocl line ends───────────────|A|
         *          BELOW
         *          OUTSIDE
         *
         *      So for A, below A is the outside side.
         *
         *      If we look at B:
         *
         *                                   |B|───────────────>till protocl line ends--->
         *                                       ABOVE
         *                                       OUTSIDE
         *
         *      So for B, above B is the outside side.
         *
         *      Therefore, when C is inside:
         *
         *      A → BELOW = OUTSIDE
         *      B → ABOVE = OUTSIDE
         *
         *
         *      🔥 Now when C is outside the range:
         *
         *      C          A                         B
         *      ↓          ↓                         ↓
         *      ●──────────●═════════════════════════●────────→
         *
         *      C is below the range.
         *
         *      For A, the outside side is considered from A towards the RIGHT:
         *
         *      C          A                         B
         *      ↓          ↓                         ↓
         *      ●──────────●═════════════════════════●────────→
         *                 │
         *                 └──────────────────────────────→
         *                          OUTSIDE
         *
         *      This includes B and everything to the right until the line ends.
         *
         *      Therefore:
         *
         *      GLOBAL - OUTSIDE = BELOW A
         *
         *
         *      🔥 If C is above the range:
         *
         *      A                         B          C
         *      ↓                         ↓          ↓
         *      ●═════════════════════════●──────────●────────→
         *
         *      C is above the range.
         *
         *      For B, the outside side is considered from B towards the LEFT:
         *
         *      A                         B          C
         *      ↓                         ↓          ↓
         *      ●═════════════════════════●──────────●────────→
         *      │                         │
         *      ←─────────────────────────┘
         *                OUTSIDE
         *
         *      This includes A, the whole range, and everything below A.
         *
         *      Therefore:
         *
         *      GLOBAL - OUTSIDE = ABOVE B
         *
         *
         *      ⚠️ But remember:
         *
         *      Below A and Above B do NOT change with C.
         *
         *      Below A always means:
         *
         *      <──────── A
         *         BELOW
         *
         *      Above B always means:
         *
         *      B ─────────→
         *          ABOVE
         *
         *      Below A = below the range.
         *      Above B = above the range.
         *
         *      Their meaning has nothing to do with where C currently is.
         *
         *      What changes with C is only how the stored
         *      feeGrowthOutside value is interpreted.
         *
         *
         *      🧒 Simple way to remember:
         *
         *      Below / Above = fixed place.
         *
         *      Outside = stored checkpoint.
         *
         *      C = tells us which way to read that checkpoint.
         *
         *
         *      Finally:
         *
         *      INSIDE = GLOBAL - BELOW - ABOVE
         */
        if (currentTick < tickUpper) {
            feeGrowthAboveUpper0x128 = upper.feeGrowthOutside0X128;
            feeGrowthAboveUpper1x128 = upper.feeGrowthOutside1X128;
        } else {
            feeGrowthAboveUpper0x128 = feeGrowthGlobal0x128 - upper.feeGrowthOutside0X128;
            feeGrowthAboveUpper1x128 = feeGrowthGlobal0x128 - upper.feeGrowthOutside1X128;
        }

        feeGrowthInside0x128 = feeGrowthGlobal0x128 - feeGrowthBelowLowe0x128 - feeGrowthAboveUpper0x128;
        feeGrowthInside1x128 = feeGrowthGlobal0x128 - feeGrowthBelowLower1x128 - feeGrowthAboveUpper1x128;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * @notice Updates the information of one specific tick.
     *
     * @dev
     * This function:
     *
     * 1. Gets the tick's storage record.
     * 2. Calculates the new liquidityGross after adding/removing liquidity.
     * 3. Checks that the tick does not exceed its maximum allowed liquidity.
     * 4. Checks whether the tick changed between zero and non-zero liquidity.
     * 5. If the tick was not initialized before, initializes its accounting data.
     * 6. Stores the new liquidityGross.
     * 7. Updates liquidityNet:
     *    - lower tick  → adds liquidityDelta
     *    - upper tick  → subtracts liquidityDelta
     *
     * @param mapRef The mapping that stores the information of every tick.
     * @param tick The specific tick whose information will be updated.
     * @param currentTick The pool's current tick. Used to know where the current price is relative to this tick.
     * @param liquidityDelta The amount of liquidity being added or removed.
     *                     Positive means adding liquidity.
     *                     Negative means removing liquidity.
     * @param feeGrowthGlobal0x128 The pool's current global fee growth for token0.
     * @param feeGrowthGlobal1x128 The pool's current global fee growth for token1.
     * @param secondsPerLiquidityCumulativeX128 The pool's current cumulative seconds per unit of liquidity.
     * @param tickCumulative The pool's current cumulative tick value used for time-based accounting.
     * @param time The current block timestamp.
     * @param upperBoundry Tells whether this tick is the upper boundary of the position.
     *                     true  = upper tick
     *                     false = lower tick
     * @param maxLiquidityAllowedPerTick The maximum liquidityGross allowed at this tick.
     *
     * @return flipped True if the tick changed between zero and non-zero liquidityGross.
     *                 False if its zero/non-zero state stayed the same.
     *
     *
     * @custom:dissection Visit : `notes/CoreLibFunctions/Tick.sol/4.updateFun.md` in the repo for compete reverse-engineering/dissection of this struct with examples etc.
     */
    function updateTick(
        mapping(int24 => Tick.TickInfo) storage mapRef,
        int24 tick,
        int24 currentTick,
        int128 liquidityDelta,
        uint256 feeGrowthGlobal0x128,
        uint256 feeGrowthGlobal1x128,
        uint160 secondsPerLiquidityCumulativeX128,
        int56 tickCumulative,
        uint32 time,
        bool upperBoundry,
        uint128 maxLiquidityAllowedPerTick
    ) internal returns (bool flipped) {
        TickInfo storage tickInfo = mapRef[tick];

        uint128 liquidityGrossBeforeDelta = tickInfo.liquidityGross;
        uint128 liquidityGrossAfterDelta =
            MyCustomLiquidityMath.deltaAddition(liquidityGrossBeforeDelta, liquidityDelta);

        if (liquidityGrossAfterDelta > maxLiquidityAllowedPerTick) {
            revert Tick__updateTick__LiquidityLimitCrossedForASingleTick();
        }

        flipped = (liquidityGrossAfterDelta == 0) != (liquidityGrossBeforeDelta == 0);

        if (liquidityGrossBeforeDelta == 0) {
            if (currentTick >= tick) {
                tickInfo.feeGrowthOutside0X128 = feeGrowthGlobal0x128;
                tickInfo.feeGrowthOutside1X128 = feeGrowthGlobal1x128;
                tickInfo.secondsPerLiquidtyOutsideX128 = secondsPerLiquidityCumulativeX128;
                tickInfo.tickCumulativeOutside = tickCumulative;
                tickInfo.secondOutside = time;
            }
            tickInfo.initialized = true;
        }
        tickInfo.liquidityGross = liquidityGrossAfterDelta;

        if (upperBoundry) {
            tickInfo.liquidityNet -= liquidityDelta;
        } else {
            tickInfo.liquidityNet += liquidityDelta;
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * @notice Clears all stored data for a specific tick.
     * @dev Resets the TickInfo at the given tick to its default values.
     * @param mapRef The mapping that stores information for each tick.
     * @param tick The specific tick whose data will be cleared.
     *
     * @custom:dissection Visit : `notes/CoreLibFunctions/Tick.sol/5.clearFun.md` in the repo for compete reverse-engineering/dissection of this struct with examples etc.
     *
     */
    function clearTickData(mapping(int24 => Tick.TickInfo) storage mapRef, int24 tick) internal {
        delete mapRef[tick];
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
}
