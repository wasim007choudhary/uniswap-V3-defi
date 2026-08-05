# Calculating Price from Tick

Now that we know the relationship between Price and Tick:

```text
Price = 1.0001^Tick
```

the next step is learning how to convert that mathematical price into the **actual market price**.

The biggest thing that confuses people here is **ERC20 decimals**.

---

# Example 1 — WETH / USDT Pool

Suppose we read the following Tick from the Pool:

```text
Tick = -195301
```

Using the formula:

```text
Price = 1.0001^-195301
```

we obtain:

```text
Price = 3.5319103213169284 × 10⁻⁹
```

or

```text
0.0000000035319
```

At first glance this looks completely wrong.

We know:

```text
1 WETH ≈ 3500 USDT
```

not

```text
1 WETH = 0.000000003 USDT
```

So what happened?

Nothing is wrong.

The only thing we have forgotten is **ERC20 decimals**.

---

# Why Does the Price Look So Small?

Remember how ERC20 tokens work.

The blockchain never stores decimal numbers.

Instead, it stores integers.

For WETH:

```text
Decimals = 18
```

Therefore,

```text
1 WETH
```

is actually stored as

```text
1 × 10¹⁸

=

1e18
```

For USDT:

```text
Decimals = 6
```

Therefore,

```text
1 USDT
```

is stored as

```text
1 × 10⁶

=

1e6
```

The Pool always works with these raw integer values.

---

# Child Analogy — Different Measuring Units

Imagine two people measuring the same table.

One uses:

```text
Meters
```

The other uses:

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

Both are correct.

They are simply using different units.

Exactly the same thing happens with ERC20 tokens.

WETH and USDT use different decimal units.

Before comparing them, we must normalize them to the same scale.

---

# Where Does `10⁻¹²` Come From?

We already know:

```text
Price = Y / X
```

In this pool:

```text
Token0 = WETH

Token1 = USDT
```

Therefore,

```text
Price = USDT / WETH
```

However,

the raw values are actually:

```text
USDT = 1e6

WETH = 1e18
```

So the ratio becomes:

```text
Price

=

1e6

/

1e18
```

Simplifying:

```text
Price

=

1e-12
```

This means the calculated price is actually:

```text
Actual Market Price

×

1e-12
```

That explains why the result appears extremely small.

The market price is still there,

it is simply scaled down by:

```text
10⁻¹²
```

---

# Numerical Example

Suppose the real market price is:

```text
1 WETH = 3500 USDT
```

The raw calculation becomes:

```text
3500 × 1e6

/

1e18
```

Grouping the powers of ten:

```text
3500 × (1e6 / 1e18)
```

Simplifies to:

```text
3500 × 1e-12
```

Which equals:

```text
0.0000000035
```

This is exactly why the price obtained from the Tick initially appears to be extremely small.

---

# Removing the Decimal Scaling

Since the calculated value contains:

```text
1e-12
```

we simply remove it.

The easiest mathematical way is:

```text
Multiply by 1e12
```

because:

```text
1e-12 × 1e12 = 1
```

Now:

```text
0.0000000035319

×

1e12

=

3531
```

Now the price matches the market:

```text
1 WETH ≈ 3531 USDT
```

---

# Why Does the Code Use This Instead?

Instead of writing:

```python
price * 1e12
```

the lesson writes:

```python
price / 1e6 * 1e18
```

These are mathematically identical.

Why?

Because:

```text
1e18

/

1e6

=

1e12
```

So:

```text
price

×

1e18

/

1e6
```

becomes:

```text
price

×

1e12
```

Both produce exactly the same answer.

---

# Why Doesn't the Code Simply Multiply by `1e12`?

Because Uniswap does **not** want to hardcode numbers.

Instead,

it thinks in terms of token decimals.

For this pool:

```text
WETH Decimals = 18

USDT Decimals = 6
```

So it naturally performs:

```text
×10^(Token0 Decimals)

÷10^(Token1 Decimals)
```

instead of memorizing:

```text
×10^12
```

This makes the code work for **any pair of ERC20 tokens**, regardless of how many decimals they use.

For example:

Suppose another pool has:

```text
Token A

8 Decimals
```

and

```text
Token B

12 Decimals
```

The normalization becomes:

```text
10^12

/

10^8

=

10^4
```

instead of:

```text
10^12
```

This is why production code always uses each token's actual decimal value rather than hardcoded constants.

---

# Example 2 — USDC / WETH Pool

Now consider another pool.

This time:

```text
Token0 = USDC

Token1 = WETH
```

Using the Tick formula:

```text
Price = 1.0001^Tick
```

Suppose we obtain:

```text
282708536.8770063
```

This looks far too large.

Why?

Because remember:

```text
Price = Token1 / Token0
```

For this pool:

```text
Price

=

WETH

/

USDC
```

This answers the question:

> **How much WETH is equal to one USDC?**

For example:

```text
1 USDC

=

0.000285 WETH
```

Mathematically this is correct,

but it is **not** how people usually think about ETH prices.

Most people naturally ask:

```text
1 WETH = ? USDC
```

instead of

```text
1 USDC = ? WETH
```

---

# Understanding Why We Use `1 / Price`

Think about buying a chocolate.

Question 1:

```text
How much does 1 chocolate cost?
```

Answer:

```text
1 Chocolate

=

₹20
```

Question 2:

```text
How many chocolates can I buy for ₹1?
```

Answer:

```text
₹1

=

0.05 Chocolate
```

Nothing changed.

Only the question changed.

One answer is simply the reciprocal (inverse) of the other.

Exactly the same thing happens in Uniswap.

Suppose:

```text
1 USDC

=

0.000285 WETH
```

People usually want the opposite:

```text
1 WETH

=

3500 USDC
```

To answer the opposite question,

we simply compute:

```text
1 / Price
```

If:

```text
Price = 0.000285
```

then:

```text
1 / Price

≈

3500
```

Now we have the market price in the form most people expect.

---

# Decimal Normalization Still Applies

Even after taking:

```text
1 / Price
```

the decimal scaling still exists.

Therefore,

we again normalize the value using the token decimals:

```python
1 / price / 1e6 * 1e18
```

which produces:

```text
3537
```

This is approximately the current market price:

```text
1 WETH ≈ 3537 USDC
```

---

# Key Takeaways

- The Tick is converted into a raw price using:
  ```text
  Price = 1.0001^Tick
  ```
- The initial result may look extremely small or extremely large because ERC20 tokens use different decimal precisions.
- WETH uses **18 decimals**, while USDT and USDC use **6 decimals**.
- The calculated price initially contains the factor:
  ```text
  1e6 / 1e18 = 1e-12
  ```
- Removing this scaling normalizes the price back to the familiar market value.
- Multiplying by `1e12` is mathematically identical to:
  ```text
  ÷1e6 ×1e18
  ```
- Uniswap uses token decimal values instead of hardcoded numbers so the same logic works for every ERC20 pair.
- `Price = Token1 / Token0`.
- If the returned price is the opposite of the form you want, simply take its reciprocal:
  ```text
  1 / Price
  ```
- Always pay attention to:
  - Which token is Token0.
  - Which token is Token1.
  - Their decimal precisions.
  - Whether the ratio needs to be inverted.