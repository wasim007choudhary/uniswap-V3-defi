# Lesson — Visualizing Multiple Positions on a Liquidity Price Graph

## Forget the Graph for a Moment

The lesson title talks about **graphs**, but the graph is only a visualization.

The real concept being introduced is much more important:

> **How does a Uniswap V3 pool behave when many liquidity providers (LPs) have different Positions?**

Once we understand that concept, the graph becomes easy.

So let's ignore the graph for now and first understand the protocol.

---

# First Question

Until now, we've always discussed a pool as if there were only **one liquidity provider.**

For example,

Alice provides liquidity between:

```text
0.99
 ↓
1.01
```

Simple.

Whenever the current price is inside Alice's range, her liquidity is active.

Whenever the current price leaves her range, her liquidity becomes inactive.

Nothing complicated.

---

# But Real Pools Don't Work Like That

Now let's ask a better question.

Suppose there are **100 liquidity providers.**

Do they all have to choose the same price range?

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
0.98
 ↓
1.03
```

Charlie chooses:

```text
1.00
 ↓
1.02
```

Now something interesting happens.

The pool no longer consists of one Position.

Instead,

the pool contains **many different Positions**, each owned by a different LP.

This is one of the biggest conceptual differences between Uniswap V2 and V3.

---

# In Uniswap V2

Everyone simply deposited tokens into one giant shared pool.

There was no individuality.

All LPs shared exactly the same liquidity.

Conceptually:

```text
Pool

████████████████████████████
```

Everyone owned a percentage of the same pool.

---

# In Uniswap V3

Every LP owns **their own Position.**

For example:

```text
Alice

0.99
 ↓
1.01
```

```text
Bob

0.98
 ↓
1.03
```

```text
Charlie

1.00
 ↓
1.02
```

Each Position has:

- its own lower tick,
- its own upper tick,
- its own liquidity,
- its own fees.

The pool is really just a collection of thousands of independent Positions.

---

# Then I Asked...

## If many Positions exist...

### Which liquidity gets used during a swap?

Imagine the current price is:

```text
1.005
```

This lies inside:

- Alice's Position ✅
- Bob's Position ✅
- Charlie's Position ✅

Now a trader performs a swap.

Who provides liquidity?

Only Alice?

Only Bob?

Only Charlie?

The answer is:

> **Every Position that is currently active contributes liquidity.**

If the current price lies inside your range,

your Position participates in the swap.

If the current price is outside your range,

your Position contributes nothing.

---

# Child Analogy — People Pulling a Truck

Imagine a huge truck.

Three people are helping pull it.

Alice can pull:

```text
100 units
```

Bob can pull:

```text
150 units
```

Charlie can pull:

```text
200 units
```

If all three are holding the truck,

their strength combines.

Nobody asks:

> "Whose strength should we use?"

The truck simply feels:

```text
100

+

150

+

200

=

450 units
```

Exactly the same thing happens in Uniswap V3.

The protocol simply combines all active liquidity.

---

# Example

Suppose:

Alice provides:

```text
100 Liquidity
```

Bob provides:

```text
150 Liquidity
```

Charlie provides:

```text
200 Liquidity
```

Now suppose the current price lies inside:

- Alice's range ✅
- Bob's range ✅
- Charlie's range ❌

How much liquidity is currently available?

The protocol simply adds:

```text
100

+

150

=

250 Liquidity
```

Charlie's liquidity is ignored because his Position is inactive.

---

# Then I Asked...

## What happens when price moves?

Suppose the market price keeps increasing.

Eventually,

Alice's upper price is crossed.

Alice becomes inactive.

Current active liquidity becomes:

```text
150
```

The price keeps increasing.

Eventually,

Bob also becomes inactive.

Now only Charlie remains active.

Current active liquidity becomes:

```text
200
```

Notice something important.

Unlike Uniswap V2,

the pool's liquidity is **not fixed.**

It constantly changes depending on which Positions overlap the current market price.

That is a fundamental property of Uniswap V3.

---

# Child Analogy — Flashlights

Imagine three flashlights.

Alice shines light only between:

```text
10 m
 ↓
20 m
```

Bob shines light between:

```text
15 m
 ↓
30 m
```

Charlie shines light between:

```text
25 m
 ↓
40 m
```

Now suppose you're standing at:

```text
18 m
```

Both Alice and Bob illuminate you.

The road is brighter.

Now walk to:

```text
27 m
```

Bob and Charlie illuminate you.

Alice no longer contributes.

Now walk to:

```text
35 m
```

Only Charlie shines on you.

Exactly the same thing happens with liquidity.

Only Positions whose ranges include the current price are active.

---

# Then I Asked...

## Why did the lesson stack the rectangles?

The stacked rectangles are simply showing one thing:

**Addition.**

Suppose:

Alice provides:

```text
100 Liquidity
```

Bob provides:

```text
200 Liquidity
```

If both Positions are active,

the protocol simply sees:

```text
100

+

200

=

300 Liquidity
```

The rectangles are stacked because the active liquidity is the **sum** of every active Position.

Nothing more.

# Then I Asked...

## If Alice and Bob's Positions overlap...

### How does the protocol know how much liquidity belongs to Alice and how much belongs to Bob?

This is where I got confused.

Suppose:

Alice provides:

```text
100 Liquidity
```

Bob provides:

```text
200 Liquidity
```

Both Positions overlap the current market price.

The pool currently behaves as if it has:

```text
100

+

200

=

300 Liquidity
```

Now suppose someone performs a swap.

At first, I thought:

> Does the protocol first use Alice's liquidity?

Or

> Does it first use Bob's liquidity?

The answer is:

**Neither.**

The protocol treats the pool as if it has one large pool of:

```text
300 Liquidity
```

for the purpose of executing the swap.

It does **not** choose one Position over another.

Instead,

every active Position contributes simultaneously.

---

# Child Analogy — Carrying a Sofa

Imagine Alice and Bob are carrying a heavy sofa.

Alice can support:

```text
100 kg
```

Bob can support:

```text
200 kg
```

Together,

they can support:

```text
300 kg
```

Now someone places another:

```text
30 kg
```

on the sofa.

Who carried the extra weight?

Not just Alice.

Not just Bob.

Both.

Alice naturally carries:

```text
100 / 300

=

1/3
```

Bob naturally carries:

```text
200 / 300

=

2/3
```

Exactly the same thing happens in Uniswap V3.

The swap uses everyone's active liquidity simultaneously.

---

# Then I Asked...

## If everything is combined...

### Doesn't the protocol lose track of who owns what?

No.

This is the genius part of the design.

Although the swap behaves as if the pool has one giant liquidity amount,

every Position is still stored independently.

Conceptually,

Alice's Position looks something like:

```solidity
Position
{
    liquidity = 100;
    tickLower = ...;
    tickUpper = ...;
}
```

Bob's Position:

```solidity
Position
{
    liquidity = 200;
    tickLower = ...;
    tickUpper = ...;
}
```

The protocol never mixes Alice's Position with Bob's Position.

Instead,

it temporarily sums their liquidity **only for swap calculations.**

After the swap,

both Positions still remain completely separate.

This is a very important mental model.

> **The pool behaves like one large pool during swaps, but internally every Position remains independent.**

---

# Then I Asked...

## If Alice and Bob's Positions overlap...

### How does the protocol know how much liquidity belongs to Alice and how much belongs to Bob?

This is where I got confused.

Suppose:

Alice provides:

```text
100 Liquidity
```

Bob provides:

```text
200 Liquidity
```

Both Positions overlap the current market price.

The pool currently behaves as if it has:

```text
100

+

200

=

300 Liquidity
```

Now suppose someone performs a swap.

At first, I thought:

> Does the protocol first use Alice's liquidity?

Or

> Does it first use Bob's liquidity?

The answer is:

**Neither.**

The protocol treats the pool as if it has one large pool of:

```text
300 Liquidity
```

for the purpose of executing the swap.

It does **not** choose one Position over another.

Instead,

every active Position contributes simultaneously.

---

# Child Analogy — Carrying a Sofa

Imagine Alice and Bob are carrying a heavy sofa.

Alice can support:

```text
100 kg
```

Bob can support:

```text
200 kg
```

Together,

they can support:

```text
300 kg
```

Now someone places another:

```text
30 kg
```

on the sofa.

Who carried the extra weight?

Not just Alice.

Not just Bob.

Both.

Alice naturally carries:

```text
100 / 300

=

1/3
```

Bob naturally carries:

```text
200 / 300

=

2/3
```

Exactly the same thing happens in Uniswap V3.

The swap uses everyone's active liquidity simultaneously.

---

# Then I Asked...

## If everything is combined...

### Doesn't the protocol lose track of who owns what?

No.

This is the genius part of the design.

Although the swap behaves as if the pool has one giant liquidity amount,

every Position is still stored independently.

Conceptually,

Alice's Position looks something like:

```solidity
Position
{
    liquidity = 100;
    tickLower = ...;
    tickUpper = ...;
}
```

Bob's Position:

```solidity
Position
{
    liquidity = 200;
    tickLower = ...;
    tickUpper = ...;
}
```

The protocol never mixes Alice's Position with Bob's Position.

Instead,

it temporarily sums their liquidity **only for swap calculations.**

After the swap,

both Positions still remain completely separate.

This is a very important mental model.

> **The pool behaves like one large pool during swaps, but internally every Position remains independent.**

---

# Then I Asked...

## How are fees distributed?

Suppose a swap generates:

```text
3 USDC
```

of fees.

Current active liquidity:

```text
300
```

Alice owns:

```text
100
```

Bob owns:

```text
200
```

Alice's share:

```text
100 / 300

=

1/3
```

Bob's share:

```text
200 / 300

=

2/3
```

Therefore,

Alice receives:

```text
1 USDC
```

Bob receives:

```text
2 USDC
```

Fees are distributed proportionally according to each Position's liquidity.

No Position is treated specially.

---

# Then I Asked...

## Okay, I understand liquidity.

### But how does the protocol know how many tokens Alice currently owns?

This is a completely different question.

There are actually two different things.

---

## 1. Liquidity

Liquidity is stored.

For example:

```text
Alice

Liquidity = 100
```

```text
Bob

Liquidity = 200
```

The protocol always knows this.

---

## 2. Current Token Amounts

This is different.

Suppose Alice initially deposited:

```text
100 Token X

100 Token Y
```

As trades occur,

her Position continuously changes.

For example,

later it might become:

```text
80 Token X

120 Token Y
```

Later:

```text
40 Token X

160 Token Y
```

Eventually:

```text
0 Token X

214 Token Y
```

These token balances are **not stored** after every swap.

Instead,

they are calculated whenever they are needed.

---

# What Does the Protocol Store?

The protocol stores only the minimum information necessary.

For every Position,

it stores things like:

- Liquidity (`L`)
- Lower Tick
- Upper Tick

That's enough.

Whenever someone wants to know the current token balances,

the protocol calculates them using:

- Liquidity (`L`)
- Current Price (`P`)
- Lower Price (`Pa`)
- Upper Price (`Pb`)

using the liquidity formulas we'll derive later.

---

# Stored vs Calculated

## Stored Permanently

```text
Liquidity

Lower Tick

Upper Tick
```

These values are stored on-chain.

---

## Calculated Whenever Needed

```text
Current Token0 Amount

Current Token1 Amount
```

These are not stored.

They are derived mathematically whenever someone queries or updates the Position.

---

# Why Doesn't Uniswap Store Current Token Balances?

Because it would be incredibly expensive.

Imagine there are:

```text
500,000 Positions
```

Every swap would have to update the balances of every affected Position.

That would consume an enormous amount of gas.

Instead,

Uniswap stores only the minimum information required and derives the current balances mathematically whenever they are needed.

This is one of the biggest gas optimizations in the entire protocol.

---

# Child Analogy — Bank Account

Imagine a bank.

The bank stores:

- Your account number.
- Your transaction history.

It doesn't create a new paper statement every second.

Whenever you open the banking app,

your balance is calculated from the stored information.

Uniswap V3 works similarly.

It stores only the important data,

then computes the current token amounts whenever someone asks.

---

# Biggest Takeaways

- A Uniswap V3 pool is made up of many independent Positions.
- Every Position has its own liquidity and price range.
- During a swap, all active Positions contribute liquidity simultaneously.
- The pool behaves like one large liquidity pool for pricing, but every Position remains separate internally.
- Liquidity is stored permanently.
- Current token balances are calculated from liquidity and the current price whenever needed.
- Fees are distributed proportionally based on each Position's liquidity.

---

---

---
# One Final Observation — Every Position Evolves Independently

As the current market price moves,

every active Position continuously changes its token composition.

For a single Position:

- Liquidity to the **left** of the current price gradually becomes **Token0 (Token X)**.
- Liquidity to the **right** of the current price gradually becomes **Token1 (Token Y)**.

As the current price increases,

more of the Position is gradually converted into **Token1 (Token Y).**

As the current price decreases,

more of the Position is gradually converted into **Token0 (Token X).**

Eventually, every Position reaches one of three possible states.

| Current Price | Position Composition |
|---------------|----------------------|
| **Below Lower Range (`P < Pa`)** | **100% Token0 (Token X)** |
| **Inside Range (`Pa ≤ P ≤ Pb`)** | **Mixture of Token0 and Token1** |
| **Above Upper Range (`P > Pb`)** | **100% Token1 (Token Y)** |

So,

when the current price moves above a Position's upper range,

that Position eventually becomes:

```text
0 Token0

100% Token1
```

Likewise,

when the current price moves below its lower range,

that Position eventually becomes:

```text
100% Token0

0 Token1
```

---

## A Question That Came Up

While studying multiple Positions, an important question came up.

> **Suppose Alice's and Bob's Positions overlap, and the current price keeps increasing. Will both Positions eventually become 100% Token1?**

The answer is:

> **Yes—but each Position follows its own price range independently.**

The fact that two Positions overlap does **not** mean they transition into Token1 at the same time.

Each Position only cares about:

- Its own lower Tick (or lower price).
- Its own upper Tick (or upper price).
- The current market price.

It does **not** care about another LP's Position.

---

## Example 1 — Different Price Ranges

Suppose:

Alice chooses:

```text
0.99
 ↓
1.03
```

Bob chooses:

```text
1.01
 ↓
1.05
```

Current price:

```text
1.02
```

At this point:

- Alice is active.
- Bob is active.

Both Positions contain a **mixture of Token0 and Token1.**

---

Now the current price increases to:

```text
1.03
```

Alice reaches her upper price bound.

Her Position becomes:

```text
0 Token0

100% Token1
```

Alice is now inactive because the current price has moved outside her range.

However,

Bob is still inside his own range:

```text
1.01
 ↓
1.05
```

so his Position still contains a mixture of Token0 and Token1.

---

Now the current price continues increasing until:

```text
1.05
```

Bob also reaches his upper price bound.

His Position becomes:

```text
0 Token0

100% Token1
```

Now both Positions are entirely Token1.

Notice that they **did not** become Token1 at the same time.

Each Position transitioned according to **its own** price range.

---

## Example 2 — Same Price Range

Now suppose both LPs choose exactly the same range.

Alice:

```text
0.99
 ↓
1.01
```

Bob:

```text
0.99
 ↓
1.01
```

If the current price rises above:

```text
1.01
```

then both Positions become:

```text
0 Token0

100% Token1
```

at the same time,

because they share the exact same price range.

---

## The General Rule

Every Position evolves independently.

Each Position asks only one question:

> **"Where is the current market price relative to my own lower and upper Tick?"**

It never checks another LP's Position.

Because of this,

multiple Positions can simultaneously be in completely different states.

For example,

Alice's Position may already be:

```text
0 Token0

100% Token1
```

while Bob's Position is still:

```text
40% Token0

60% Token1
```

Likewise,

if two Positions share exactly the same range,

they will transition through these states together.

This independent behavior is one of the reasons Uniswap V3 stores every Position separately.

---

# Real-World Example — Liquidity Price Graph for the WETH/USDT Pool

This lesson introduces **no new protocol mechanics.**

Instead,

it visualizes everything we've already learned using the real **WETH/USDT** pool on the Uniswap interface.

Think of it as seeing the previous concepts come to life.

---

## Mapping the Tokens

Throughout the previous lessons, we used generic token names:

```text
Token0 (Token X)

Token1 (Token Y)
```

In the WETH/USDT pool:

```text
Token0 = WETH

Token1 = USDT
```

So whenever we previously said:

```text
Token0
```

you can now think:

```text
WETH
```

Whenever we previously said:

```text
Token1
```

you can now think:

```text
USDT
```

---

## Moving Along the Liquidity Graph

As you move from **left to right** on the graph:

- The Tick increases.
- The price increases.

Since this pool is **WETH/USDT**,

moving to the right means:

```text
1 WETH costs more USDT.
```

For example:

```text
1800 USDT

↓

2000 USDT

↓

2200 USDT
```

Moving left means the opposite.

---

## Why Does the Liquidity Graph Have This Shape?

We've already learned the answer.

The graph is **not** created by one liquidity provider.

Instead,

every LP has their own Position.

For example,

```text
Alice

1800 → 2000
```

```text
Bob

1900 → 2200
```

```text
Charlie

1950 → 2100
```

Whenever multiple Positions overlap,

their liquidity is added together.

Conceptually,

the graph is simply showing:

```text
Position A

+

Position B

+

Position C

+

Position D

↓

Total Active Liquidity
```

So the unique shape of the graph comes from stacking together all Positions that overlap each price.

---

## Understanding the Current Price

Suppose the current market price is:

```text
2000 USDT per WETH
```

At the current price,

active Positions contain a mixture of:

```text
WETH

+

USDT
```

because they are still inside their chosen price ranges.

---

## Looking to the Left of the Current Price

Everything to the **left** of the current price has already crossed that price.

Those Positions have already transitioned into:

```text
100% Token1
```

For this pool:

```text
100% USDT
```

because:

```text
Token1 = USDT
```

---

## Looking to the Right of the Current Price

Everything to the **right** of the current price has not yet reached that price.

Those Positions are still:

```text
100% Token0
```

For this pool:

```text
100% WETH
```

because:

```text
Token0 = WETH
```

---

## Child Analogy

Imagine standing in the middle of a very long road.

The road represents every possible market price.

Everything behind you has already happened.

Everything ahead of you hasn't happened yet.

For the WETH/USDT pool:

- The road **behind you** (left of the current price) contains Positions that have already become **100% USDT (Token1).**
- The road **ahead of you** (right of the current price) contains Positions that are still **100% WETH (Token0).**
- Where you're currently standing, Positions are still transitioning and therefore contain a mixture of WETH and USDT.

As the market price moves,

this transition point also moves.

The Uniswap interface is simply visualizing this behavior.

---

# Key Takeaways

- Every Position continuously changes its Token0/Token1 composition as the market price moves.
- Every Position independently transitions through three states:
  - **100% Token0**
  - **A mixture of Token0 and Token1**
  - **100% Token1**
- Overlapping Positions do **not** have to transition at the same time.
- Positions with identical price ranges transition together.
- Every Position evolves independently according to its own lower and upper Tick.
- The real WETH/USDT liquidity graph is simply a visualization of these concepts.
- In the WETH/USDT pool:
  - **Token0 = WETH**
  - **Token1 = USDT**
- To the **left** of the current price, liquidity is entirely **USDT (Token1).**
- At the **current price**, liquidity is a mixture of **WETH and USDT.**
- To the **right** of the current price, liquidity is entirely **WETH (Token0).**
- The unique shape of the liquidity graph comes from stacking together all overlapping liquidity Positions.
- This lesson serves as a real-world confirmation of the concepts introduced in the previous lessons rather than introducing new protocol mechanics.