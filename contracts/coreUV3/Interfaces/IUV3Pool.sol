// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//import './pool/IUniswapV3PoolImmutables.sol';
import {IUV3PoolState} from "contracts/coreUV3/Interfaces/pool/IUV3PoolState.sol";

//import './pool/IUniswapV3PoolDerivedState.sol';
//import './pool/IUniswapV3PoolActions.sol';
//import './pool/IUniswapV3PoolOwnerActions.sol';
//import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUV3Pool is

    IUV3PoolState
{}
