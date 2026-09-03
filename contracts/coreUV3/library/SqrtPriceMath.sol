// SPDX-License-Identifier: MIT
import {MyCustomFullMath} from "contracts/coreUV3/library/MyCustomFullMATH.sol";
import {MyCustomMath} from "contracts/coreUV3/library/MyCustomMath.sol";
import {FixedPointQ96} from "contracts/coreUV3/library/FixedPoint96.sol";
import {MyCustomSafeCast} from "contracts/coreUV3/library/MyCustomSafeCast.sol";
import {MyCustomUnsafeMath} from "contracts/coreUV3/library/MyCustomUnsafeMath.sol";
pragma solidity ^0.8.20;

library SqrtPriceMath {
    function getNextSqrtPriceFromAmount0RoundingUp(uint160 sqrtPriceQ96, uint128 liquidity, uint256 amount, bool add)
        internal
        pure
        returns (uint160)
    {
        if (amount == 0) return sqrtPriceQ96; // no adding or removing liquidity, return current price
        uint256 numerator1 = uint256(liquidity) << FixedPointQ96.RESOLUTION;

        if (add) {
            uint256 product; // no need overflow check, new sio versions got that inbuilt unless using the unchecked block
            if ((product = amount * sqrtPriceQ96) / amount == sqrtPriceQ96) {}
            uint256 denominator = numerator1 + product;
        }
    }
}
