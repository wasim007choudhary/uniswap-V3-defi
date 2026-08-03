# Deriving `sqrtPriceX96` from Tick

So far, we've learned how to calculate:

- Price from Tick.
- Price from `sqrtPriceX96`.
- Tick from `sqrtPriceX96`.

A natural question is:

> **If we already know the Tick, can we directly calculate `sqrtPriceX96`?**

The answer is:

> **Yes.**

Let's derive the equation step by step.

---

# Step 1 — Start with the Tick Formula

We already know that the current price is calculated as:

```text
P = 1.0001^Tick
```

At this point, we know the Tick and want to calculate:

```text
sqrtPriceX96
```

---

# Step 2 — Take the Square Root of Both Sides

Current equation:

```text
P = 1.0001^Tick
```

Take the square root of both sides:

```text
√P = √(1.0001^Tick)
```

Now we have the square root of the price.

---

# Step 3 — Simplify the Right Side

Recall the exponent rule:

```text
√a = a^(1/2)
```

Applying it:

```text
√(1.0001^Tick)

=

(1.0001^Tick)^(1/2)
```

Now use another exponent rule:

```text
(a^b)^c = a^(b×c)
```

Therefore:

```text
√P

=

1.0001^(Tick/2)
```

We have now expressed the square root of the price directly in terms of the Tick.

---

# Step 4 — Apply the Definition of `sqrtPriceX96`

By definition:

```text
sqrtPriceX96

=

√P × Q96
```

where:

```text
Q96 = 2^96
```

Now substitute the value of `√P` that we just derived.

```text
sqrtPriceX96

=

1.0001^(Tick/2)

×

2^96
```

This is the final equation.

---

# Final Formula

If the Tick is known,

we can directly calculate `sqrtPriceX96` using:

```text
sqrtPriceX96

=

1.0001^(Tick/2)

×

2^96
```

or equivalently:

```text
sqrtPriceX96

=

√(1.0001^Tick)

×

2^96
```

Both equations are mathematically identical.

---

# Numerical Example

Suppose:

```text
Tick = 0
```

### Calculate the Price

```text
P

=

1.0001^0

=

1
```

### Calculate the Square Root

```text
√P

=

√1

=

1
```

### Multiply by `Q96`

```text
sqrtPriceX96

=

1 × 2^96
```

Result:

```text
sqrtPriceX96

=

79228162514264337593543950336
```

This is the well-known `sqrtPriceX96` value whenever:

```text
Tick = 0
```

---

# Complete Conversion Flow

If we start from the Tick:

```text
Tick

↓

Price

↓

Square Root Price

↓

sqrtPriceX96
```

The equations are:

```text
Price

=

1.0001^Tick
```

↓

```text
√Price

=

1.0001^(Tick/2)
```

↓

```text
sqrtPriceX96

=

1.0001^(Tick/2)

×

2^96
```

---

# Key Takeaways

- If the Tick is known, `sqrtPriceX96` can be calculated directly.
- Start with:
  ```text
  P = 1.0001^Tick
  ```
- Take the square root:
  ```text
  √P = 1.0001^(Tick/2)
  ```
- Multiply by `Q96` (`2^96`):
  ```text
  sqrtPriceX96 = 1.0001^(Tick/2) × 2^96
  ```
- This is simply the reverse of recovering the Price from `sqrtPriceX96`.
- Together, these equations allow conversion between all three representations:
  - Tick
  - Price
  - `sqrtPriceX96`