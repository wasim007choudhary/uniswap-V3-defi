// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {MyCustomFullMath} from "contracts/coreUV3/library/MyCustomFullMATH.sol";
import {UNISWAP_V3_POOL_USDC_WETH_500} from "Constants.sol";
import {IUV3Pool} from "contracts/coreUV3/Interfaces/IUV3Pool.sol";

contract SpotPriceTest is Test {
    IUV3Pool private immutable poolIUV3 = IUV3Pool(UNISWAP_V3_POOL_USDC_WETH_500);
    uint256 public constant USDC_DECIMALS = 1e6;
    uint256 public constant WETH_DECIMALS = 1e18;
    uint256 public constant Q96 = 1 << 96; //2 ** 96; both same

    function test_getSpotPriceFromSqrtPriceX96() public {
        uint256 price = 0;
        IUV3Pool.Slot0 memory slot0 = poolIUV3.slot0();

        price = MyCustomFullMath.mulDiv(slot0.sqrtPriceX96, slot0.sqrtPriceX96, Q96);
        price = 1e12 * 1e18 * Q96 / price;

        assertGt(price, 0, "price = 0");
        console2.log("price %e", price);
    }
}

