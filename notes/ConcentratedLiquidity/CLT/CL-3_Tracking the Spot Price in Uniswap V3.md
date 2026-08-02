# Lesson — Tracking the Spot Price in Uniswap V3

In the previous lessons, we learned that Uniswap V3 no longer treats **Reserves** as the primary state of the pool.

Instead, it primarily tracks:

- Liquidity
- Current Price

This immediately raises an important question.

> **If Uniswap V3 doesn't store reserves like Uniswap V2, then how does it know the current price?**

Let's answer that.

---

# First, Let's Recall Uniswap V2

In Uniswap V2, finding the current price was very easy.

Suppose the pool contains:

```text
100 DAI
100 USDC
```

The spot price is simply

```text
Price = reserve1 / reserve0

      = 100 / 100

      = 1
```

Now suppose someone swaps tokens.

The pool becomes

```text
110 DAI
90.91 USDC
```

The new spot price is simply

```text
90.91 / 110
```

Nothing complicated.

The reserves themselves tell us the current price.

---

# Then I Asked...

> **Can Uniswap V3 do the same thing?**

The answer is:

**No.**

Why?

Because Uniswap V3 no longer stores:

```text
reserve0
reserve1
```

as its primary state.

Instead,

it stores:

```text
Liquidity

+

Current Price
```

But then another question appears.

> **If it doesn't calculate the price from reserves, how does it know the price?**

---

# Uniswap V3 Introduces "Ticks"

Instead of storing the price directly,

Uniswap V3 stores something called a:

```text
Tick
```

When I first heard the word **Tick**, I thought it had something to do with time.

It doesn't.

A Tick is simply an integer that represents a specific price.

Think of it as a label or an index for a particular price level.

---

# Child Analogy — Apartment Floors

Imagine a huge apartment building.

Every floor has a number.

```text
Floor -2

Floor -1

Floor 0

Floor 1

Floor 2

Floor 3
```

Now imagine every floor represents a different price.

Instead of saying

> "Go to price 1.00453892"

you simply say

> "Go to Floor 3."

The floor number is much easier to remember and work with.

Ticks work exactly the same way.

Every Tick corresponds to exactly one price.

---

# Tick Zero

The protocol defines:

```text
Tick = 0
```

to represent:

```text
Price = 1
```

This becomes the starting point.

---

# Positive Ticks

Now suppose we move upward.

```text
Tick

0

↓

1

↓

2

↓

3
```

The price becomes

larger...

larger...

larger...

As the Tick keeps increasing,

the price keeps increasing.

Eventually,

it approaches infinity.

---

# Negative Ticks

Now move downward.

```text
Tick

0

↓

-1

↓

-2

↓

-3
```

The price becomes

smaller...

smaller...

smaller...

As the Tick keeps decreasing,

the price gets closer and closer to zero.

---

# How Does Uniswap Convert a Tick into a Price?

This is where the famous formula comes in.

```text
Price = 1.0001^Tick
```

or

```text
P = 1.0001^t
```

where

- `P` = Spot Price
- `t` = Current Tick

Once the protocol knows the Tick,

it can calculate the current price immediately.

---

# Small Examples

## Tick = 0

```text
Price

=

1.0001⁰

=

1
```

Exactly what we expected.

---

## Tick = 1

```text
Price

=

1.0001¹

=

1.0001
```

The price increases slightly.

---

## Tick = 2

```text
Price

=

1.0001²

≈

1.00020001
```

Another tiny increase.

---

## Tick = -1

```text
Price

=

1.0001⁻¹

≈

0.99990001
```

The price becomes slightly smaller than one.

---

## Tick = 100

The price becomes much larger than one.

---

## Tick = -100

The price becomes much smaller than one.

---

# Why Does the Price Keep Growing?

Notice something.

The formula is:

```text
Price = 1.0001^Tick
```

This is an **exponential function**.

As the Tick becomes larger,

the exponent becomes larger,

so the price keeps increasing.

Likewise,

as the Tick becomes more negative,

the exponent becomes smaller,

causing the price to approach zero.

This is exactly why:

- Very large positive Ticks correspond to very high prices.
- Very large negative Ticks correspond to very low prices.

---

# Child Analogy — Stairs

Imagine climbing a staircase.

Each step is very small.

One step doesn't make you much higher.

But after climbing

```text
1000
```

steps,

you end up very high above the ground.

Ticks work exactly the same way.

Each Tick changes the price only a tiny amount.

Thousands of Ticks create huge price differences.

---

# Why Exactly 1.0001?

One question naturally comes to mind.

> **Why did Uniswap choose 1.0001?**

Could they have chosen:

```text
1.0002
```

Yes.

They could have chosen any number greater than one.

For example:

```text
1.00001

1.00005

1.0001

1.0002

1.001
```

All of these would work mathematically.

The real question is:

> **How much should the price change between two neighboring Ticks?**

With

```text
1.0001
```

every Tick changes the price by approximately

```text
0.01%
```

This creates a very fine and precise price grid.

If Uniswap had chosen

```text
1.001
```

every Tick would change the price by roughly

```text
0.1%
```

The price grid would become much coarser.

LPs would lose the ability to choose very precise price ranges.

On the other hand,

if Uniswap had chosen

```text
1.00001
```

the price grid would become extremely precise,

but the protocol would need many more Ticks to cover the same price range, making the system more complex.

So,

```text
1.0001
```

is simply an engineering compromise between:

- Precision
- Efficiency

---

# Child Analogy — Measuring Scale

Imagine you're making a ruler.

You could place markings every:

```text
1 mm
```

or every

```text
2 mm
```

or every

```text
10 mm
```

A ruler with markings every

```text
1 mm
```

is very precise,

but it contains lots of markings.

A ruler with markings every

```text
10 mm
```

is much simpler,

but much less precise.

Ticks work exactly the same way.

Uniswap had to decide how close together neighboring price levels should be.

It chose a spacing of approximately

```text
0.01%
```

between adjacent Ticks,

which corresponds to using the multiplier:

```text
1.0001
```

---

# Why Not Store the Price Directly?

Another question naturally comes up.

> **Why not simply store the price itself?**

Instead of storing something like

```text
1.23456789
```

why store

```text
Tick = 2107
```

instead?

Because integers are much easier for the protocol to work with.

Later,

liquidity positions will be defined using:

```text
Lower Tick

Upper Tick
```

instead of arbitrary decimal prices.

This makes tracking liquidity, swaps, and fee accounting much more efficient.

---

# Key Takeaways

- In Uniswap V2, the spot price is calculated from the pool reserves.
- In Uniswap V3, reserves are no longer the primary state, so the protocol tracks the current price differently.
- Uniswap V3 stores an integer called the **Tick** instead of storing arbitrary decimal prices.
- Every Tick corresponds to exactly one price.
- Tick `0` represents a price of `1`.
- Positive Ticks correspond to prices greater than `1`.
- Negative Ticks correspond to prices less than `1`.
- The relationship between Tick and Price is:

```text
Price = 1.0001^Tick
```

- The multiplier `1.0001` was chosen as an engineering compromise, providing very fine price precision while keeping the protocol efficient.
- Ticks can be thought of as numbered price levels, similar to floors in a building or markings on a ruler.