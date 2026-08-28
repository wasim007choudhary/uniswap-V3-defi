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
        uint24 feepips
    ) internal pure returns(){}
}
