// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title MyCustomSafeCast
 *
 * @notice Provides safe functions for converting one integer type into
 *         another integer type without accidentally losing information.
 *
 * @dev Solidity allows explicit conversions such as:
 *
 *          uint256 → uint160
 *          int256  → int128
 *          uint256 → int256
 *
 *      But a smaller type cannot hold every value that a larger type can hold.
 *
 *      For example:
 *
 *          uint256 can hold much larger positive values than uint160.
 *
 *          int256 can hold a much larger positive and negative range
 *          than int128.
 *
 *      If we simply perform a narrowing conversion:
 *
 *          uint160(x)
 *
 *      or:
 *
 *          int128(x)
 *
 *      and the value does not fit, information can be lost.
 *
 *      This library prevents that problem by checking the conversion.
 *
 *      The basic idea is very simple:
 *
 *          1. Convert the value.
 *          2. Check whether the converted value is still the same value.
 *          3. If it changed, something was lost.
 *          4. Revert.
 *
 *      For example:
 *
 *          uint256 x = 100;
 *          uint160(x) = 100;
 *
 *          Nothing changed.
 *          The conversion is safe.
 *
 *      But if `x` is too large for uint160, the conversion cannot preserve
 *      the original value. The check detects that difference and reverts.
 *
 *      This is our Solidity 0.8.20 version of the safe-casting idea used
 *      by Uniswap V3's SafeCast library.
 *
 *      We intentionally made a few modifications for our 0.8.20 codebase.
 *
 *      The original Uniswap implementation uses `require` checks and was
 *      written for older Solidity versions.
 *
 *      Our implementation instead uses:
 *
 *          if (...) {
 *              revert CustomError();
 *          }
 *
 *      with custom errors.
 *
 *      This gives us explicit, named failure reasons while avoiding
 *      revert strings.
 *
 *      We also use Solidity 0.8.20 syntax and type information where
 *      appropriate.
 *
 *      IMPORTANT:
 *
 *      Solidity 0.8.x gives us checked arithmetic, but an explicit
 *      narrowing cast such as:
 *
 *          uint160(x)
 *
 *      does not automatically mean:
 *
 *          "revert if x does not fit."
 *
 *      Therefore, these checks are still necessary.
 *
 *      ---------------------------------------------------------------
 *      DETAILED DISSECTION
 *      ---------------------------------------------------------------
 *
 *      For a complete child-level breakdown of every function, including:
 *
 *          - why each cast is necessary
 *          - how the comparison detects lost information
 *          - uint256 → uint160
 *          - int256 → int128
 *          - uint256 → int256
 *          - integer ranges
 *          - overflow and underflow
 *          - why the original Uniswap code used `require`
 *          - why our 0.8.20 version uses custom errors and `if` + `revert`
 *          - gas considerations
 *          - the difference between signed and unsigned integers
 *
 *      see:
 *
 *          notes/CoreLibFunctions/SafeCast
 *
 *      That note contains the full function-by-function dissection written
 *      at both developer level and extremely simple "child level" so that
 *      the code can be understood without losing the technical details.
 */
library MyCustomSafeCast {
    /**
     * @notice Thrown when a uint256 value cannot safely fit into uint160.
     *
     * @dev This means the original uint256 value was larger than the
     *      maximum value that uint160 can represent.
     */
    error MyCustomSafeCast__toUint160__Overflow();

    /**
     * @notice Thrown when an int256 value cannot safely fit into int128.
     *
     * @dev This can happen when the value is:
     *
     *          - too large in the positive direction, or
     *          - too small in the negative direction.
     */
    error MyCustomSafeCast__toInt128__OutOfRange();

    /**
     * @notice Thrown when a uint256 value is too large to safely become int256.
     *
     * @dev A uint256 can represent values up to:
     *
     *          2^256 - 1
     *
     *      while the largest positive int256 value is:
     *
     *          2^255 - 1
     *
     *      Therefore, values greater than `2^255 - 1` cannot safely be
     *      converted from uint256 to int256.
     */
    error MyCustomSafeCast__toInt256__Overflow();

    /**
     * @notice Safely converts a uint256 value into uint160.
     *
     * @dev Think of this as trying to put a big box into a smaller box.
     *
     *      `uint256` has 256 bits available.
     *
     *      `uint160` has only 160 bits available.
     *
     *      So uint160 cannot hold every possible uint256 value.
     *
     *      We first perform the conversion:
     *
     *          z = uint160(x);
     *
     *      Then we ask:
     *
     *          "Did the value stay exactly the same?"
     *
     *      If:
     *
     *          z == x
     *
     *      the value survived the conversion perfectly.
     *
     *      If:
     *
     *          z != x
     *
     *      information was lost during the conversion, so we revert.
     *
     * @param x The uint256 value to convert.
     * @return z The same value safely represented as uint160.
     */
    function toUint160(uint256 x) internal pure returns (uint160 z) {
        z = uint160(x);
        if (z != x) {
            revert MyCustomSafeCast__toUint160__Overflow();
        }
    }

    /**
     * @notice Safely converts an int256 value into int128.
     *
     * @dev `int256` has a much larger signed range than `int128`.
     *
     *      int128 can represent:
     *
     *          -2^127  to  2^127 - 1
     *
     *      while int256 can represent:
     *
     *          -2^255  to  2^255 - 1
     *
     *      We first convert the value:
     *
     *          z = int128(x);
     *
     *      Then we compare it with the original value:
     *
     *          z != x
     *
     *      If they are different, the value could not fit inside int128
     *      without losing information.
     *
     *      Therefore, we revert.
     *
     *      This protects against both:
     *
     *          positive overflow
     *
     *      and:
     *
     *          negative underflow
     *
     * @param x The int256 value to convert.
     * @return z The same value safely represented as int128.
     */
    function toInt128(int256 x) internal pure returns (int128 z) {
        z = int128(x);
        if (z != x) {
            revert MyCustomSafeCast__toInt128__OutOfRange();
        }
    }

    /**
     * @notice Safely converts a uint256 value into int256.
     *
     * @dev This conversion is different from the two narrowing conversions
     *      above because it changes from an unsigned integer to a signed
     *      integer.
     *
     *      uint256 can represent:
     *
     *          0 to 2^256 - 1
     *
     *      int256 can represent:
     *
     *          -2^255 to 2^255 - 1
     *
     *      Because `x` is uint256, it can never be negative.
     *
     *      Therefore, the only question we need to ask is:
     *
     *          "Is x small enough to fit inside the positive range of int256?"
     *
     *      The largest positive int256 value is:
     *
     *          2^255 - 1
     *
     *      So if:
     *
     *          x > 2^255 - 1
     *
     *      the conversion is unsafe and we revert.
     *
     *      If the value is inside the valid range, we safely perform:
     *
     *          z = int256(x);
     *
     * @param x The uint256 value to convert.
     * @return z The same value safely represented as int256.
     */
    function toInt256(uint256 x) internal pure returns (int256 z) {
        if (x > 2 ** 255 - 1) {
            revert MyCustomSafeCast__toInt256__Overflow();
        }
        z = int256(x);
    }
}
