// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library SqrtPriceMath {
    function getAmount0Delta(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity, bool roundUp)
        internal
        pure
        returns (uint256 amount0)
    {}
    function getAmount1Delta(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity, bool roundUp)
        internal
        pure
        returns (uint256 amount1)
    {}

    function getNextSqrtPriceFromInput(uint160 sqrtPX96, uint256 amountIn, uint128 liquidity, bool zeroForOne)
        internal
        pure
        returns (uint160 sqrtQX96)
    {}
    function getNextSqrtPriceFromOutput(uint160 sqrtPX96, uint256 amountOut, uint128 liquidity, bool zeroForOne)
        internal
        pure
        returns (uint160 sqrtQX96)
    {}
}
