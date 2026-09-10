## `addDelta()`

```solidity
function addDelta(
    uint128 x,
    int128 y
) internal pure returns (uint128 z) {
    if (y < 0) {
        z = x - uint128(-y);
    } else {
        z = x + uint128(y);
    }
}
```

### What does this function do?

`addDelta()` adds a **signed liquidity change** (`y`) to the current liquidity (`x`) and returns the resulting liquidity (`z`).

### Formula — Resulting Liquidity

\[
\boxed{z = x + y}
\]

**What it does:** Calculates the new liquidity after applying the signed liquidity delta.

**Where it applies:**
- `y > 0` → liquidity increases
- `y < 0` → liquidity decreases
- `y = 0` → liquidity remains unchanged

### Why are the types different?

```text
x = uint128
y = int128
z = uint128
```

`x` and `z` represent actual liquidity, which cannot be negative, so they use `uint128`.

`y` represents a change in liquidity, which can be positive or negative, so it uses `int128`.

Therefore:

```text
x = current liquidity
y = signed liquidity change
z = resulting liquidity
```

Example:

```text
x = 1000
y = +300

z = 1000 + 300
  = 1300
```

And:

```text
x = 1000
y = -300

z = 1000 + (-300)
  = 700
```

---

## Negative Delta Branch

```solidity
if (y < 0) {
    z = x - uint128(-y);
}
```

When `y` is negative, liquidity needs to decrease.

Suppose:

```text
y = -300
```

First:

```text
-y
```

becomes:

```text
-(-300) = +300
```

Therefore:

```solidity
uint128(-y)
```

converts the negative delta into its positive magnitude.

Then:

```solidity
z = x - uint128(-y);
```

becomes:

```text
z = x - 300
```

Example:

```text
x = 1000
y = -300

-y = +300

z = 1000 - 300
  = 700
```

### Important clarification

This:

```solidity
x - uint128(-y)
```

does NOT mean:

```text
x - (-300)
```

It means:

```text
x - (+300)
```

because `-y` is evaluated first.

So:

```text
-y
↓
convert negative delta into positive magnitude

x - ...
↓
subtract that magnitude from liquidity
```

---

## Positive Delta Branch

```solidity
else {
    z = x + uint128(y);
}
```

If `y >= 0`, liquidity increases (or remains unchanged when `y == 0`).

Example:

```text
x = 1000
y = 300

z = 1000 + 300
  = 1300
```

The `uint128(y)` conversion is valid because this branch has established that `y >= 0`.

---

## Why did the original Uniswap version have `require` checks?

The original implementation was written for Solidity versions before `0.8.0`, where arithmetic overflow and underflow could silently wrap.

Original negative branch:

```solidity
require((z = x - uint128(-y)) < x, 'LS');
```

Original positive branch:

```solidity
require((z = x + uint128(y)) >= x, 'LA');
```

These manually detected:

```text
LS = liquidity subtraction underflow
LA = liquidity addition overflow
```

For example:

```text
x = 100
y = -200

100 - 200 = -100
```

A `uint128` cannot represent `-100`.

Similarly:

```text
x = uint128.max
y = 1
```

would produce a result greater than the maximum `uint128`.

---

## Solidity 0.8.20 Upgrade

Solidity 0.8.20 has built-in checked arithmetic.

Therefore, arithmetic automatically reverts when:

```text
uint128 subtraction → underflow
uint128 addition → overflow
```

The old manual `require` checks are therefore unnecessary for arithmetic safety.

Modern Solidity 0.8.20 version:

```solidity
function addDelta(
    uint128 x,
    int128 y
) internal pure returns (uint128 z) {
    if (y < 0) {
        z = x - uint128(-y);
    } else {
        z = x + uint128(y);
    }
}
```

### What must NOT change?

The Solidity upgrade can remove the old manual overflow/underflow checks, but the underlying mathematical behavior must remain identical:

```text
y < 0 → subtract |y| from x
y ≥ 0 → add y to x
```

The types retain their original meaning:

```text
x → uint128
y → int128
z → uint128
```

### Fundamental Invariant

\[
\boxed{0 \le z \le 2^{128}-1}
\]

In short:

```text
Original Solidity:
manual overflow/underflow detection

Solidity 0.8.20:
compiler-enforced overflow/underflow detection

Mathematical behavior:
UNCHANGED
```
