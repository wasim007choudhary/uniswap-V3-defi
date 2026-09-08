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

    /**
     * @notice Flips the initialized state for a given tick from false to true, or vice versa.
     * @dev The tick must be exactly divisible by tickSpacing so that the compressed tick
     *      represents a valid usable tick. The compressed tick is converted into a bitmap
     *      word position and bit position, then a single-bit mask is created and XORed
     *      against the corresponding bitmap word to toggle that bit.
     *
     *      The mask `1 << bitPos` is equivalent to `1 * (2 ** bitPos)`, which places
     *      a single `1` at `bitPos`.
     *
     * @param mapRef The bitmap mapping in which the tick's initialized state is flipped.
     * @param tickSpacing The spacing between usable ticks.
     * @param tick The tick whose initialized state is to be flipped.
     *
     * @custom:dissection For complete line-by-line dissection and reverse-engineering, visit:
     *      `notes/5.TickBitmap & NextTickAlgo/2.CodeBase/2.TickBitMap Library/2.flickTickFun.md`
     */

    function flickTick(mapping(int16 => uint256) storage mapRef, int24 tickSpacing, int24 tick) internal {
        require(tick % tickSpacing == 0);
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);

        uint256 mask = 1 << bitPos; //  same as 1 × 2^bitPos...or is written as: 1 * (2 ** bitPos), and if 1 >> bitpos, then 1/2^bitpos is: x / (2 ** n)..for negative floor(x / (2 ** n)) or else -1.7 becomes -1 omdead of -2 because of sol roudning down! Extra knwoledge for negative here tho but ignmore it ggs!

        mapRef[wordPos] ^= mask;
    }

    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage mapRef,
        int24 tick,
        int24 tickSpacing,
        bool lessThanOrEqualTo
    ) internal view returns (int24 nextTick, bool initialized) {
        int24 compressed = tick / tickSpacing;

        if (tick < 0 && tick % tickSpacing != 0) compressed--;

        if (lessThanOrEqualTo) {
            (int16 wordPos, uint8 bitPos) = position(compressed);

            uint256 mask = 1 << bitPos - 1 + (1 << bitPos);
            uint256 masked = mapRef[wordPos] & mask;
            initialized = masked != 0;
            if (initialized) {
                nextTick = (compressed - int24(uint24(bitPos - (BitMath.mostSignificantBit(masked))))) * tickSpacing;
            } else {
                nextTick = (compressed - int24(uint24(bitPos))) * tickSpacing;
            }
        } else {
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);

            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = mapRef[wordPos] & mask;
            initialized = masked != 0;
            if (initialized) {
                nextTick = (compressed + 1 + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing;
            } else {
                nextTick = (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) * tickSpacing;
            }
        }
    }
}
