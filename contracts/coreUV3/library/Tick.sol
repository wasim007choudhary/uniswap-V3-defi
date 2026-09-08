// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {MyCustomSafeCast} from "contracts/coreUV3/library/MyCustomSafeCast.sol";
import {TickMath} from "contracts/coreUV3/library/TickMath.sol";
import {LiquidityMath} from "contracts/coreUV3/library/LiquidityMath.sol";

library Tick {
    using MyCustomSafeCast for int256;

    struct TickInfo {


        uint128 liquidityGrossTotalOfTheTick;
        int128 liquidityNet;

        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;

        int56 tickCumulativeOutside;

        uint160 secondsPerLiquidtyOutsideX128;
        uint32 secondOutside;

        bool initialized;
    }
}
