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