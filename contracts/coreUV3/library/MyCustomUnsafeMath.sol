// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library MyCustomUnsafeMath {
    /**
     * @note This library has been made safe in our Solidity 0.8.20 version.
     *       However, we keep the `UnsafeMath` name to respect Uniswap V3's
     *       original naming convention and maintain consistency with the
     *       original implementation.
     *
     *  Respect to thew OGs
     */
    /**
     * @notice Returns the ceiling of `a / b`.
     *
     * @dev This function is made to perform integer division while rounding
     *      the result UP whenever a remainder exists.
     *
     *      Solidity integer division normally rounds DOWN because it removes
     *      the fractional part.
     *
     *      For example:
     *
     *          10 / 3 = 3 remainder 1
     *          divRoundingUp(10, 3) = 4
     *
     *          12 / 3 = 4 remainder 0
     *          divRoundingUp(12, 3) = 4
     *
     *      The logic is:
     *
     *          a / b
     *          +
     *          1 if a % b > 0
     *          0 if a % b == 0
     *
     *      This function is made because some Uniswap V3 calculations must
     *      round an amount UP rather than allowing Solidity's normal integer
     *      division to round it DOWN.
     *
     *      For example, when calculating an amount of token input required,
     *      rounding down could result in an amount that is slightly too small.
     *      Rounding UP ensures the calculated input is sufficient.
     *
     *      This is our custom Solidity 0.8.20 implementation of the same
     *      `divRoundingUp()` functionality used by Uniswap V3's `UnsafeMath`
     *      library.
     *
     *      Original Uniswap V3 NatSpec:
     *
     *      @notice Returns ceil(x / y) , ceil means rounding up if you were wonderring
     *
     *
     *      Unlike the original Uniswap implementation, which uses inline
     *      assembly, this version uses normal Solidity 0.8.20 arithmetic.
     *
     *      Why this library is called `UnsafeMath`:
     *
     *     @dev The original Uniswap library intentionally performs this small
     *      calculation without additional safety checks and expects the caller
     *      to provide valid inputs. In our Solidity 0.8.20 implementation,
     *      division by zero automatically reverts by Panic(0x12).
     *
     *      This helper is used by SqrtPriceMath wherever a division must be
     *      rounded UP.
     *
     * @param a The dividend.
     * @param b The divisor.
     * @return c The result of `a / b`, rounded UP whenever a remainder exists.
     */
    /*
    * ============================================================
    * OUR CUSTOM SOLIDITY 0.8.20 IMPLEMENTATION
    * ============================================================
    *
    * Uniswap V3:
    *
    *  function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
          assembly {
             z := add(div(x, y), gt(mod(x, y), 0))
           }
    }
    *
    * Our Solidity 0.8.20 version:
    */
    function divRoundingUp(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a / b + (a % b > 0 ? 1 : 0);

        /*same as
        if (a % b == 0) {
            return c = a / b;
        } else {
        return c = a / b + 1;
        } */
    }
}
