# Conversion from `sqrtPriceX96` to Tick

In the previous lessons, we learned that all three values are connected:

```text
Tick

⇄

Price

⇄

sqrtPriceX96
```

Previously, we learned how to calculate:

- **Price from Tick**
- **Price from `sqrtPriceX96`**

Now we'll go one step further.

Suppose we already know:

```text
sqrtPriceX96
```

Can we calculate:

```text
Tick
```

The answer is **Yes.**

This is exactly what Uniswap V3 sometimes does internally during swaps.

---

# Step 1 — Recall the Two Price Equations

We already know:

```text
Price = 1.0001^Tick
```

We also know:

```text
Price = (sqrtPriceX96 / Q96)^2
```

where:

```text
Q96 = 2^96
```

Notice something.

Both equations represent **the exact same Price**.

If two expressions equal the same thing,

then they must equal each other.

Therefore,

we can write:

```text
1.0001^Tick

=

(sqrtPriceX96 / Q96)^2
```

This becomes our starting equation.

---

# What Are We Trying to Find?

We want:

```text
Tick
```

But look carefully.

Tick is hiding here:

```text
1.0001^Tick
```

Tick is sitting **inside an exponent.**

How do we pull an exponent outside?

We use a **logarithm.**

---

# Child Analogy — Opening a Locked Box

Imagine your friend hides a toy inside a locked box.

You cannot grab the toy directly.

First,

you must unlock the box.

Logarithms work exactly like that.

Whenever a variable is trapped inside an exponent,

a logarithm "opens the box" and brings the exponent outside.

---

# Step 2 — Apply Logarithm to Both Sides

Starting equation:

```text
1.0001^Tick

=

(sqrtPriceX96 / Q96)^2
```

Take the logarithm of both sides.

```text
log(1.0001^Tick)

=

log((sqrtPriceX96 / Q96)^2)
```

Nothing has changed mathematically.

We've simply wrapped both sides with:

```text
log()
```

---

# Step 3 — Use the First Logarithm Rule

One of the most important logarithm identities is:

```text
log(a^b)

=

b × log(a)
```

In simple words:

> **The exponent comes outside the logarithm.**

Apply it to the left side.

```text
log(1.0001^Tick)

↓

Tick × log(1.0001)
```

Now the equation becomes:

```text
Tick × log(1.0001)

=

log((sqrtPriceX96 / Q96)^2)
```

---

# Step 4 — Apply the Same Rule Again

Look at the right side.

It also has an exponent.

```text
(... )²
```

Apply exactly the same logarithm rule.

```text
log((sqrtPriceX96 / Q96)^2)

↓

2 × log(sqrtPriceX96 / Q96)
```

Now our equation becomes:

```text
Tick × log(1.0001)

=

2 × log(sqrtPriceX96 / Q96)
```

---

# Step 5 — Isolate Tick

Our goal is:

```text
Tick
```

Currently we have:

```text
Tick × log(1.0001)
```

How do we remove multiplication?

We divide.

Divide **both sides** by:

```text
log(1.0001)
```

```text
Tick × log(1.0001)

/

log(1.0001)

=

2 × log(sqrtPriceX96 / Q96)

/

log(1.0001)
```

The left side simplifies because:

```text
log(1.0001)

/

log(1.0001)

=

1
```

Therefore,

we obtain the final equation:

```text
Tick

=

2 × log(sqrtPriceX96 / Q96)

/

log(1.0001)
```

This is the formula used to recover the Tick from `sqrtPriceX96`.

---

# Why Does Dividing Work?

Suppose we have:

```text
5 × 8 = 40
```

If we want to recover:

```text
5
```

we divide both sides by:

```text
8
```

```text
40 / 8 = 5
```

Exactly the same thing happened here.

We had:

```text
Tick × log(1.0001)
```

To recover Tick,

we divided both sides by:

```text
log(1.0001)
```

---

# Child Analogy — Undoing the Operations

Imagine someone hides the answer using two tricks.

First,

they put Tick inside an exponent.

```text
Tick

↓

1.0001^Tick
```

Now Tick is hidden.

To reveal it,

we use a logarithm.

```text
log(1.0001^Tick)

↓

Tick × log(1.0001)
```

Tick has now come outside,

but it's still multiplied by:

```text
log(1.0001)
```

So we undo the multiplication.

```text
Divide by log(1.0001)
```

Now Tick is completely isolated.

---

# What Is This Formula Used For?

Most developers never calculate this equation manually.

The important thing is understanding **why it exists.**

During swaps,

the Pool continuously updates:

```text
sqrtPriceX96
```

Sometimes,

the protocol also needs the corresponding:

```text
Tick
```

Instead of storing two independent values,

it can calculate Tick directly from `sqrtPriceX96` using this equation.

---

# Relationship Between Tick, Price and `sqrtPriceX96`

All three values describe the **same market price.**

You can start from any one of them and calculate the other two.

Starting from Tick:

```text
Tick

↓

Price = 1.0001^Tick

↓

sqrtPriceX96
```

Or starting from `sqrtPriceX96`:

```text
sqrtPriceX96

↓

Price = (sqrtPriceX96 / Q96)^2

↓

Tick =
2 × log(sqrtPriceX96 / Q96)
/ log(1.0001)
```

They are simply different mathematical representations of the same current market price.

---

# Key Takeaways

- Tick, Price, and `sqrtPriceX96` all represent the same market price in different forms.
- We already know:
  ```text
  Price = 1.0001^Tick
  ```
- We also know:
  ```text
  Price = (sqrtPriceX96 / Q96)^2
  ```
- Since both equations equal the same Price, we can set them equal:
  ```text
  1.0001^Tick = (sqrtPriceX96 / Q96)^2
  ```
- Applying logarithms allows us to move Tick out of the exponent.
- Using the logarithm identity:
  ```text
  log(a^b) = b × log(a)
  ```
  gives:
  ```text
  Tick × log(1.0001) = 2 × log(sqrtPriceX96 / Q96)
  ```
- Dividing both sides by `log(1.0001)` isolates Tick.
- The final formula is:
  ```text
  Tick =
  2 × log(sqrtPriceX96 / Q96)
  /
  log(1.0001)
  ```
- You do **not** need to memorize this formula.
- The important concept is understanding that Uniswap can move freely between:
  - Tick
  - Price
  - `sqrtPriceX96`

  because they all represent the same underlying spot price.

  ---
  ---
  ---
  # Calculating Tick from `sqrtPriceX96` (Real Example)

In the previous lesson, we derived the formula for calculating the Tick from `sqrtPriceX96`:

```text
Tick =
2 × log(sqrtPriceX96 / Q96)
/
log(1.0001)
```

Now we'll verify that this formula actually works using a **real Uniswap V3 Pool**.

This lesson introduces **no new mathematics**.

It simply applies the formula we already derived.

---

# The Pool Used

This example uses the:

```text
USDC / WETH

Fee Tier = 0.05%
```

Pool.

From the Pool contract we already know two values.

```text
sqrtPriceX96
```

and

```text
Tick
```

The contract returns:

```text
sqrtPriceX96

=

1386025840740905446350612632896904
```

and

```text
Tick

=

195402
```

Think of this as the Pool already giving us the answer.

Our job is simply to check whether our formula produces the same Tick.

---

# Step 1 — Define `Q96`

We already know that:

```text
Q96 = 2^96
```

In Python:

```python
Q96 = 2 ** 96
```

Nothing new is happening here.

We're simply defining the same scaling constant used by Uniswap.

---

# Step 2 — Apply the Formula

Previously we derived:

```text
Tick

=

2 × log(sqrtPriceX96 / Q96)

/

log(1.0001)
```

Now we simply substitute the real value from the Pool.

Instead of writing:

```text
sqrtPriceX96
```

we substitute:

```text
1386025840740905446350612632896904
```

The equation becomes:

```text
Tick

=

2 × log(1386025840740905446350612632896904 / 2^96)

/

log(1.0001)
```

Python writes the exact same equation:

```python
t = 2 * math.log(sqrt_p_x96 / Q96) / math.log(1.0001)
```

Nothing magical is happening.

We're simply plugging the Pool's value into the formula we already proved.

---

# Step 3 — Print the Result

After running the calculation:

```python
print(t)
```

Python returns:

```text
195402.155
```

The Tick stored by the Pool is:

```text
195402
```

These values almost perfectly match.

This confirms that our formula correctly converts `sqrtPriceX96` back into the corresponding Tick.

---

# Why Isn't the Answer Exactly `195402`?

Notice that our calculation gives:

```text
195402.155
```

instead of:

```text
195402
```

Why?

Because the mathematical calculation produces a **continuous (decimal) value**.

However,

**Ticks are always whole numbers (integers).**

A Pool cannot have a Tick like:

```text
195402.155
```

It can only store:

```text
195402
```

or

```text
195403
```

So the protocol stores the integer Tick that corresponds to the current price.

The small decimal difference comes from floating-point calculations and the fact that the actual market price may lie between two Tick boundaries.

---

# Child Analogy — Standing on a Staircase

Imagine you're standing on a staircase.

Mathematically,

your position might be:

```text
Step 15.3
```

But a staircase doesn't have:

```text
15.3 Steps
```

It only has:

```text
15

16
```

So we simply say you're standing on:

```text
Step 15
```

The same idea applies here.

Our calculation gives:

```text
195402.155
```

but the protocol stores:

```text
195402
```

because Ticks are always whole numbers.

---

# What Is This Lesson Really Showing?

This lesson is simply verifying that the conversion formula works.

We:

1. Read `sqrtPriceX96` from a real Uniswap V3 Pool.
2. Plug it into the formula.
3. Recover the Tick.
4. Compare it with the Tick stored by the Pool.

Since both values match,

we know the formula is correct.

---

# Key Takeaways

- This lesson introduces **no new mathematics**.
- It simply verifies the Tick conversion formula using a real Uniswap V3 Pool.
- The Pool provides:
  - `sqrtPriceX96`
  - `Tick`
- We calculate the Tick using:
  ```text
  Tick =
  2 × log(sqrtPriceX96 / Q96)
  /
  log(1.0001)
  ```
- The calculated value (`195402.155`) closely matches the Tick stored by the Pool (`195402`).
- The small decimal difference is expected because logarithms return continuous values, while Uniswap stores Ticks as integers.
- This confirms that `sqrtPriceX96` and Tick are simply two different representations of the same market price.