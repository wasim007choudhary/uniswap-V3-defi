// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title BitMath
 * @notice Provides bit-level utilities for efficiently finding the highest and lowest
 *         set `1` bit inside a `uint256`.
 *
 * @dev These functions are used by the Tick Bitmap / next initialized tick algorithm
 *      to locate initialized tick positions efficiently inside a 256-bit bitmap word.
 *
 *      Highly recommended to go through:
 *      `notes/5.TickBitmap & NextTickAlgo/1.Conceptual`
 *      before coming here to understand the Tick Bitmap and next initialized tick
 *      concepts behind these bit-level operations.
 */

library BitMath {
    /**
     * @notice Finds the position of the highest set `1` bit in a non-zero `uint256`.
     * @dev Treats `x` as a 256-bit binary value where bit positions start at `0`
     *      from the rightmost bit.
     *
     *      The function progressively narrows the search using chunks of
     *      `128`, `64`, `32`, `16`, `8`, `4`, and `2` bits.
     *
     *      Whenever a higher chunk contains the highest `1` bit, `x` is shifted
     *      right to remove the positions that have already been searched, while
     *      `highest1BitPos` remembers how many bit positions were skipped.
     *
     *      The final result is the bit position of the highest set `1` bit.
     *
     *      For example:
     *
     *          x = 1011₂
     *
     *          The highest `1` is at bit position `3`, so the function returns `3`.
     *
     *      This is used by the Tick Bitmap / next initialized tick search to find
     *      the position of the highest initialized bit inside a masked bitmap word.
     *
     *
     * @dev The returned position satisfies the following property:
     *
     *      `x >= 2**highest1BitPos`
     *
     *      and
     *
     *      `x < 2**(highest1BitPos + 1)`
     *
     *      This means the returned bit position is the highest set `1` in `x`.
     *
     * @param x The non-zero `uint256` value whose highest set `1` bit is searched for.
     * @return highest1BitPos The zero-based position of the highest set `1` bit in `x`.
     *
     * @custom:dissection For Deep dissection and reverse-engineering visit:
     *      notes/5.TickBitmap & NextTickAlgo/2.CodeBase/1.mostSignificantBit.md
     */
    function mostSignificantBit(uint256 x) internal pure returns (uint8 highest1BitPos) {
        require(x > 0);
        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            highest1BitPos += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            highest1BitPos += 64;
        }

        if (x >= 0x100000000) {
            x >>= 32;
            highest1BitPos += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            highest1BitPos += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            highest1BitPos += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            highest1BitPos += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            highest1BitPos += 2;
        }

        if (x >= 0x2) {
            highest1BitPos += 1;
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * @notice Returns the position of the least significant set bit (`1`) in a non-zero `uint256`.
     *
     * @dev
     * Treats the 256-bit value as a box of bit positions `255` down to `0` and searches
     * for the lowest-position `1`.
     *
     * The search starts with `lowest1bitPos = 255` and progressively narrows the possible location
     * of the lowest `1` by checking whether the lower half of the remaining search region
     * contains any set bit:
     *
     * - If the lower region contains a `1`, the answer must be inside that region,
     *   so `lowest1bitPos` is reduced by the size of the region.
     * - If the lower region contains no `1`, that region is discarded by shifting `x`
     *   to the right, bringing the remaining upper region down for the next check.
     *
     * The search progressively narrows through:
     *
     * `128 → 64 → 32 → 16 → 8 → 4 → 2 → 1`
     *
     * `type(uintN).max` and the hexadecimal masks (`0xf`, `0x3`, and `0x1`) are used
     * to inspect the corresponding lower bits of `x`.
     *
     * For example:
     *
     * `x = 1`:
     * `lowest1bitPos` starts at `255` and is progressively reduced
     * `255 → 127 → 63 → 31 → 15 → 7 → 3 → 1 → 0`,
     * therefore the least significant set bit is bit `0`.
     *
     * `x = 2²²⁰`:
     * the lower regions are discarded by shifting `x` until the set bit is brought
     * into the smaller search regions, while `lowest1bitPos` remains `255` until a region containing
     * the set bit is selected. The final result is `220`.
     *
     * The function requires `x > 0` because a zero value contains no set bit and therefore
     * has no least significant bit position to return.
     *
     * @dev The returned position satisfies the following property:
     *
     *      `(x & 2**lowest1bitPos) != 0`
     *
     *      and
     *
     *      `(x & (2**lowest1bitPos - 1)) == 0`
     *
     *      This means the returned bit position is actually set to `1`,
     *      while every bit position below it is `0`. Therefore, `lowest1bitPos`
     *      is the least significant set bit of `x`.
     *
     * @param x The non-zero `uint256` value whose lowest-position set bit is being located.
     * @return lowest1bitPos The bit position of the least significant set bit, ranging from `0` to `255`.
     *
     * @custom:reverse-engineering
     * For a complete line-by-line dissection and reverse engineering of this function, visit:
     * `notes/5.TickBitmap & NextTickAlgo/2.CodeBase/2.leastSignificantBit.md`
     */
    function leastSignificantBit(uint256 x) internal pure returns (uint8 lowest1bitPos) {
        require(x > 0);
        lowest1bitPos = 255;

        if (x & type(uint128).max > 0) {
            lowest1bitPos -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            lowest1bitPos -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            lowest1bitPos -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            lowest1bitPos -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            lowest1bitPos -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            lowest1bitPos -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            lowest1bitPos -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) {
            lowest1bitPos -= 1;
        }
    }
}
