# Uniswap V3 — Lesson 1: Concentrated Liquidity

> **Goal:** Before diving into the implementation of Uniswap V3, we first need to understand **why Uniswap V3 was created**. Just like we did in Uniswap V2, we're not going to memorize concepts—we're going to understand the reasoning behind every design decision.

---

# Before We Begin

One thing I noticed immediately is that this lesson actually mixes **four different concepts** together.

Instead of learning all of them at once, we'll break them apart and understand each one individually.

This lesson contains:

1. **Why Uniswap V2 is Capital Inefficient**
2. **Concentrated Liquidity**
3. **Real vs. Virtual Reserves**
4. **Liquidity Amplification**

We'll stop after every concept and make sure it is crystal clear before moving on.

---

# Lesson 1 — Concentrated Liquidity

## Part 1 — Recap of Uniswap V2

Let's start with something we already know.

Suppose we have a DAI/USDC pool.

```text
DAI  = 100
USDC = 100
```

Current price:

```text
100 / 100 = 1
```

Therefore,

```text
1 DAI = 1 USDC
```

Nothing new here.

This is exactly how Uniswap V2 works.

---

## Someone Swaps 1 DAI

Now suppose someone swaps

```text
1 DAI
```

into the pool.

The pool becomes approximately:

```text
DAI  = 101
USDC ≈ 99
```

The new price becomes

```text
99 / 101 ≈ 0.98
```

---

### Notice something.

We swapped only

```text
1 token
```

yet the price already changed noticeably.

At this point I asked myself:

> **"Why does such a tiny swap move the price so much?"**

The answer comes directly from the equation we already learned in Uniswap V2.

```text
x · y = k
```

When reserves are small,

moving along the constant-product curve changes the price much faster.

```text
Small Liquidity
       ↓
Large Price Impact
```

This is true for every Constant Product AMM.

---

# So How Do We Reduce Price Impact?

The obvious answer is:

> **Increase liquidity.**

Instead of

```text
100 DAI
100 USDC
```

suppose the pool has

```text
200 DAI
200 USDC
```

Now if someone swaps

```text
1 DAI
```

the reserves barely change.

Instead of the price moving to

```text
0.98
```

it may remain much closer to

```text
0.995
```

---

## First Important Rule

> **More Liquidity = Less Slippage = Smaller Price Movement**

This is one of the most important rules in every AMM.

---

# But Then a Bigger Question Came Up...

Suppose this is a

```text
DAI / USDC
```

pool.

I asked:

> **"Where do traders actually trade?"**

Almost always around

```text
0.99

↓

1.00

↓

1.01
```

Could the price become

```text
5
```

or

```text
50
```

Yes.

It is mathematically possible.

But under normal market conditions,

the market spends almost all of its time near

```text
1.00
```

---

# Then Where Is Our Liquidity?

This is where the important realization begins.

In Uniswap V2,

our liquidity supports

```text
0 ------------------------------------------------------------ ∞
```

Every possible price.

Our deposited capital promises liquidity whether the price is

```text
0.5

1

2

10

100
```

---

# At This Point I Asked...

> **"The tokens are still inside the pool. How are they wasted?"**

This is actually a really good question.

Because the tokens are **not**

- Burned
- Lost
- Deleted
- Removed from the pool

They're still sitting inside the pool.

So how can anyone say the liquidity is "wasted"?

---

## The Answer

The word

> **"Wasted"**

is actually misleading.

A much better phrase is

> **Capital Inefficiency**

The tokens still exist.

The protocol still owns them.

Nothing disappears.

The issue isn't that the capital is gone.

The issue is

> **where that capital is deployed.**

---

# Restaurant Analogy

Imagine you own a restaurant.

You have

```text
100 employees.
```

During lunch,

only

```text
20 employees
```

are actually serving customers.

The remaining

```text
80
```

are standing around waiting because there isn't enough work.

Did those employees disappear?

No.

Do they still exist?

Yes.

Are you still paying them?

Yes.

But most of them are not contributing much.

That is exactly what

> **Capital Inefficiency**

means.

---

# V2 Is Similar

Suppose almost every trade happens near

```text
1.00
```

Yet your liquidity is spread across

```text
0 → ∞
```

Most of your deposited capital is reserved for prices that might rarely be visited.

Nothing is wrong with the tokens.

The deployment of the capital is inefficient.

---

# Then Uniswap V3 Asked a Different Question

Instead of asking

> **"Can we add more liquidity?"**

the Uniswap team asked

> **"Why not move the existing liquidity only to where trading actually happens?"**

That single question led to one of the biggest innovations in DeFi.

> **Concentrated Liquidity**

---

# Concentrated Liquidity

After understanding why Uniswap V2 is capital inefficient, the next obvious question became:

> **"If most trades happen near the current price, why are we providing liquidity across every possible price?"**

This question is exactly what led to **Concentrated Liquidity**.

---

## The Idea

Suppose you tell the protocol:

Instead of providing liquidity across

```text
0 → ∞
```

I only want to provide liquidity between

```text
0.99

↓

1.01
```

Now something completely changes.

Your liquidity **only exists inside that price range**.

Outside this range:

```text
No liquidity from you.
```

Inside this range:

```text
All of your liquidity.
```

---

## Visualizing the Difference

### Uniswap V2

Your liquidity is spread across every possible price.

```text
0 ------------------------------------------------------- ∞
██████████████████████████████████████████████████████████
```

---

### Uniswap V3

Instead of spreading your liquidity everywhere,

it is concentrated only where you choose.

```text
0 ----------------0.99====1====1.01----------------------∞
                 ███████████
```

Notice something.

The amount of deposited capital has **not changed**.

Only its **placement** has changed.

---

# At This Point I Asked...

> **"Why is this actually powerful?"**

Let's use the same example.

Imagine we deposit

```text
200 DAI

200 USDC
```

---

## In Uniswap V2

Those

```text
200 DAI

200 USDC
```

are spread across

```text
0 → ∞
```

Every possible price.

---

## In Uniswap V3

The exact same

```text
200 DAI

200 USDC
```

are compressed into

```text
0.99 → 1.01
```

Now every single token is participating in swaps that happen inside that range.

None of that liquidity is reserved for prices outside the chosen interval.

---

# Very Important

At this point it's easy to misunderstand what V3 is doing.

One thing became very clear.

> **Uniswap V3 did NOT create more money.**

We still deposited

```text
200 DAI

200 USDC
```

The protocol didn't mint extra tokens.

The protocol didn't duplicate our liquidity.

Nothing magical happened.

Instead,

it simply made those same tokens work much harder **within a specific price interval**.

That is exactly why people say

> **Uniswap V3 is Capital Efficient.**

---

# Child Analogy

Imagine you have

```text
100 soldiers.
```

## Uniswap V2

You spread them across

```text
100 km
```

of border.

```text
|S|S|S|S|S|S|S|S|S|S|S|S|...
```

Each location has very few soldiers.

---

## Uniswap V3

Now suppose you already know

the enemy will attack only

```text
between km 45 and km 55.
```

Instead of spreading everyone out,

you place all

```text
100 soldiers
```

there.

```text
------------------------------------------
          SSSSSSSSSSSSSSSSSSSSS
------------------------------------------
```

Did you recruit more soldiers?

**No.**

Did you increase your army?

**No.**

You simply deployed the same soldiers

where they actually matter.

That is exactly what

> **Concentrated Liquidity**

does.

---

# Key Takeaways

- Uniswap V2 spreads liquidity across the entire price spectrum (`0 → ∞`).
- Most trading usually happens within a much narrower price interval.
- This makes V2 **Capital Inefficient**, because much of the deposited capital is reserved for prices that are rarely visited.
- Uniswap V3 allows LPs to choose a specific price range where their liquidity will be active.
- The same deposited capital becomes much more effective within that chosen range.

---

# We Stop Here

At this point, the course moves on to:

- **Real Reserves (200 tokens)**
- **Virtual Reserves (40,100 tokens)**

I intentionally decided to stop here because this is **not** a continuation of Concentrated Liquidity.

It is an entirely new concept.

In fact, it is the mathematical trick that allows Concentrated Liquidity to work while still preserving the **Constant Product AMM**.

This is where Uniswap V3 starts becoming significantly more sophisticated, so it deserves its own dedicated lesson.

---

# Additional Discussion

During our discussion, another important question came up.

---

# My Question

At this point, I asked:

> **"Suppose I provide liquidity only between `0.90 → 1.10`. If the price moves outside my range and no other LP has provided liquidity beyond that point, does the pool become `0 / 0`?"**

This is a very natural question.

The answer is:

> **No. The pool does NOT become `0 / 0`.**

Let's understand why.

---

# Example

Suppose the pool initially contains

```text
100 TokenA
100 USDC
```

and I decide to provide liquidity only between

```text
0.90 → 1.10
```

The current price is

```text
1.00 ✅
```

Everything is working normally.

---

# Now Suppose Traders Keep Buying TokenA

Eventually, the price reaches

```text
1.10
```

At this point,

my liquidity has been **completely consumed**.

My position has effectively become **100% one token**.

For example (roughly),

```text
0 TokenA
200 USDC
```

> **Note:** Don't worry about the exact numbers yet. We'll derive them mathematically later.

---

# Then I Asked...

> **"Now someone wants to buy more TokenA. Can they?"**

The answer is:

**No.**

---

# Why?

Because my position has

```text
0 TokenA
```

left to sell.

My liquidity ended at

```text
1.10
```

---

# What If No Other LP Exists Beyond 1.10?

Suppose no one has provided liquidity for prices above

```text
1.10
```

Then, for every price above that,

the pool has

```text
Active Liquidity = 0
```

Since there is no active liquidity,

the swap cannot continue.

The transaction simply **reverts**, because there is no liquidity available to trade against.

---

# Then I Asked Another Question

> **"So does the pool become `0 TokenA / 0 USDC`?"**

Again,

the answer is:

> **No.**

The pool still contains tokens.

For example, my position might now look like

```text
0 TokenA
200 USDC
```

or, if the price had instead moved all the way to the lower boundary,

```text
200 TokenA
0 USDC
```

The important point is:

> **The reserves still exist.**

What disappears is **Active Liquidity**, not the tokens themselves.

---

# Bridge Analogy

A good way to think about this is with a bridge.

Imagine:

```text
Road ---- Bridge ---- Road
```

The bridge represents **Liquidity**.

Now imagine the bridge ends.

```text
Road ---- Bridge    X
```

Can cars continue?

**No.**

But did the road disappear?

**No.**

The only thing missing is

> **the bridge.**

Exactly the same thing happens in Uniswap V3.

The tokens still exist.

The pool still exists.

The only thing missing is

> **Active Liquidity**.

---

# So What Actually Fails?

It is **not** because

```text
TokenA = 0

USDC = 0
```

Instead,

it is because

```text
Active Liquidity = 0
```

Without active liquidity,

the AMM has nothing to trade against,

so it cannot continue quoting prices or executing swaps beyond that range.

---

# One Small Refinement

Another important realization came up during the discussion.

When we eventually dissect `swap()`,

we'll discover something interesting.

The swap function **does not ask**:

> **"Are there reserves?"**

Instead, it effectively asks:

> **"Is there active liquidity at the current price?"**

That single difference is one of the biggest conceptual shifts between Uniswap V2 and Uniswap V3.

---

# Biggest Conceptual Difference

## Uniswap V2

The central concept is

> **Reserves**

The protocol primarily cares about the pool's reserves.

---

## Uniswap V3

The central concept is

> **Active Liquidity**

The protocol primarily cares about whether there is active liquidity available at the current price.

That shift—from **Reserves** to **Active Liquidity**—is one of the most fundamental ideas in Uniswap V3 and is something to keep in mind throughout the rest of the protocol.