// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library MycustomLiquidityMath {
    function deltaAddition(uint128 x, int128 y) internal pure returns (uint128 z) {
        //here the overflow anjd underflow checks are done by our latest so so no extra checks needed

        if (y < 0) {
            z = x - uint128(-y); //why -y..say y = -2...then -y= 2..see that coenot is used here
        } else {
            z = x + uint128(y);
        }
    }
}
