// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library BitMath {
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
    }
}
