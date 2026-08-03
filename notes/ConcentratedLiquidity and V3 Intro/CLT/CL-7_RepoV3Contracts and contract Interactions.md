# Uniswap V3 Contracts

Before diving into the implementation of Uniswap V3, it's important to understand the major contracts that make up the protocol and how they are organized.

Unlike Uniswap V2, where most interactions revolved around the **Factory**, **Pair**, and **Router** contracts, Uniswap V3 introduces additional contracts to support **Concentrated Liquidity**, **Liquidity Positions (NFTs)**, and more advanced routing.

---

# Repository Structure

The Uniswap V3 codebase is split across several repositories, each with a specific responsibility.

The four important repositories are:

- `v3-core`
- `v3-periphery`
- `swap-router-contracts`
- `universal-router`

Each repository contains contracts that serve different purposes.

---

## `v3-core`

This repository contains the **core protocol logic**.

The contracts inside this repository define how the protocol actually works.

The two most important contracts are:

- `UniswapV3Factory`
- `UniswapV3Pool`

### UniswapV3Factory

The **Factory** contract is responsible for creating (deploying) new Uniswap V3 pools.

Whenever a new trading pair is needed, the Factory deploys a new `UniswapV3Pool` contract.

---

### UniswapV3Pool

The **Pool** contract is where the protocol actually operates.

Each pool:

- Holds the two tokens.
- Stores liquidity.
- Executes swaps.
- Handles flash loans.
- Tracks liquidity positions.

Just like the **Pair** contract in Uniswap V2, the Pool contract is considered a **low-level contract**.

Although it contains the core protocol logic, users typically do **not** interact with it directly.

Instead, users interact through higher-level helper contracts.

---

## `v3-periphery`

The **Periphery** repository contains contracts that make interacting with the protocol much easier.

The most important contract in this repository is:

- `NonfungiblePositionManager`

This contract manages liquidity positions.

It is responsible for:

- Creating liquidity positions.
- Increasing liquidity.
- Decreasing liquidity.
- Collecting swap fees.
- Managing liquidity position NFTs.

Since every liquidity position in Uniswap V3 is unique, this contract represents each position as an **ERC721 (NFT).**

---

## `swap-router-contracts`

This repository contains router contracts used for swapping tokens.

The primary router introduced in this course is:

- `SwapRouter02`

Instead of interacting directly with the Pool contract, users typically execute swaps through this router.

The router simplifies the swap process and handles the low-level interactions with Uniswap V3 pools.

---

## `universal-router`

The **Universal Router** is a newer and more comprehensive router.

It extends the functionality of `SwapRouter02` by supporting:

- Uniswap V2 swaps.
- Uniswap V3 swaps.
- NFT-related operations.

Although it is more powerful, it is **not** covered in this course.

Instead, the course focuses on the simpler `SwapRouter02` contract.

---

# High-Level Contract Relationships

The main contracts introduced in this lesson are:

```text
UniswapV3Factory
        │
        ▼
Creates
        │
        ▼
UniswapV3Pool
```

```text
NonfungiblePositionManager
        │
        ▼
Manages Liquidity Positions
```

```text
SwapRouter02
        │
        ▼
Executes Swaps
```

---

# Comparison with Uniswap V2

| Uniswap V2 | Uniswap V3 |
|------------|------------|
| Factory | UniswapV3Factory |
| Pair | UniswapV3Pool |
| Router | SwapRouter02 |
| ERC20 LP Tokens | ERC721 Liquidity Positions managed by NonfungiblePositionManager |

The overall architecture remains similar to Uniswap V2:

- A **Factory** creates Pools.
- A **Pool** contains the core AMM logic.
- A **Router** provides an easier interface for users.

However, Uniswap V3 introduces one major addition:

- **NonfungiblePositionManager**, which manages NFT-based liquidity positions.

---

# Key Takeaways

- Uniswap V3 is organized into multiple repositories, each serving a different purpose.
- The four important repositories are:
  - `v3-core`
  - `v3-periphery`
  - `swap-router-contracts`
  - `universal-router`
- `UniswapV3Factory` deploys new `UniswapV3Pool` contracts.
- `UniswapV3Pool` is the low-level contract that holds tokens and executes the core AMM logic.
- `NonfungiblePositionManager` manages liquidity positions and represents them as ERC721 NFTs.
- `SwapRouter02` is the primary router used to execute swaps.
- The `Universal Router` extends routing functionality but is outside the scope of this course.
- Similar to Uniswap V2, users generally interact with higher-level contracts instead of directly calling the Pool contract.

---

---
---
# Uniswap V3 Contract Interactions

Now that we've introduced the major contracts in Uniswap V3, the next step is understanding **how these contracts interact with one another** and the important functions exposed by each contract.

---

# Overall Interaction Flow

At a high level, the interaction between the major contracts looks like this:

```text
                User
                  │
                  ▼
        NonfungiblePositionManager
                  │
                  ▼
           UniswapV3Pool
                  ▲
                  │
        UniswapV3Factory
```

For swaps:

```text
                User
                  │
                  ▼
            SwapRouter02
                  │
                  ▼
           UniswapV3Pool
```

The **Factory** creates pools.

The **Pool** contains the core AMM logic.

The **NonfungiblePositionManager** manages liquidity positions.

The **SwapRouter02** simplifies token swaps.

---

# UniswapV3Factory

The `UniswapV3Factory` contract is responsible for deploying new pools.

To create a new pool, users call:

```solidity
createPool(...)
```

The Factory then deploys a new `UniswapV3Pool` contract.

Conceptually:

```text
User
 │
 ▼
createPool()
 │
 ▼
UniswapV3Factory
 │
 ▼
Deploys
 │
 ▼
UniswapV3Pool
```

---

# UniswapV3Pool

The Pool contract contains the protocol's core logic.

The most important functions are:

- `mint()`
- `burn()`
- `collect()`
- `swap()`
- `flash()`

Most of these are considered **low-level functions**.

Rather than being called directly by users, they are usually called through helper contracts such as the `NonfungiblePositionManager` or `SwapRouter02`.

---

## mint()

Used to **add liquidity** to a pool.

Unlike directly transferring tokens into a contract, `mint()` initiates a callback to the caller so the required tokens can be provided.

Because of this callback mechanism, the caller is generally another smart contract rather than an EOA (Externally Owned Account).

---

## burn()

Used to **remove liquidity from a position.**

An important detail:

Calling `burn()` **does not immediately transfer tokens back to the user.**

Instead, it only removes liquidity from the position.

To actually receive the withdrawn tokens and any accumulated swap fees, the user must later call:

```solidity
collect()
```

---

## collect()

Used to:

- Collect withdrawn tokens.
- Collect accumulated swap fees.

A common sequence is:

```text
burn()

↓

collect()
```

Similarly, after decreasing liquidity through the Position Manager:

```text
decreaseLiquidity()

↓

collect()
```

---

## swap()

Performs token swaps.

This is another **low-level function**.

When `swap()` is called, the Pool contract executes a callback to the caller.

Inside that callback, the caller must transfer the required input tokens into the Pool.

This is very similar to the low-level swap mechanism used in Uniswap V2.

Because of this callback, `swap()` is typically called through router contracts rather than directly by users.

---

## flash()

Provides flash loans.

Like `swap()`, `flash()` is also a low-level function.

A flash loan must be:

- Borrowed.
- Used.
- Repaid.

all within the **same transaction.**

Because this logic must execute atomically, flash loans are generally initiated by custom smart contracts rather than EOAs.

---

# Callback Mechanism

Many functions inside `UniswapV3Pool` perform a callback to the caller.

Examples include:

- `mint()`
- `swap()`
- `flash()`

Instead of simply accepting tokens before execution, the Pool asks the caller to provide the required tokens during the callback.

Conceptually:

```text
Caller

↓

Pool.mint()

↓

Pool Callback

↓

Caller Sends Tokens

↓

Pool Finishes Execution
```

This callback-based architecture is one of the biggest differences developers encounter when working directly with the Pool contract.

---

# NonfungiblePositionManager

The recommended way to interact with liquidity positions is through the `NonfungiblePositionManager`.

Instead of interacting directly with the Pool, users call this contract.

The Position Manager internally interacts with the Pool and manages the ERC721 liquidity position.

---

## mint()

Creates a brand-new liquidity position.

This is used the **first time** liquidity is added.

Flow:

```text
User

↓

NonfungiblePositionManager

↓

Pool.mint()

↓

Pool Callback

↓

Position NFT Minted
```

---

## increaseLiquidity()

Adds more liquidity to an **existing** Position.

Rather than creating another NFT, this function increases the liquidity associated with the existing Position.

---

## decreaseLiquidity()

Removes liquidity from an existing Position.

Just like the Pool's `burn()` function,

this function **does not immediately transfer tokens back.**

It simply decreases the liquidity stored in the Position.

To actually receive tokens and earned fees, the user must call:

```solidity
collect()
```

---

## collect()

Transfers:

- Withdrawn liquidity.
- Earned swap fees.

to the liquidity provider.

---

## burn()

Destroys the Position NFT.

This is typically performed only after:

- Liquidity has been completely removed.
- Fees have been collected.

---

# Flash Loans

Flash loans are performed through the Pool's `flash()` function.

The borrowing contract is **not** part of the Uniswap protocol.

Instead, it is a custom smart contract written by the developer.

Conceptually:

```text
Your Flash Contract

↓

Pool.flash()

↓

Pool Callback

↓

Execute Arbitrary Logic

↓

Repay Loan

↓

Transaction Ends
```

Everything must complete successfully within the same transaction.

Otherwise, the transaction reverts.

---

# SwapRouter02

Users generally do **not** call the Pool's `swap()` function directly.

Instead, they interact with the `SwapRouter02`.

The router internally performs the low-level swap and handles the required callback logic.

Conceptually:

```text
User

↓

SwapRouter02

↓

Pool.swap()

↓

Pool Callback

↓

Swap Completes
```

---

# SwapRouter02 Functions

The router exposes four main swap functions.

## exactInputSingle()

Performs a swap through **one pool**.

The user specifies the exact amount of input tokens they wish to spend.

The output amount is determined by the pool.

---

## exactOutputSingle()

Performs a swap through **one pool**.

Instead of specifying the input amount,

the user specifies the exact amount of output tokens they wish to receive.

Example:

Suppose a user wants exactly:

```text
1 WETH
```

and is willing to spend **up to**

```text
3000 DAI
```

The user calls:

```solidity
exactOutputSingle(...)
```

If obtaining exactly 1 WETH requires less than or equal to 3000 DAI, the swap succeeds.

Otherwise, it reverts.

---

## exactInput()

Works like `exactInputSingle()`, but supports **multi-hop swaps** involving multiple pools.

Example:

```text
WETH

↓

DAI

↓

MKR
```

This route passes through multiple Uniswap V3 pools.

---

## exactOutput()

Works like `exactOutputSingle()`, but supports **multi-hop swaps**.

The user specifies:

- Exact output amount.
- Maximum input they're willing to spend.

The router determines the required path through multiple pools.

---

# Single-Hop vs Multi-Hop

Single-Hop:

```text
DAI

↓

WETH
```

Uses one Pool.

---

Multi-Hop:

```text
WETH

↓

DAI

↓

MKR
```

Uses multiple Pools.

---

# Key Takeaways

- `UniswapV3Factory` deploys new Pool contracts using `createPool()`.
- `UniswapV3Pool` contains the protocol's low-level AMM logic.
- Important Pool functions are:
  - `mint()`
  - `burn()`
  - `collect()`
  - `swap()`
  - `flash()`
- `burn()` removes liquidity but does **not** transfer tokens.
- `collect()` transfers withdrawn liquidity and accumulated fees.
- Many Pool functions use callback mechanisms, requiring another smart contract as the caller.
- `NonfungiblePositionManager` is the recommended interface for managing liquidity positions.
- Liquidity positions are represented as ERC721 NFTs.
- `SwapRouter02` provides a user-friendly interface for executing swaps.
- `exactInputSingle()` and `exactOutputSingle()` perform single-hop swaps.
- `exactInput()` and `exactOutput()` support multi-hop swaps across multiple pools.