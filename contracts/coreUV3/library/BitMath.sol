// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

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
}
