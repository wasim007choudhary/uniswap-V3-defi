# Calculating Price Using `sqrtPriceX96`

In the previous lesson, we learned that we can calculate the current spot price using the **Tick**:

```text
Price = 1.0001^Tick
```

However, the Pool also stores another value inside `slot0`:

```text
sqrtPriceX96
```

This lesson explains how to recover the current spot price using `sqrtPriceX96`.

---

# What Is `sqrtPriceX96`?

Uniswap defines it as:

```text
sqrtPriceX96 = √P × Q96
```

where:

```text
Q96 = 2^96
```

Substituting `Q96` into the equation:

```text
sqrtPriceX96 = √P × 2^96
```

Notice something.

The protocol is **not storing the price (`P`) directly.**

It is storing:

- The square root of the price (`√P`).
- Multiplied by `2^96`.

---

# Why Doesn't Uniswap Store the Price Directly?

Suppose the current price is:

```text
P = 25
```

The square root is:

```text
√25 = 5
```

Instead of storing:

```text
25
```

the protocol stores:

```text
5 × 2^96
```

Why multiply by `2^96`?

Because Solidity cannot store decimal numbers.

Suppose the square root price was:

```text
0.75
```

Solidity cannot accurately store:

```text
0.75
```

Instead, Uniswap scales it by multiplying it with a very large number:

```text
0.75 × 2^96
```

This converts the decimal into a very large integer that Solidity can safely store.

This is exactly the same idea we saw earlier with ERC20 decimals.

For example:

```text
1 WETH

↓

1 × 10^18
```

Instead of storing decimals,

we scale the value into an integer.

Here,

instead of using:

```text
10^18
```

Uniswap uses:

```text
2^96
```

We'll learn **why they specifically chose `2^96`** when we study Q64.96 fixed-point numbers.

---

# Our Goal

Suppose the Pool gives us:

```text
sqrtPriceX96
```

We want:

```text
Price (P)
```

So we simply undo everything the protocol did.

The easiest way is to work backwards.

---

# Step 1 — Remove `2^96`

We start with the stored equation:

```text
sqrtPriceX96 = √P × 2^96
```

To remove the multiplication,

divide **both sides** by `2^96`.

```text
sqrtPriceX96 / 2^96

=

(√P × 2^96)

/ 2^96
```

The `2^96` cancels:

```text
sqrtPriceX96 / 2^96

=

√P
```

Now we have successfully recovered:

```text
√P
```

instead of:

```text
√P × 2^96
```

---

# Step 2 — Recover the Original Price

Are we done?

Not yet.

We currently have:

```text
√P
```

But we want:

```text
P
```

How do we remove a square root?

Suppose:

```text
√25 = 5
```

How do we get:

```text
25
```

back?

We square it.

```text
5² = 25
```

Exactly the same thing happens here.

Take the equation:

```text
sqrtPriceX96 / 2^96

=

√P
```

Now square **both sides**.

```text
(sqrtPriceX96 / 2^96)²

=

(√P)²
```

Since:

```text
(√P)² = P
```

the equation becomes:

```text
P = (sqrtPriceX96 / 2^96)²
```

This is the final formula used to calculate the price from `sqrtPriceX96`.

---

# Verify It Using Small Numbers

Forget crypto for a moment.

Suppose:

```text
P = 25
```

### Step 1

Take the square root.

```text
√25

=

5
```

Now, instead of using:

```text
2^96
```

let's pretend we multiply by:

```text
100
```

just to keep the numbers small.

The stored value becomes:

```text
5 × 100

=

500
```

Imagine someone only gives you:

```text
500
```

and says:

> Recover the original price.

---

## Undo Step 1

Remove the multiplication.

```text
500 / 100

=

5
```

---

## Undo Step 2

Remove the square root by squaring.

```text
5²

=

25
```

Original price recovered.

Exactly the same logic is used by Uniswap.

The only difference is that instead of multiplying by:

```text
100
```

it multiplies by:

```text
2^96
```

---

# Child Analogy

Imagine your friend secretly hides the number:

```text
25
```

Before giving it to you,

he performs two tricks.

### Trick 1

Take the square root.

```text
25

↓

5
```

### Trick 2

Multiply it by:

```text
100
```

```text
5

↓

500
```

Now he hands you:

```text
500
```

You want the original number.

So you simply undo his tricks **in reverse order.**

First:

Undo the multiplication.

```text
500

↓

5
```

Then:

Undo the square root.

```text
5²

↓

25
```

You recovered the original number.

Uniswap does the exact same thing.

It hides the price like this:

```text
Price

↓

Square Root

↓

Multiply by 2^96

↓

Store as sqrtPriceX96
```

When we want the price back,

we simply reverse every operation.

```text
sqrtPriceX96

↓

Divide by 2^96

↓

√Price

↓

Square It

↓

Price
```

Nothing magical is happening.

We are simply undoing the operations in reverse order.

---

# Final Formula

Putting everything together:

```text
sqrtPriceX96 = √P × 2^96
```

↓

Divide both sides by `2^96`

```text
sqrtPriceX96 / 2^96 = √P
```

↓

Square both sides

```text
(sqrtPriceX96 / 2^96)² = (√P)²
```

↓

Simplify

```text
P = (sqrtPriceX96 / 2^96)²
```

---

# Key Takeaways

- The Pool stores `sqrtPriceX96`, **not** the price directly.
- `sqrtPriceX96` is defined as:
  ```text
  sqrtPriceX96 = √P × 2^96
  ```
- `2^96` is a scaling factor that allows Solidity to store fractional values as integers.
- To recover the square root price, divide by `2^96`.
- To recover the actual price, square the result.
- The complete formula is:
  ```text
  P = (sqrtPriceX96 / 2^96)²
  ```
- The mathematics is simply the process of **undoing the protocol's operations in reverse order**:
  1. Divide by `2^96`.
  2. Square the result.
- We'll later learn **why Uniswap stores the square root of the price** and **why it specifically uses `2^96`** when we study Q64.96 fixed-point numbers.

---

# Calculating Spot Price from `sqrtPriceX96` using a **real `sqrtPriceX96` value

This is same as **SP-4_Calculating price from Tick.md** but for `sqrtPriceX96` and not tick.

In the previous lesson, we derived the formula for calculating the price from `sqrtPriceX96`:

```text
Price = (sqrtPriceX96 / 2^96)^2
```

In this lesson, we'll use a **real `sqrtPriceX96` value** taken from the WETH/USDT Uniswap V3 Pool and calculate the actual market price.

This lesson doesn't introduce any new mathematics.

Instead, it puts everything we've already learned into practice.

---

# Step 1 — Read `sqrtPriceX96` from the Pool

Suppose the Pool returns:

```text
sqrtPriceX96 = 4551852809367933182694918
```

At first glance,

this huge number doesn't look anything like an ETH price.

That's because this number is **not the price itself.**

It is actually:

```text
sqrtPriceX96 = √Price × 2^96
```

The protocol stores the **square root of the price**, multiplied by a scaling factor (`2^96`).

---

# Step 2 — Remove the Scaling Factor

We know:

```text
sqrtPriceX96 = √Price × 2^96
```

Our goal is to recover:

```text
√Price
```

To remove the multiplication by `2^96`,

divide both sides by `2^96`.

```text
sqrtPriceX96 / 2^96

=

(√Price × 2^96)

/ 2^96
```

The `2^96` cancels:

```text
sqrtPriceX96 / 2^96

=

√Price
```

Now we've recovered the square root price.

---

# Step 3 — Recover the Actual Price

We're close,

but we still have:

```text
√Price
```

instead of:

```text
Price
```

How do we remove a square root?

Suppose:

```text
√25 = 5
```

To recover:

```text
25
```

we simply square the result.

Exactly the same thing happens here.

```text
Price

=

(√Price)^2
```

Substituting our previous equation:

```text
Price

=

(sqrtPriceX96 / 2^96)^2
```

This is exactly the formula we derived in the previous lesson.

---

# Why Is the Calculated Price Still So Small?

Suppose we calculate:

```python
price = (sqrtPriceX96 / 2**96) ** 2
```

The result might be:

```text
0.000000003378
```

At first glance,

this looks completely wrong.

We know:

```text
1 WETH ≈ 3378 USDT
```

not

```text
1 WETH = 0.000000003378 USDT
```

Nothing is wrong.

We've simply forgotten to account for ERC20 decimals.

---

# Understanding the Decimal Problem Again

This Pool contains:

```text
Token0 = WETH

18 Decimals
```

```text
Token1 = USDT

6 Decimals
```

The price is defined as:

```text
Price = Token1 / Token0
```

which means:

```text
Price = USDT / WETH
```

However,

the protocol actually works with the raw integer values.

Instead of:

```text
1 USDT
```

it stores:

```text
1 × 10^6
```

Instead of:

```text
1 WETH
```

it stores:

```text
1 × 10^18
```

Therefore,

the calculated price actually contains:

```text
10^6 / 10^18

=

10^-12
```

This extra scaling factor makes the calculated value appear extremely small.

---

# Child Analogy — Different Measuring Units

Imagine two people measuring the same table.

One measures in:

```text
Meters
```

The other measures in:

```text
Millimeters
```

The first person says:

```text
2 meters
```

The second says:

```text
2000 millimeters
```

Neither person is wrong.

They're simply using different units.

Exactly the same thing happens here.

WETH and USDT use different decimal units,

so before interpreting the price,

we must normalize both tokens to the same scale.

---

# Removing the Decimal Scaling

Since the price contains:

```text
10^-12
```

we need to remove it.

The lesson does this by writing:

```python
price / 1e6 * 1e18
```

Let's understand why.

First,

divide by:

```text
1e6
```

Then,

multiply by:

```text
1e18
```

Mathematically,

this becomes:

```text
price

×

1e18

/

1e6
```

Simplifying:

```text
price

×

10^12
```

because:

```text
10^18 / 10^6

=

10^12
```

So:

```python
price / 1e6 * 1e18
```

and

```python
price * 1e12
```

are exactly the same.

The lesson writes it using the token decimals because this approach works for **any ERC20 pair**, not just WETH and USDT.

---

# Final Result

After removing the decimal scaling,

the price becomes:

```text
3378
```

which means:

```text
1 WETH ≈ 3378 USDT
```

Now the calculated value matches the actual market price.

---

# Child Analogy — Opening Three Boxes

Imagine someone hides the answer inside three boxes.

### Box 1

The protocol multiplies the square root price by:

```text
2^96
```

### Box 2

The protocol stores:

```text
√Price
```

instead of:

```text
Price
```

### Box 3

ERC20 decimals scale the final answer.

To recover the real market price,

we simply open the boxes one by one.

```text
sqrtPriceX96

↓

Divide by 2^96

↓

√Price

↓

Square It

↓

Raw Price

↓

Remove ERC20 Decimal Scaling

↓

Actual Market Price
```

Every step simply reverses something that was done earlier.

---

# Key Takeaways

- `sqrtPriceX96` is **not** the actual price.
- It is defined as:
  ```text
  sqrtPriceX96 = √Price × 2^96
  ```
- Divide by `2^96` to recover the square root price.
- Square the result to recover the raw price:
  ```text
  Price = (sqrtPriceX96 / 2^96)^2
  ```
- The calculated price still contains ERC20 decimal scaling.
- For the WETH/USDT pool:
  - WETH has **18 decimals**.
  - USDT has **6 decimals**.
- The raw price therefore contains:
  ```text
  10^6 / 10^18 = 10^-12
  ```
- Normalize the decimals by:
  ```python
  price / 1e6 * 1e18
  ```
  which is mathematically identical to:
  ```python
  price * 1e12
  ```
- After normalization, the calculated price matches the real market price:
  ```text
  1 WETH ≈ 3378 USDT
  ```
- This lesson introduces **no new mathematics**. It simply applies the formula derived in the previous lesson using a real `sqrtPriceX96` value from a Uniswap V3 Pool.