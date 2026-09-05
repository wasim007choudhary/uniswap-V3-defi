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
    }
}
