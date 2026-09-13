// contracts/ForTesting/TickMathCaller.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TickMath} from "./check.sol";

contract TMCaller {
    function callOriginal(int24 tick) external pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(tick);
    }

    function callOptimized(int24 tick) external pure returns (uint160) {
        return TickMath.getOptimzedSqrtRatioAtTick(tick);
    }
}

