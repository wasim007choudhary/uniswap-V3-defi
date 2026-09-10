# Uniswap V3 — LowGasSafeMath.sol

## What Is `LowGasSafeMath` Mainly For?

`LowGasSafeMath` is a small math library designed to perform basic arithmetic safely while using very little extra gas.

It provides:

- `add`
- `sub`
- `mul`

for both `uint256` and `int256`.

The original library was written for older Solidity versions where arithmetic could overflow or underflow and silently wrap around instead of automatically reverting.

The basic goal was:

> If the mathematical answer cannot fit inside the integer type, revert instead of accepting a wrapped/corrupted number.

The name tells us what it is:

- **SafeMath** → make arithmetic safe against overflow/underflow.
- **LowGas** → do that safety checking with compact, gas-conscious logic.

>Note In our code We will implement the 0.8.20 compatable ones as it got all the build in checks we here needed to coded

---

# The Original Library

```solidity
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}
```

---

# 1. `add(uint256, uint256)`

Original:

```solidity
function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x);
}
```

It calculates:

```solidity
z = x + y;
```

and checks that the addition did not overflow.

The clever part:

```solidity
(z = x + y) >= x
```

means:

> First calculate `x + y` and store it in `z`. Then ask: "Is the answer greater than or equal to `x`?"

Because `x` and `y` are `uint256`, `y` can never be negative. Therefore a valid addition must satisfy:

```text
x + y >= x
```

It does not matter whether `y` is smaller than, equal to, or bigger than `x`.

Examples:

```text
x = 10, y = 5    → z = 15  → 15 >= 10 ✓
x = 10, y = 10   → z = 20  → 20 >= 10 ✓
x = 10, y = 100  → z = 110 → 110 >= 10 ✓
```

The check is **not** asking whether `x` is bigger than `y`.

It asks:

> After adding the non-negative `y` to `x`, did the result become smaller than `x`?

Normally that cannot happen.

### Overflow

Conceptually:

```text
x = MAX
y = 1

MAX + 1
   ↓
wraps around
   ↓
0
```

Then:

```text
z >= x
0 >= MAX
✗
```

So the `require` fails and reverts.

### Why This Tiny Check Matters

This tiny check:

```solidity
require((z = x + y) >= x);
```

has a heavy impact in older Solidity.

It turns:

```text
overflow → wrapped/corrupted number
```

into:

```text
overflow → revert
```

That is the cleverness of these old low-gas checks: the source expression is tiny, but it protects an important arithmetic boundary.

## Solidity 0.8.20 Version

Solidity `0.8.x` already checks normal arithmetic.

Therefore:

```solidity
function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x + y;
}
```

is enough.

No `require`, custom error, or manual overflow check is needed for normal checked arithmetic.

---

# 2. `sub(uint256, uint256)`

Original:

```solidity
function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x);
}
```

It calculates:

```solidity
z = x - y;
```

and checks that the subtraction did not underflow.

For unsigned integers, the valid condition is:

```text
x >= y
```

Examples:

```text
x = 100
y = 30
z = 70
70 <= 100 ✓
```

If `x == y`:

```text
100 - 100 = 0
0 <= 100 ✓
```

### Why `z <= x` Detects Underflow

When unsigned subtraction is valid, subtracting a non-negative value cannot make the result bigger than `x`.

So:

```text
valid subtraction:
z <= x
```

If `y > x`, the mathematical result would be negative, which cannot fit in `uint256`.

In old Solidity arithmetic it could wrap into a huge `uint256`.

Example:

```text
x = 30
y = 100

30 - 100
   ↓
would mathematically be -70
   ↓
cannot be uint256
   ↓
old arithmetic wraps to a huge uint256
```

Then:

```text
z > x
```

instead of:

```text
z <= x
```

So:

```solidity
require((z = x - y) <= x);
```

reverts.

### The Pattern

```text
Valid:
x >= y
    ↓
z <= x

Underflow:
y > x
    ↓
wrapped result becomes huge
    ↓
z > x
    ↓
revert
```

Again, a very small check has a strong safety effect in older Solidity.

## Solidity 0.8.20 Version

Normal subtraction in Solidity `0.8.20` is already checked.

```solidity
function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x - y;
}
```

No old `require` or custom error is needed.

---

# 3. `mul(uint256, uint256)`

Original:

```solidity
function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(x == 0 || (z = x * y) / x == y);
}
```

It calculates:

```solidity
z = x * y;
```

and checks whether multiplication overflowed.

The clever check:

```solidity
(z = x * y) / x == y
```

means:

> If `x * y` was calculated correctly, dividing the answer by `x` should give us `y` again.

Example:

```text
x = 10
y = 5

z = 10 * 5 = 50

50 / 10 = 5

5 == 5 ✓
```

## Why `x == 0`?

The check divides by `x`:

```solidity
(z = x * y) / x
```

If `x == 0`, that division would be by zero.

But:

```text
0 × y = 0
```

is always safe.

Therefore:

```solidity
x == 0 || ...
```

means:

```text
If x is zero:
    multiplication is safe.

Otherwise:
    calculate x × y,
    divide the result by x,
    make sure we get y back.
```

## How It Detects Overflow

If `x * y` overflows under old unsigned arithmetic, the result wraps around.

Then:

```text
(x * y) / x
```

will no longer give the original `y`.

Therefore:

```solidity
(z = x * y) / x == y
```

becomes false and the `require` reverts.

The whole safety path is:

```text
multiplication overflow
        ↓
wrapped value
        ↓
divide by x
        ↓
doesn't recover y
        ↓
require fails
        ↓
revert
```

Again, a small expression has a heavy safety impact.

## Solidity 0.8.20 Version

Normal multiplication in Solidity `0.8.20` already reverts on overflow.

Therefore:

```solidity
function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x * y;
}
```

is enough.

No manual overflow check, custom error, or `require` is needed for normal checked arithmetic.

### `unchecked` Caveat

If we deliberately use:

```solidity
unchecked {
    z = x * y;
}
```

Solidity's automatic overflow protection is disabled for that operation.

Then we must separately decide whether an explicit safety check is required.

---

# 4. `add(int256, int256)`

Original:

```solidity
function add(int256 x, int256 y) internal pure returns (int256 z) {
    require((z = x + y) >= x == (y >= 0));
}
```

This is the signed version, so the check is different.

After:

```solidity
z = x + y;
```

the result should move in a predictable direction based on the sign of `y`.

### If `y` is positive

Adding a positive number should move the result up:

```text
z >= x
```

### If `y` is negative

Adding a negative number should move the result down:

```text
z < x
```

The original combines both rules into:

```solidity
(z >= x) == (y >= 0)
```

---

## Normal Cases

### Case 1 — `x = 10`, `y = 5`

```text
z = 10 + 5
  = 15

z >= x
15 >= 10
true

y >= 0
5 >= 0
true

true == true
✓
```

Passes.

### Case 2 — `x = 10`, `y = -5`

```text
z = 10 + (-5)
  = 5

z >= x
5 >= 10
false

y >= 0
-5 >= 0
false

false == false
✓
```

Passes.

The result moved down because `y` was negative.

### Case 3 — `x = 10`, `y = -100`

```text
z = 10 + (-100)
  = -90

z >= x
-90 >= 10
false

y >= 0
-100 >= 0
false

false == false
✓
```

Passes.

Even though the absolute value of `y` is bigger than `x`, that is not the issue. The rule cares about the direction.

### Case 4 — `x = -5`, `y = 10`

```text
z = -5 + 10
  = 5

z >= x
5 >= -5
true

y >= 0
10 >= 0
true

true == true
✓
```

Passes.

### Case 5 — `x = -100`, `y = 10`

```text
z = -100 + 10
  = -90

z >= x
-90 >= -100
true

y >= 0
10 >= 0
true

true == true
✓
```

Passes.

The sign of `x` does not matter. The important thing is the sign of `y`.

---

# Signed Addition: The Real Protection Is at the Boundaries

For easy demonstration, use `int8`:

```text
int8 range:

-128 → 127
```

The same principle applies to `int256`:

```text
MIN = -2^255
MAX =  2^255 - 1
```

## Case 6 — Positive Overflow

```text
x = 127
y = 1
```

Mathematically:

```text
127 + 1 = 128
```

But `128` does not fit in `int8`.

Old wrapping behavior can produce:

```text
128 → -128
```

So:

```text
z = -128
```

Now:

```text
z >= x
-128 >= 127
false
```

but:

```text
y >= 0
1 >= 0
true
```

Therefore:

```text
false == true
✗
```

The check fails and reverts.

## Case 7 — Negative Underflow

```text
x = -128
y = -1
```

Mathematically:

```text
-128 + (-1) = -129
```

But `-129` does not fit.

Old wrapping behavior can produce:

```text
-129 → 127
```

So:

```text
z = 127
```

Now:

```text
z >= x
127 >= -128
true
```

but:

```text
y >= 0
-1 >= 0
false
```

Therefore:

```text
true == false
✗
```

The check fails and reverts.

## The Whole Signed Addition Trick

```solidity
(z = x + y) >= x == (y >= 0)
```

basically says:

```text
If y is positive:
    result should be >= x.

If y is negative:
    result should be < x.
```

Or:

```text
y >= 0 → result should move UP
y < 0  → result should move DOWN
```

If the result crosses either boundary, old signed wrapping makes it move in the wrong direction. The tiny check catches it.

This is why these old checks are interesting:

> They are extremely small pieces of code, but they encode a very strong boundary-safety invariant.

## Solidity 0.8.20 Version

Normal signed addition is already checked:

```solidity
function add(int256 x, int256 y) internal pure returns (int256 z) {
    z = x + y;
}
```

No manual direction check or custom error is needed.

---

# 5. `sub(int256, int256)`

Original:

```solidity
function sub(int256 x, int256 y) internal pure returns (int256 z) {
    require((z = x - y) <= x == (y >= 0));
}
```

This is the signed subtraction version.

It follows the same idea as signed addition, but the direction is reversed because we are subtracting.

## Main Rule

If `y` is positive:

```text
x - positive
```

should move down:

```text
z <= x
```

If `y` is negative:

```text
x - negative
```

is effectively adding a positive value, so it should move up:

```text
z > x
```

The original combines this into:

```solidity
(z <= x) == (y >= 0)
```

---

# Normal Number Cases

## Case 1 — Positive `x`, Positive `y`

```text
x = 10
y = 5

z = 10 - 5
  = 5

z <= x
5 <= 10
true

y >= 0
5 >= 0
true

true == true
✓
```

Passes.

## Case 2 — Positive `x`, Negative `y`

```text
x = 10
y = -5

z = 10 - (-5)
  = 15

z <= x
15 <= 10
false

y >= 0
-5 >= 0
false

false == false
✓
```

Passes.

Notice:

```text
x - (-5)
```

is effectively:

```text
x + 5
```

so the result moves up.

## Case 3 — Negative `x`, Positive `y`

```text
x = -10
y = 5

z = -10 - 5
  = -15

z <= x
-15 <= -10
true

y >= 0
5 >= 0
true

true == true
✓
```

Passes.

## Case 4 — Negative `x`, Negative `y`

```text
x = -10
y = -5

z = -10 - (-5)
  = -5

z <= x
-5 <= -10
false

y >= 0
-5 >= 0
false

false == false
✓
```

Passes.

So all four ordinary sign combinations work.

---

# Signed Subtraction: Boundary Cases

Again use `int8`:

```text
MIN = -128
MAX = 127
```

## Case 5 — Positive Overflow

```text
x = 127
y = -1
```

Then:

```text
z = 127 - (-1)
  = 128
```

But `128` cannot fit.

Old wrapping behavior can produce:

```text
128 → -128
```

So:

```text
z = -128
```

Check:

```text
z <= x
-128 <= 127
true

y >= 0
-1 >= 0
false

true == false
✗
```

The check reverts.

## Case 6 — Negative Underflow

```text
x = -128
y = 1
```

Then:

```text
z = -128 - 1
  = -129
```

But `-129` cannot fit.

Old wrapping behavior can produce:

```text
-129 → 127
```

So:

```text
z = 127
```

Check:

```text
z <= x
127 <= -128
false

y >= 0
1 >= 0
true

false == true
✗
```

The check reverts.

## The Whole Signed Subtraction Trick

```solidity
(z = x - y) <= x == (y >= 0)
```

basically says:

```text
If y is positive:
    subtraction should move DOWN.
    Therefore z <= x.

If y is negative:
    subtracting a negative moves UP.
    Therefore z > x.
```

So:

```text
y > 0 → result should move DOWN
y < 0 → result should move UP
```

If the operation crosses an `int256` boundary, old wrapping makes the result move in the wrong direction. The tiny comparison detects it.

Again:

> A very small check can have a very large safety impact.

## Solidity 0.8.20 Version

Normal signed subtraction is already checked:

```solidity
function sub(int256 x, int256 y) internal pure returns (int256 z) {
    z = x - y;
}
```

No manual overflow/underflow check or custom error is needed.

---

# Final Solidity 0.8.20 Assessment

The original library contains:

```text
1. add(uint256, uint256)
2. sub(uint256, uint256)
3. mul(uint256, uint256)
4. add(int256, int256)
5. sub(int256, int256)
```

All five were designed to provide arithmetic safety in older Solidity.

In normal Solidity `0.8.20`, the compiler already checks ordinary arithmetic.

Therefore, our modern implementations can simply be:

```solidity
function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x + y;
}

function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x - y;
}

function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x * y;
}

function add(int256 x, int256 y) internal pure returns (int256 z) {
    z = x + y;
}

function sub(int256 x, int256 y) internal pure returns (int256 z) {
    z = x - y;
}
```

The old manual `require` checks are redundant when using normal checked Solidity `0.8.20` arithmetic.

---

# Why We Do Not Add Custom Errors Here

For some of our custom libraries, custom errors are useful when we need to add a safety condition that Solidity itself does not provide.

Here, Solidity `0.8.20` already performs the arithmetic safety checks.

Adding another custom-error check would duplicate the compiler's protection rather than provide new protection.

So for these five operations, the clean modern flow is:

```text
normal arithmetic
      ↓
Solidity 0.8.20 checked arithmetic
      ↓
automatic revert on overflow/underflow
```

rather than:

```text
manual check
      ↓
custom revert
      ↓
arithmetic
      ↓
Solidity checks again
```

---

# Important `unchecked` Caveat

The conclusion above applies to **normal checked arithmetic**.

If we deliberately write:

```solidity
unchecked {
    z = x + y;
}
```

then Solidity's automatic overflow/underflow protection is disabled for that operation.

At that point, we must separately decide whether an explicit safety mechanism is required.

So the mental model is:

```text
Solidity 0.8.20
+
normal arithmetic
=
built-in overflow/underflow protection
```

but:

```text
Solidity 0.8.20
+
unchecked arithmetic
=
no automatic overflow/underflow protection
```

---

# Final Mental Model

`LowGasSafeMath` is a great example of old Solidity engineering.

The original checks look tiny:

```solidity
(z = x + y) >= x
```

```solidity
(z = x - y) <= x
```

```solidity
(z = x * y) / x == y
```

and:

```solidity
(z = x + y) >= x == (y >= 0)
```

```solidity
(z = x - y) <= x == (y >= 0)
```

But each one encodes an important mathematical invariant.

They were designed to catch:

- unsigned addition overflow
- unsigned subtraction underflow
- unsigned multiplication overflow
- signed addition overflow
- signed addition underflow
- signed subtraction overflow
- signed subtraction underflow

in older Solidity where arithmetic could wrap.

So although the checks are only a few characters long, they have a **heavy safety impact**.

For our Solidity `0.8.20` rewrite, however, the language itself now provides those arithmetic checks for normal arithmetic. Therefore, a top-level modern DeFi implementation would generally avoid duplicating those checks unless there is a specific reason to use `unchecked` arithmetic or preserve a separate abstraction.
