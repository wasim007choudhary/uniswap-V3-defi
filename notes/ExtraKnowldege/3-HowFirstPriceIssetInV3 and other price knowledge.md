# Extra Knowledge — How Is The Initial Price Set In Uniswap V3?

---

> ## 💡 Why Read This?
>
> While studying Uniswap V3, one common question is:
>
> > **"If there are infinitely many ticks and many Liquidity Providers (LPs), who decides the very first price of the pool?"**
>
> This note answers that question and explains how a pool goes from **an empty contract** to **a live market**.

---

# Step 1 — A New Pool Is Created

Suppose someone creates a new pool for

```text
ETH / USDC
```

Immediately after creation,

the pool looks like this.

```text
ETH / USDC Pool

Liquidity = 0

Price = ?
```

Notice something.

The pool has:

- ✅ A smart contract.
- ✅ Two tokens.
- ❌ No liquidity.
- ❌ No market price.

Since nobody has deposited liquidity,

no trading can happen.

---

# Step 2 — The Creator Sets The Initial Price

Before anyone can trade,

the pool must know

> **What is the current price?**

Unlike future prices,

the protocol **cannot calculate the first price itself.**

Instead,

the pool creator initializes the pool by calling

```solidity
initialize(uint160 sqrtPriceX96)
```

This function sets the pool's **initial square root price**, which also determines the initial current tick.

For example,

the creator may initialize the pool with

```text
1 ETH = 2000 USDC
```

or

```text
1 ETH = 3500 USDC
```

or any other desired starting price.

This becomes the pool's **first market price**.

---

# 👶 Child Analogy — Opening A Fruit Shop

Imagine you open a fruit shop.

The shop is empty.

Question:

Who decides the first price of apples?

The customers?

❌ No.

The market?

❌ No.

The shop owner writes

```text
Apples

₹100 / kg
```

That becomes the starting price.

Uniswap works exactly the same way.

When a new pool is created,

someone must decide

```text
1 ETH = 2000 USDC
```

That becomes the initial price.

---

# Step 3 — Still No Liquidity

Even though the initial price now exists,

the pool still has

```text
Liquidity = 0
```

Nobody has deposited tokens yet.

So,

users still cannot trade.

---

# Step 4 — Liquidity Providers Arrive

Now Liquidity Providers begin adding liquidity.

Suppose the current price is

```text
2000 USDC / ETH
```

Alice provides liquidity between

```text
1800 → 2500
```

Bob provides liquidity between

```text
1900 → 2200
```

Charlie provides liquidity between

```text
2000 → 3000
```

Notice something important.

The LPs **do not choose the current price.**

Instead,

they choose **the price range over which they want their liquidity to be active.**

The current price already exists because the pool was initialized earlier.

---

# Common Misconception

Many beginners think

> "If there are many LPs, do they vote on the first price?"

No.

The first price is **not** determined by the LPs.

The creator initializes the pool with an initial price.

LPs simply decide

> **"Around that price, where should my liquidity exist?"**

---

# Step 5 — The First Swap Happens

Suppose the pool starts with

```text
1 ETH = 2000 USDC
```

A user buys ETH.

The price moves to

```text
2020
```

Another swap occurs.

```text
2050
```

Another.

```text
2080
```

Now,

the price is no longer controlled by the creator.

Instead,

it changes naturally as users trade.

---

# 👶 Child Analogy — An Auction

Imagine an auction.

The auctioneer announces

```text
Starting Price

₹10,000
```

That is the initial price.

Now people begin bidding.

```text
₹11,000

↓

₹12,000

↓

₹15,000
```

Who chose the first price?

The auctioneer.

Who determines every later price?

The bidders.

Uniswap V3 works exactly the same way.

---

# Where Do Ticks Come In?

Ticks are mathematical price points.

They extend across the entire price axis.

```text
... Tick-3

↓

Tick-2

↓

Tick-1

↓

Tick0

↓

Tick1

↓

Tick2

↓

Tick3 ...
```

Every tick corresponds to one unique price.

However,

most ticks never contain liquidity.

Only ticks chosen as

- `tickLower`
- `tickUpper`

become **initialized ticks**.

---

# What Happens During Initialization?

Suppose the creator initializes the pool at

```text
1 ETH = 2000 USDC
```

Internally,

Uniswap converts that price into

```text
sqrtPriceX96
```

and also determines the corresponding

```text
Current Tick
```

For example,

```text
Price

↓

2000

↓

Current Tick

↓

76012
```

*(The tick number above is only an example.)*

That tick becomes the pool's starting point.

---

# After Initialization

Once the pool is live,

every swap moves the current tick.

Example:

```text
76012

↓

76013

↓

76014

↓

76015
```

or

```text
76012

↓

76011

↓

76010
```

Whenever an initialized tick is crossed,

the pool updates the Active Liquidity using

```text
liquidityNet
```

Exactly as we learned in the swap lessons.

---

# Complete Lifecycle

```text
Pool Created
      │
      ▼
Liquidity = 0
No Price Yet
      │
      ▼
Creator Calls initialize()
Sets Initial Price
(Current Tick Determined)
      │
      ▼
Liquidity Providers Add Liquidity
Around The Current Price
      │
      ▼
Users Start Swapping
      │
      ▼
Current Price Moves
(Current Tick Changes)
      │
      ▼
Initialized Tick Crossed?
      │
 Yes  ▼
Apply liquidityNet
Update Active Liquidity
Continue Swap
```

---

# 📝 Key Takeaways

- Creating a pool does **not** automatically determine its price.
- The pool creator sets the **initial price** by calling `initialize(sqrtPriceX96)`.
- The initial price determines the pool's initial **Current Tick**.
- Liquidity Providers do **not** choose the current price; they choose the price ranges where they want their liquidity to be active.
- After initialization, all future prices are determined naturally by swaps.
- Swaps move the **Current Tick** left or right.
- Whenever the Current Tick crosses an initialized tick, `liquidityNet` is applied to update the Active Liquidity.
- The creator only sets the **starting price once**. From that point onward, the market determines the price.

---
---
---
# Extra Knowledge — Does a Uniswap V3 Pool Have a Price Orientation?

---

> ## 💡 Why Read This?
>
> While learning Uniswap V3, many people naturally think of markets like:
>
> - ETH/USDC
> - BTC/USD
> - EUR/USD
>
> This often leads to an important question:
>
> > **When someone creates a Uniswap V3 pool, are they creating a "WETH priced in USDC" pool or a "USDC priced in WETH" pool?**
>
> The answer is **no**, and understanding why will make the rest of Uniswap V3 much easier.

---

# The Question

Suppose Alice creates a pool containing

```text
WETH

USDC
```

Did she create

```text
A WETH priced in USDC pool?
```

or

```text
A USDC priced in WETH pool?
```

Neither.

She simply created

```text
A pool between WETH and USDC.
```

The pool itself has **no economic opinion** about which token should be considered the "main" asset.

---

# The Pool Is Neutral

Think of the pool as a container.

```text
┌─────────────────────┐
│                     │
│      WETH           │
│         +           │
│      USDC           │
│                     │
└─────────────────────┘
```

That's all the pool knows.

It does **not** think

> "I'm an ETH-priced-in-USDC pool."

Nor does it think

> "I'm a USDC-priced-in-ETH pool."

It simply holds a relationship between two assets.

---

# Then Why Do Humans Say

```text
1 ETH = 2000 USDC
```

Because **humans** like quoting prices that way.

For example, we naturally say

```text
ETH/USD

BTC/USD

EUR/USD
```

Those are **human market conventions.**

The pool itself doesn't care.

---

# Child Analogy — A Box Of Fruits

Imagine a box containing

```text
🍎 Apples

🍊 Oranges
```

Does the box think

> "I'm an Apple priced in Orange box."

❌ No.

Or

> "I'm an Orange priced in Apple box."

❌ No.

It's simply

```text
Apple

+

Orange
```

Now suppose someone asks

> "How many oranges equal one apple?"

That's **your question**, not the box's.

The box is completely neutral.

A Uniswap pool behaves exactly the same way.

---

# So Where Does

```text
1 ETH = 2000 USDC
```

Come From?

When the pool is initialized,

the creator chooses an **initial exchange ratio.**

For example,

they might say

```text
1 ETH = 2000 USDC
```

This is **not naming the pool.**

It is simply telling the protocol

> **"Start this market at this exchange rate."**

The protocol then converts that exchange ratio into its internal representation.

---

# The Pool Stores A Relationship

Think of the relationship like this.

```text
ETH

⇄

USDC
```

Not

```text
ETH

↓

USDC
```

or

```text
USDC

↓

ETH
```

The pool stores a relationship between the two assets.

---

# The Same Market Can Be Written Two Ways

Suppose

```text
1 ETH = 2000 USDC
```

The exact same market can also be written as

```text
1 USDC = 0.0005 ETH
```

Both statements describe **the exact same exchange rate.**

Nothing about the market changed.

Only the way humans chose to write it changed.

---

# Child Analogy — Distance

Imagine I ask

> "How many meters are in one kilometer?"

You answer

```text
1000
```

Now I ask

> "How many kilometers are in one meter?"

You answer

```text
0.001
```

Did the distance change?

No.

Only the way we described it changed.

Exactly the same thing happens with token prices.

---

# What Does The Protocol Actually Care About?

Internally,

Uniswap only cares about values like

```text
token0

token1

Current Tick

sqrtPriceX96
```

These values allow the protocol to perform all mathematical calculations.

The protocol does **not** store concepts like

```text
ETH priced in USDC
```

or

```text
USDC priced in ETH
```

Those are simply human interpretations.

---

# What Is The Creator Actually Choosing?

When Alice creates the pool,

she is **not** saying

> "This is a WETH priced in USDC pool."

Instead,

she is saying

> "Create a market between WETH and USDC."

Then,

during initialization,

she chooses the starting exchange ratio.

For example,

```text
1 ETH = 2000 USDC
```

The protocol converts that ratio into

- `sqrtPriceX96`
- Current Tick

and stores those values internally.

---

# Complete Picture

```text
Alice Creates Pool

        │

        ▼

Pool Contains

WETH + USDC

        │

        ▼

Alice Chooses

Initial Exchange Rate

1 ETH = 2000 USDC

        │

        ▼

Protocol Converts It To

sqrtPriceX96

Current Tick

        │

        ▼

Liquidity Providers Add Liquidity

        │

        ▼

Users Start Swapping

        │

        ▼

The Market Determines Future Prices
```

---

# 📝 Key Takeaways

- A Uniswap V3 pool is **not** a "WETH priced in USDC" pool.
- A Uniswap V3 pool is **not** a "USDC priced in WETH" pool.
- The pool is simply a market between two tokens.
- Humans describe the market using familiar price quotes such as:
  - `1 ETH = 2000 USDC`
  - `1 USDC = 0.0005 ETH`
- Both price quotes describe the **same market**.
- During initialization, the creator chooses only the **starting exchange ratio**, not the "orientation" of the pool.
- Internally, the protocol stores mathematical values (`sqrtPriceX96`, Current Tick, `token0`, `token1`) rather than human-readable price descriptions.
- After initialization, the market price is determined entirely by swaps.
>Note:Best of luck come back here when you get confused when deep diving the notes etc, Happned to me. Whenever yougo detailed deep diving sometimes you forget or get confused with the basic knowldge so this clock backs in atleast for me. hope this helps.