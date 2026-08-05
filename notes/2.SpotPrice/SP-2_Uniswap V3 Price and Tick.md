# Uniswap V3 Price and Tick

In the previous lesson, we learned that the current spot price can be obtained from either:

- `tick`
- `sqrtPriceX96`

In this lesson, we'll focus on the relationship between **Tick** and **Price**, and learn the mathematical equation that connects them.

---

# Defining the Variables

Throughout this lesson:

```text
x = Token0

y = Token1

P = Price of Token0 in terms of Token1
```

When we say:

> **"Price of Token0 in terms of Token1"**

we simply mean:

> **How many units of Token1 are required to buy one unit of Token0?**

For example:

```text
Token0 = WETH

Token1 = USDC
```

If:

```text
1 WETH = 2500 USDC
```

then:

```text
P = 2500
```

because one Token0 (WETH) costs 2500 Token1 (USDC).

A simple analogy:

```text
1 Apple = ₹20
```

- Apple = Token0
- Money = Token1
- Price = ₹20

---

# Price in Uniswap V2

In Uniswap V2, the spot price was calculated directly from the pool reserves.

The equation was:

```text
P = Y / X
```

where:

- `Y` = Amount of Token1 in the pool.
- `X` = Amount of Token0 in the pool.

For example:

```text
Pool

100 WETH

250,000 USDC
```

Price:

```text
P

=

250000 / 100

=

2500
```

So:

```text
1 WETH = 2500 USDC
```

The Pool did **not** explicitly store the price.

Instead, it stored the reserves, and the price was derived from them.

---

# Why Doesn't This Work in Uniswap V3?

In Uniswap V3, the Pool no longer continuously stores the current token amounts.

Instead, it stores values such as:

- Liquidity (`L`)
- Current Tick
- Current Price Representation (`sqrtPriceX96`)

The current amounts of Token0 and Token1 are **calculated when needed** using:

- Liquidity
- Current Price
- Lower Price
- Upper Price

Since the current token balances are not directly stored,

we can no longer calculate the spot price by simply doing:

```text
Y / X
```

---

# Is `P = Y / X` Still Correct?

Yes.

Although Uniswap V3 no longer calculates the current price from reserves,

the equation:

```text
P = Y / X
```

is still the mathematical definition of price.

It simply describes:

> **The ratio of Token1 to Token0.**

The protocol now stores the price in a different form,

but the meaning of price has **not** changed.

A simple analogy:

```text
Speed = Distance / Time
```

A car's dashboard may directly display:

```text
120 km/h
```

You don't continuously calculate:

```text
Distance / Time
```

while driving,

but the equation is still mathematically true.

Similarly,

Uniswap V3 stores the price using Tick (or `sqrtPriceX96`),

but:

```text
Price = Token1 / Token0
```

remains the mathematical definition of price.

---

# A Note About Token Decimals

The lesson briefly discusses decimal differences between ERC20 tokens.

For example:

```text
WETH

18 Decimals
```

```text
USDC

6 Decimals
```

Internally,

their raw balances are stored as:

```text
1 WETH

=

1 × 10¹⁸
```

```text
2500 USDC

=

2500 × 10⁶
```

Because these tokens use different decimal precisions,

simply dividing the raw balances introduces powers of ten such as:

```text
10⁶ / 10¹⁸

=

10⁻¹²
```

When writing Solidity code,

we normalize these values so both tokens use the same precision before performing calculations.

The instructor mentions that these decimal conversions will be covered in more detail later when implementing the code.

---

# Price in Uniswap V3

Instead of calculating price from reserves,

Uniswap V3 defines the spot price using the current Tick.

The equation is:

```text
P = 1.0001^Tick
```

Therefore,

if we know the current Tick,

we can calculate the current spot price.

---

# Understanding the Equation

Suppose:

```text
Tick = 0
```

Then:

```text
P

=

1.0001⁰

=

1
```

---

Suppose:

```text
Tick = 1
```

Then:

```text
P

=

1.0001¹

=

1.0001
```

The price increases by approximately:

```text
0.01%
```

---

Suppose:

```text
Tick = 2
```

Then:

```text
P

=

1.0001²

≈

1.00020001
```

Again,

the price has increased by another 0.01%.

Each Tick represents one additional multiplication by:

```text
1.0001
```

---

Now suppose:

```text
Tick = -1
```

Then:

```text
P

=

1.0001⁻¹

=

1 / 1.0001

≈

0.99990001
```

The price decreases.

Therefore:

```text
Positive Tick

↓

Higher Price
```

```text
Negative Tick

↓

Lower Price
```

This matches what we learned in the previous lessons:

- As Tick increases, Price increases.
- As Tick decreases, Price decreases.

---

# Uniswap V2 vs Uniswap V3

| Uniswap V2 | Uniswap V3 |
|------------|------------|
| Stores reserves | Stores Tick and `sqrtPriceX96` |
| Price = `reserve1 / reserve0` | Price = `1.0001^Tick` |
| Price derived from reserves | Price derived from Tick (or `sqrtPriceX96`) |

The mathematical meaning of price remains the same.

What changed is **how the protocol obtains that price.**

---

# Key Takeaways

- `P` represents the price of **Token0 in terms of Token1**.
- In Uniswap V2, the spot price was calculated using:
  ```text
  P = Y / X
  ```
- In Uniswap V3, the Pool no longer continuously stores the current token balances.
- The mathematical definition of price (`P = Y / X`) is still valid.
- Token decimal differences require normalization when performing calculations.
- Uniswap V3 defines the current price using:
  ```text
  P = 1.0001^Tick
  ```
- Every Tick represents a small price step of approximately **0.01%**.
- Positive Ticks correspond to higher prices.
- Negative Ticks correspond to lower prices.
- The next step is understanding how `sqrtPriceX96` represents the same spot price.