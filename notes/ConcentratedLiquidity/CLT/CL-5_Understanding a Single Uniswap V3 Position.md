# Lesson — Understanding a Single Uniswap V3 Position

This lesson is **not really about graphs**.

Instead, it's introducing one of the most important concepts in Uniswap V3:

> **A Position**

Forget the graph for now.

We'll understand the concept first.

---

# First Question

Until now, we've always talked about:

```text
The Pool
```

Now let's ask a question.

Suppose there are **100 Liquidity Providers (LPs).**

Do they all have to provide liquidity in the same price range?

Obviously not.

For example,

Alice chooses:

```text
0.99

↓

1.01
```

Bob chooses:

```text
0.95

↓

1.05
```

Charlie chooses:

```text
1.10

↓

1.30
```

Immediately we notice something.

The pool no longer has one giant shared liquidity.

Instead,

it has **many different liquidity ranges owned by different people.**

---

# Then I Asked...

> **What exactly is a Position?**

This is the biggest new concept.

In **Uniswap V2**,

adding liquidity simply meant:

> **"Here are my tokens."**

Done.

Everyone became part of one giant liquidity pool.

There was nothing unique about your liquidity.

---

In **Uniswap V3**,

adding liquidity means:

> **"Here are my tokens..."**

> **"...and I only want them to work between these prices."**

For example,

Current Price:

```text
1.00
```

I choose:

```text
Lower Price

0.99
```

and

```text
Upper Price

1.01
```

That creates **my Position.**

### Definition

> **A Position is your personal liquidity that is active only between your chosen lower and upper price (or Tick) range.**

---

# Child Analogy — Shop Rental

Imagine a huge shopping mall.

In **Uniswap V2**,

everyone throws their products into one giant supermarket.

Nobody owns a specific section.

Everyone shares everything.

---

In **Uniswap V3**,

everyone rents their own shop.

Alice rents:

```text
Shop 10

↓

Shop 20
```

Bob rents:

```text
Shop 21

↓

Shop 40
```

Charlie rents:

```text
Shop 41

↓

Shop 60
```

Each owner earns money only when customers visit **their shop**.

Exactly the same happens in Uniswap V3.

Your Position is like **your own rented shop**.

---

# Then I Asked...

> **What information do I need to create a Position?**

The lesson lists three things.

---

## 1. Current Price

First,

I need to know:

> **Where is the market right now?**

In Uniswap V3,

this is represented by the:

```text
Current Tick
```

---

## 2. My Price Range

Next,

I choose:

```text
Lower Price (Pa)

Upper Price (Pb)
```

or equivalently,

```text
Lower Tick (Ta)

Upper Tick (Tb)
```

This defines where I want my liquidity to be active.

---

## 3. Token Amounts

Finally,

I decide how many tokens I want to deposit.

For example,

```text
100 Token X

100 Token Y
```

These tokens become my liquidity position.

---

# Then I Asked...

> **Why does Uniswap use Ticks instead of Prices here?**

We already answered this in the previous lesson.

Every price corresponds to exactly one Tick.

So instead of storing:

```text
0.991278
```

the protocol stores:

```text
Tick = 120
```

Likewise,

instead of storing:

```text
1.008421
```

it stores:

```text
Tick = 200
```

Internally,

every Position is stored using:

```solidity
tickLower
tickUpper
```

instead of decimal prices.

---

# What Happens When Price Moves?

Suppose my Position is active between:

```text
0.99

↓

1.01
```

Now imagine the current price is:

```text
0.95
```

Am I active?

No.

The current price hasn't entered my chosen range yet.

---

Now the price rises.

```text
0.97

↓

0.98

↓

0.99 ✅
```

The moment the price enters my range,

my liquidity becomes active.

Now every swap that happens inside my range earns me fees.

---

The price keeps moving.

```text
1.00

↓

1.005

↓

1.01
```

I'm still active.

---

Eventually,

the price becomes:

```text
1.02
```

Now my Position becomes inactive again,

because the market has moved outside my chosen range.

---

# Child Analogy — Toll Booth

Imagine you own a toll booth.

Your toll booth only exists on:

```text
Road 20 km

↓

Road 30 km
```

Cars driving between **20 km and 30 km** must pass your booth.

You earn money.

But if cars are driving on:

```text
Road 40 km
```

they never reach your booth.

You don't earn anything,

even though your booth still exists.

Exactly the same happens in Uniswap V3.

Your Position only earns fees while the current price stays inside your chosen range.

---

# Then I Asked...

> **What happens to my tokens while the price moves?**

This is one of the coolest parts of Uniswap V3.

Suppose I start with:

```text
100 Token X

100 Token Y
```

As traders swap,

my Position slowly changes.

If price keeps increasing,

my Position gradually becomes:

```text
80 Token X

120 Token Y
```

↓

```text
50 Token X

150 Token Y
```

↓

```text
20 Token X

180 Token Y
```

↓

```text
0 Token X

200 Token Y
```

Notice,

nothing happens instantly.

The conversion is gradual.

---

If instead,

price keeps decreasing,

the opposite happens.

```text
100 Token X

100 Token Y
```

↓

```text
120 Token X

80 Token Y
```

↓

```text
150 Token X

50 Token Y
```

↓

```text
200 Token X

0 Token Y
```

Again,

the conversion is gradual.

---

# Child Analogy — Two Water Tanks

Imagine two connected water tanks.

One contains red water.

The other contains blue water.

As you slowly turn a valve,

water gradually flows from one tank into the other.

Initially,

both tanks contain water.

Eventually,

one tank becomes completely empty,

while the other becomes completely full.

Nothing happens suddenly.

The change is continuous.

Your liquidity Position behaves exactly the same way.

As price moves,

your Position gradually transforms:

- from mostly Token X to mostly Token Y, or
- from mostly Token Y to mostly Token X.

---

# One Important Note

The lesson mentions values such as:

```text
0 Token X

214 Token Y
```

or

```text
214 Token X

0 Token Y
```

Don't focus on the number **214**.

It comes from the liquidity mathematics that we'll derive later.

The important takeaway is simply:

- **Price below your range (`P < Pa`) → Your Position becomes 100% Token X (Token0).**
- **Price inside your range (`Pa ≤ P ≤ Pb`) → Your Position contains a mixture of Token X (Token0) and Token Y (Token1).**
- **Price above your range (`P > Pb`) → Your Position becomes 100% Token Y (Token1).**

That is the real concept this lesson is trying to teach.

---

# Key Takeaways

- A **Position** is your personal liquidity that is active only within your chosen price (Tick) range.
- Unlike V2, every LP can choose a completely different price range.
- Creating a Position requires:
  - The current price (Current Tick).
  - A lower price/Tick.
  - An upper price/Tick.
  - The token amounts to deposit.
- Your Position becomes active only when the current price enters your chosen range.
- Your Position stops earning swap fees once the current price leaves your chosen range.
- As price moves, the composition of your Position changes continuously.
- Above your range, your Position becomes entirely **Token1**.
- Below your range, your Position becomes entirely **Token0**.
- Inside your range, your Position always contains a changing mixture of both tokens.

---

## Additional Discussion — Token Composition Above and Below Your Price Range

While studying liquidity positions, an important question came up.

> **Does the rule "Above the range = Token Y" and "Below the range = Token X" always hold true?**

The answer is:

**Yes**, but it's more accurate to describe it using **Token0** and **Token1**, since those are the terms used throughout the Uniswap V3 protocol.

For simplicity, assume:

```text
Token X = Token0

Token Y = Token1
```

---

## Price Above Your Range (`P > Pb`)

When the current price moves **above your upper price range**, your Position gradually converts into:

```text
0 Token X (Token0)

100% Token Y (Token1)
```

Why?

Because traders have continuously swapped **Token X (Token0)** out of your Position.

Eventually, there is no Token X left.

---

## Price Below Your Range (`P < Pa`)

When the current price moves **below your lower price range**, your Position gradually converts into:

```text
100% Token X (Token0)

0 Token Y (Token1)
```

Why?

Because traders have continuously swapped **Token X (Token0)** into your Position.

Eventually, your Position contains only Token X.

---

# Why Does This Happen?

Let's understand it using a real example.

Suppose we have an:

```text
ETH / USDC
```

pool.

Assume:

```text
Token0 = ETH

Token1 = USDC
```

Current price:

```text
1 ETH = 2000 USDC
```

---

## Scenario 1 — ETH Price Increases

Now suppose ETH rises to:

```text
1 ETH = 2500 USDC
```

Ask yourself:

> **What caused the price to increase?**

People kept **buying ETH**.

But where did that ETH come from?

It came from the Liquidity Providers.

As traders continue buying ETH:

- Your ETH (Token0) decreases.
- Your USDC (Token1) increases.

Eventually, once the price moves above your chosen range, your Position becomes:

```text
0 ETH

100% USDC
```

---

## Scenario 2 — ETH Price Decreases

Now suppose ETH falls from:

```text
2000 USDC

↓

1500 USDC
```

What happened?

People are now **selling ETH**.

As they sell ETH into the pool:

- Your Position keeps receiving ETH.
- Your USDC decreases.

Eventually, once the price moves below your chosen range, your Position becomes:

```text
100% ETH

0 USDC
```

---

# General Rule

This rule is true for every Uniswap V3 Position.

| Current Price | Position Composition |
|---------------|----------------------|
| **Below Lower Range (`P < Pa`)** | **100% Token0 (Token X)** |
| **Inside Range (`Pa ≤ P ≤ Pb`)** | **A mixture of Token0 and Token1** |
| **Above Upper Range (`P > Pb`)** | **100% Token1 (Token Y)** |

---

# Final Rule to Remember

- **Price below your range (`P < Pa`) → Your Position becomes 100% Token0 (Token X).**
- **Price inside your range (`Pa ≤ P ≤ Pb`) → Your Position contains a mixture of Token0 and Token1.**
- **Price above your range (`P > Pb`) → Your Position becomes 100% Token1 (Token Y).**

This is the general rule you'll use throughout Uniswap V3.
