//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library MyCustomFullMath {
    function mul512(uint256 x, uint256 y) internal pure returns (uint256 upperPart, uint256 lowerPart) {
        assembly ("memory-safe") {
            let mm := mulmod(x, y, not(0))
            lowerPart := mul(x, y)
            upperPart := sub(sub(mm, lowerPart), lt(mm, lowerPart))
        }
    }

    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            (uint256 upperPart, uint256 lowerPart) = mul512(x, y);

            if (upperPart == 0) {
                result = lowerPart / denominator;
            }
        }
    }
}
