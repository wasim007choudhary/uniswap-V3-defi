// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";

/*import {MyCustomFullMath} from "contracts/coreUV3/library/MyCustomFullMATH.sol";
import {UNISWAP_V3_POOL_USDC_WETH_500} from "Constants.sol";
import {IUV3Pool} from "contracts/coreUV3/Interfaces/IUV3Pool.sol";*/
import {TickMathCaller} from "contracts/ForTesting/CallingTicKmATH.sol";

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
//SpotPriceTest
contract TickMathOptimizationTest is Test {
    /*  /// @notice Reference to the Uniswap V3 USDC/WETH 0.05% pool.
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
       *
      function test_getSpotPriceFromSqrtPriceX96() public view {
          uint256 price = 0;
          (uint160 sqrtPriceX96,,,,,,) = poolIUV3.slot0();

          price = MyCustomFullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, Q96);
          price = 1e12 * 1e18 * Q96 / price;

          assertGt(price, 0, "price = 0");
          console2.log("price %e", price);
      }*/
    /*function testOriginal() public pure returns (uint160) {
        uint160 P = TickMath.getSqrtRatioAtTick(0);
        return P;
    }*/
    /* function testOptimized() public pure returns (uint160) {
         uint160 P = TickMath.getOptimzedSqrtRatioAtTick(0);
         return P;
     }*/
    /*  function testRestOriginal() public pure returns (uint160) {
              uint256 absTick = 0;

              uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;

              uint160 sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));

              return sqrtPriceX96;
          }

          function testRestOptimized() public pure returns (uint160) {
              uint24 absTick = 0;

              uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;

              uint160 sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));

              return sqrtPriceX96;
          }*/
    TickMathCaller caller;

    function setUp() public {
        caller = new TickMathCaller();
    }

    function testGasOriginal() public {
        caller.original(1);
    }

    function testGasOptimized() public {
        caller.optimized(1);
    }

    function testGasHybrid() public {
        caller.hybrid(1);
    }

    /* function testFuzGasCom(int24 tick) public pure {
         //  tick = int24(bound(int256(tick), -887272, 887272));
         vm.assume(tick >= -887272 && tick <= 887272);

         uint160 original = TickMath.getSqrtRatioAtTick(tick);
         uint160 optimized = TickMath.getOptimzedSqrtRatioAtTick(tick);

         console2.log("Original :", original, "Optimized :", optimized);
     }*/
    ////////////////////////////////////////
    /* function testAbsOriginal() public pure returns (uint256) {
         int24 tick = -127;
         uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));

         // console2.log(absTick);
         require(absTick <= uint256(int256(TickMath.MAX_TICK)), "T");

         uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;

         if (absTick & 0x2 != 0) {
             ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
         }
         if (absTick & 0x4 != 0) {
             ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
         }
         if (absTick & 0x8 != 0) {
             ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
         }
         if (absTick & 0x10 != 0) {
             ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
         }

         if (absTick & 0x20 != 0) {
             ratio = (ratio * 0xff973b41fa98a081472e6896dfb254c0) >> 128;
         }
         if (absTick & 0x40 != 0) {
             ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
         }
         return ratio;
     }

     function testAbsOptimized() public pure returns (uint256) {
         int24 tick = -127;
         uint24 absTick = tick < 0 ? uint24(-(tick)) : uint24(tick);

         //  console2.log(absTick);
         require(absTick <= uint24(TickMath.MAX_TICK), "T");

         uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;

         if (absTick & 0x2 != 0) {
             ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
         }
         if (absTick & 0x4 != 0) {
             ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
         }
         if (absTick & 0x8 != 0) {
             ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
         }
         if (absTick & 0x10 != 0) {
             ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
         }
         if (absTick & 0x20 != 0) {
             ratio = (ratio * 0xff973b41fa98a081472e6896dfb254c0) >> 128;
         }
         if (absTick & 0x40 != 0) {
             ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
         }

         return ratio;
     }*/
}
