// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {BitMath} from "contracts/coreUV3/library/BitMath.sol";

library TickBitMap {
    /**
     * @notice Returns the bitmap word position and bit position for a given tick.
     *
     * @dev A bitmap is made of `uint256` words, and each word contains 256 bits.
     *      Since `256 = 2^8`, every word represents 256 consecutive bit positions:
     *      `0` through `255`.
     *
     *      The function splits the tick into two parts:
     *
     *      1. `wordPos` tells us **which 256-bit word** contains the tick.
     *      2. `bitPos` tells us **which bit inside that word** represents the tick.
     *
     *      `tick / 256` can also be written as `tick >> 8` because shifting right
     *      by 8 binary positions is equivalent to dividing by `2^8 = 256`
     *      for the relevant integer-position calculation.
     *
     *      For `bitPos`, `tick % 256` gives the position within the 256-value group.
     *      The result is first converted from `int24` to `uint24`, and only then
     *      to `uint8`, because modern Solidity (`0.8+`) does not allow the direct
     *      `int24` → `uint8` conversion when both the signedness and width change.
     *
     *      In simple terms:
     *
     *          tick
     *           ↓
     *      ┌────┴────┐
     *      ↓         ↓
     *   wordPos    bitPos
     *      ↓         ↓
     *   which      which
     *   word?      bit?
     *
     *      This gives the exact location of a tick inside the Tick Bitmap.
     *
     * @param tick The tick whose bitmap position is being calculated.
     * @return wordPos The signed index of the `uint256` bitmap word containing the tick.
     * @return bitPos The bit position inside that word, from `0` to `255`.
     *
     * @custom:dissection For complete line-by-line dissection and reverse-engineering, visit:
     *      `notes/5.TickBitmap & NextTickAlgo/2.CodeBase/2.TickBitMap Library/1.PositionFun.md`
     */
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick / 256); // or >> 8 same ...as 8bits = 256 in other wrds 0....255...total equals 256 positions
        bitPos = uint8(uint24(tick % 256)); // sol 0.8+ dpesnt all direct conversion...int24..-> uint24..then only uint8..not directly int24->uint8..it breaks in modern soldity
    }
}
