#  `mul512()` Deep Dive 

Before understanding `mulDiv()`, we first need to understand `mul512()`.

Unlike the EVM's normal `MUL` instruction, which returns only the lower 256 bits of a multiplication, `mul512()` reconstructs the **entire 512-bit product** and splits it into two `uint256` values:

- `high` → Upper 256 bits
- `low` → Lower 256 bits

---

## The Function

```solidity
/**
 * @dev Return the 512-bit multiplication of two uint256.
 *
 * The result is stored in two 256 variables such that product = high * 2²⁵⁶ + low.
 */
function mul512(uint256 a, uint256 b) internal pure returns (uint256 high, uint256 low) {
    assembly ("memory-safe") {
        let mm := mulmod(a, b, not(0))
        low := mul(a, b)
        high := sub(sub(mm, low), lt(mm, low))
    }
}
```

---

# Why Do We Need This?

A Solidity `uint256` can only store **256 bits**.

Imagine we multiply two huge numbers.

```
a × b
```

The answer might require **512 bits**.

```
┌────────────────────────────┬────────────────────────────┐
│        Upper 256 bits      │      Lower 256 bits       │
│            HIGH            │            LOW            │
└────────────────────────────┴────────────────────────────┘
```

The EVM's normal `MUL` instruction **only returns the LOW part**.

The HIGH part is discarded.

So `mul512()` reconstructs the missing HIGH part.

---

# How a 512-bit Number Is Stored

Think of two boxes.

```
┌──────────────┬──────────────┐
│    HIGH      │     LOW      │
└──────────────┴──────────────┘
```

Together they represent one huge number.

The relationship is

```
product = high × 2²⁵⁶ + low
```

---

## Why Only HIGH Is Multiplied?

Imagine each box can only hold **2 digits** instead of 256 bits.

Suppose the real number is

```
543
```

Split into

```
HIGH = 5
LOW  = 43
```

To rebuild the number

```
5 × 100 + 43

=

543
```

Notice:

Only HIGH is multiplied.

LOW is already the lower portion.

Exactly the same idea applies here.

Instead of base 100, we use

```
2²⁵⁶
```

Therefore

```
product = high × 2²⁵⁶ + low
```

---

# Does the EVM Lose the Upper Bits?

**Yes.**

The EVM's `MUL` opcode computes

```
a × b mod 2²⁵⁶
```

Meaning

```
Keep only the lowest 256 bits.
```

Visualizing:

```
Real Product (512 bits)

┌──────────────┬──────────────┐
│    HIGH      │     LOW      │
└──────────────┴──────────────┘

        │

        ▼

mul(a,b)

        ▼

LOW
```

The HIGH part is lost.

That is exactly why `mul512()` exists.

---

# Line-by-Line Explanation

---

## Assembly Block

```solidity
assembly ("memory-safe") {
    let mm := mulmod(a, b, not(0))
    low := mul(a, b)
    high := sub(sub(mm, low), lt(mm, low))
}
```

---

# What Does `"memory-safe"` Mean?

```
assembly ("memory-safe")
```

This is **not part of the algorithm**.

It tells the Solidity compiler

> "I promise this assembly block does not corrupt Solidity's memory."

Our assembly only performs arithmetic.

It never uses

- mstore
- mload
- calldatacopy
- returndatacopy

Therefore it is naturally memory-safe.

It simply helps the compiler perform better optimizations.

---

# Line 1

```solidity
let mm := mulmod(a, b, not(0))
```

---

## What is `not(0)`?

`not()` is a **bitwise NOT** operation.

It flips every bit.

Example (8 bits):

```
00000000

↓

11111111
```

For the EVM (256 bits):

```
000...000

↓

111...111
```

which equals

```
2²⁵⁶ − 1
```

or

```solidity
type(uint256).max
```

In Yul assembly, the shortest way to write

```
2²⁵⁶ − 1
```

is

```solidity
not(0)
```

---

## Why Not Just Write `type(uint256).max`?

Because inside Yul assembly,

```solidity
type(uint256).max
```

doesn't exist.

Instead we use

```solidity
not(0)
```

which produces exactly the same value.

---

## Does `not(0)` Overflow?

No.

`not()` is **not arithmetic**.

It simply flips existing bits.

```
00000000

↓

11111111
```

No extra bits are created.

No overflow happens.

---

# What Does This Line Do?

```solidity
let mm := mulmod(a, b, not(0))
```

This computes

```
(a × b) mod (2²⁵⁶ − 1)
```

Notice carefully:

**`mm` is NOT the overflowed bits.**

Instead,

`mm` is

> A special clue about the full 512-bit multiplication.

Later,

we combine

- LOW
- mm

to reconstruct

- HIGH

Think of `mm` as

> A detective clue.

---

## Child Analogy

Imagine a giant puzzle.

You already have

```
LOW
```

Someone also gives you

```
mm
```

which is a clue.

Using

```
LOW + mm
```

you can reconstruct

```
HIGH
```

---

# Line 2

```solidity
low := mul(a, b)
```

This performs a normal EVM multiplication.

The EVM returns only

```
Lower 256 bits
```

So

```
LOW
```

is stored here.

Child explanation:

> Store the part that fits into one uint256.

---

# Line 3

```solidity
high := sub(sub(mm, low), lt(mm, low))
```

This is the clever part.

---

## Is Subtraction Happening?

Yes.

This is equivalent to

```solidity
high = (mm - low) - lt(mm, low);
```

Two subtractions happen.

---

## First Subtraction

```
mm - low
```

Remember

```
mm
```

is the clue.

```
low
```

is already known.

Removing LOW from the clue leaves us **almost** with HIGH.

---

## What Is `lt(mm, low)`?

`lt` means

```
less than
```

It returns

```
1 if mm < low

0 otherwise
```

---

## Why Subtract One More?

Sometimes

```
mm - low
```

needs to borrow.

Exactly like decimal subtraction.

Example

```
1000

-

999
```

Borrowing occurs.

Binary arithmetic behaves the same way.

If borrowing happened

```
lt(mm, low)

=

1
```

So we subtract one more.

Otherwise

```
lt(mm, low)

=

0
```

Nothing extra is subtracted.

---

## Child Analogy

Imagine two toy boxes.

```
Mystery Box (mm)
```

You already know what toys are in

```
LOW
```

So you remove them.

Sometimes while removing,

you accidentally borrowed one toy from the upper shelf.

If that happened,

give the toy back.

That's exactly what

```
lt(mm, low)
```

checks.

---

# Final Mental Model

```
Huge multiplication

        │

        ▼

Full 512-bit product

        │

        ▼

┌──────────────┬──────────────┐
│    HIGH      │     LOW      │
└──────────────┴──────────────┘

        ▲

        │

Recover HIGH using:

- LOW
- mm (the clue)

```

---

# One-Line Summary of Each Assembly Instruction

```solidity
let mm := mulmod(a, b, not(0))
```

> Get a special clue about the complete 512-bit multiplication.

---

```solidity
low := mul(a, b)
```

> Store the lower 256 bits.

---

```solidity
high := sub(sub(mm, low), lt(mm, low))
```

> Use the clue and the lower bits to reconstruct the missing upper 256 bits.

---

# Key Takeaways

- `mul()` only returns the lower 256 bits.
- The upper 256 bits are discarded by the EVM.
- `mul512()` reconstructs those missing upper bits.
- `mm` is **not** the overflowed bits.
- `mm` is a mathematical clue used to recover the overflowed bits.
- `high` and `low` together represent the complete 512-bit multiplication.
- The original product can always be reconstructed as

```
product = high × 2²⁵⁶ + low
```
----
----
----
