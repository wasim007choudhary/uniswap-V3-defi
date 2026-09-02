// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

///@notice This library is a sol 0.8.0+ implementation of the original/old sol version Uniswap V3 Math.sol library.
///@dev The original Uniswap V3 Math.sol library was written in an older version of Solidity that did not have built-in overflow checks. In Solidity 0.8.0 and later, overflow checks are built into the language, making the original Math.sol library unnecessary.
///@notice We Hvae removed the checls which are not needed and did our own to read about the original library and the changes we made to it,
///@dev please read notes/CoreLibFunctions/Math.md to get the full dissecton of the original lib and why we wrote our own.

///@notice You are wondering why same function names and wont it cause issue but here is the answer - Solidity allows function overloading, so having the same function name is fine as long as the parameter types/signatures are different.
library MyCustomMath {
    /////// unSigned Intergers ///////
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
    }

    /////// Signed Intergers ///////

    function add(int256 x, int256 y) internal pure returns (int256 z) {
        z = x + y;
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        z = x - y;
    }

    ///@notice Our extra own function unswap didn't need and so no function in their library of it but I added it for my own use case
    function mul(int256 x, int256 y) internal pure returns (int256 z) {
        z = x * y;
    }
}
