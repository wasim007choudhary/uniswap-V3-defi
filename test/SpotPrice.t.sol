// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {MyCustomFullMath} from "contracts/coreUV3/library/MyCustomFullMATH.sol";
import {UNISWAP_V3_POOL_USDC_WETH_500} from "Constants.sol";
import {IUV3Pool} from "contracts/coreUV3/Interfaces/IUV3Pool.sol";

/**
 * @title SpotPriceTest
 * @author Wasim
 * @notice Demonstrates how to derive the spot price of WETH in terms of USDC
 *         using Uniswap V3's `sqrtPriceX96`.
 *
 * @dev The pool does NOT store the spot price directly.
 *
 *      Instead, it stores:
 *
 *          sqrtPriceX96 = √P × Q96
 *
 *      where:
 *
 *          P = WETH / USDC
 *
 *      Since this exercise asks for:
 *
 *          USDC / WETH
 *
 *      we first recover P, then mathematically flip the ratio to obtain
 *      its inverse (USDC / WETH), adjust for the 18 vs. 6 decimal
 *      difference, and finally return the result with 18-decimal precision.
 */
contract SpotPriceTest is Test {
    /// @notice Reference to the Uniswap V3 USDC/WETH 0.05% pool.
    IUV3Pool private immutable poolIUV3 = IUV3Pool(UNISWAP_V3_POOL_USDC_WETH_500);

    /// @notice USDC uses 6 decimal places.
    uint256 public constant USDC_DECIMALS = 1e6;

    /// @notice WETH uses 18 decimal places.
    uint256 public constant WETH_DECIMALS = 1e18;

    /// @notice Fixed-point scaling factor (2^96) used throughout Uniswap V3.
    uint256 public constant Q96 = 1 << 96; // Same as 2 ** 96

    /**
     * @notice Calculates the spot price of WETH in terms of USDC.
     *
     * @dev Mathematical derivation:
     *
     *      Pool stores:
     *
     *          sqrtPriceX96 = √P × Q96
     *
     *      where:
     *
     *          P = WETH / USDC
     *
     *      Squaring both sides:
     *
     *          sqrtPriceX96² = P × Q96²
     *
     *      Instead of dividing by Q96² immediately, we compute:
     *
     *          sqrtPriceX96² / Q96
     *
     *      which gives:
     *
     *          price = P × Q96
     *
     *      To obtain the price we actually want:
     *
     *          price = P × Q96
     *
     *          price / Q96 = P
     *
     *          Q96 / price = 1 / P
     *
     *      Since:
     *
     *          P = WETH / USDC
     *
     *      then:
     *
     *          1 / P = USDC / WETH
     *
     *      Finally:
     *
     *          × 1e12
     *              Converts USDC's 6-decimal representation to the
     *              same 18-decimal scale as WETH.
     *
     *          × 1e18
     *              Returns the final spot price using 18-decimal
     *              fixed-point precision.
     *
     *      Although the implementation multiplies by:
     *
     *          1e12 × 1e18 = 1e30
     *
     *      the returned value is NOT in 30 decimals.
     *
     *      WETH already contributes 18 decimals, so after the ratio
     *      is evaluated, the effective result is an 18-decimal
     *      fixed-point price.
     *
     * @dev Example:
     *
     *      Console output:
     *
     *          1.875705671124314989654e21
     *
     *      Human-readable value:
     *
     *          1875.705671124314989654 USDC per WETH
     */
    function test_getSpotPriceFromSqrtPriceX96() public {
        uint256 price = 0;
        IUV3Pool.Slot0 memory slot0 = poolIUV3.slot0();

        price = MyCustomFullMath.mulDiv(slot0.sqrtPriceX96, slot0.sqrtPriceX96, Q96);
        price = 1e12 * 1e18 * Q96 / price;

        assertGt(price, 0, "price = 0");
        console2.log("price %e", price);
    }
}
