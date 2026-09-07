// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {BitMath} from "contracts/coreUV3/library/BitMath.sol";

library TickBitMap {
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick / 256); // or >> 8 same ...as 8bits = 256 in other wrds 0....255...total equals 256 positions
        bitPos = uint8(uint24(tick % 256)); // sol 0.8+ dpesnt all direct conversion...int24..-> uint24..then only uint8..not directly int24->uint8..it breaks in modern soldity
    }
}
