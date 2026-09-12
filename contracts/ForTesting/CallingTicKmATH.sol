// contracts/ForTesting/TickMathCaller.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TickMath} from "./check.sol";

contract TickMathCaller {
    function original(int24 tick) external pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(tick);
    }

    function optimized(int24 tick) external pure returns (uint160) {
        return TickMath.getOptimzedSqrtRatioAtTick(tick);
    }

    function hybrid(int24 tick) external pure returns (uint160) {
        return TickMath.getHybridSqrtRatioAtTick(tick);
    }
}
