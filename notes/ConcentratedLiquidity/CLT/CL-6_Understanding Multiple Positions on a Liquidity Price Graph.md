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

more of the Position is gradually converted into **Token1 (Token Y)**.

As the current price decreases,

more of the Position is gradually converted into **Token0 (Token X)**.

When the current price moves above a Position's upper price range,

that Position eventually becomes:

```text
0 Token0

100% Token1
```

When the current price moves below a Position's lower price range,

that Position eventually becomes:

```text
100% Token0

0 Token1
```

---

# Additional Discussion — Do Overlapping Positions Become 100% Token1 Together?

While studying multiple Positions, an important question came up.

> **Suppose Alice's and Bob's Positions overlap, and the current price keeps increasing. Will both Positions eventually become 0 Token0 and 100% Token1?**

The answer is:

> **Yes—but each Position follows its own price range independently.**

The fact that two Positions overlap does **not** mean they transform into Token1 at the same time.

Each Position only cares about:

- Its own lower price (or Tick).
- Its own upper price (or Tick).
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

Alice has reached her upper price bound.

Alice's Position becomes:

```text
0 Token0

100% Token1
```

Alice is now inactive because the current price has moved outside her range.

However,

Bob's Position is still inside its own range:

```text
1.01
 ↓
1.05
```

So Bob's Position still contains a mixture of Token0 and Token1.

---

Now suppose the current price keeps increasing until:

```text
1.05
```

Bob has now reached his upper price bound.

His Position becomes:

```text
0 Token0

100% Token1
```

Now both Positions are entirely Token1.

Notice that they **did not** become Token1 at the same time.

Each Position changed according to **its own** upper price bound.

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

# General Rule

Every Position behaves independently.

For every Position:

- **Price below its lower range (`P < Pa`) → 100% Token0**
- **Price inside its range (`Pa ≤ P ≤ Pb`) → A mixture of Token0 and Token1**
- **Price above its upper range (`P > Pb`) → 100% Token1**

Overlapping Positions do **not** change this rule.

Each Position only asks one question:

> **"Where is the current market price relative to my own lower and upper price?"**

Not anyone else's.

Because of this,

multiple Positions can be in completely different states at the same time.

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

This happens because Alice has already crossed her upper price bound, while Bob is still inside his own range.

Likewise, if two Positions have exactly the same range, they will transition through these states together.

This is one of the reasons Uniswap V3 stores every Position separately.

Each Position evolves independently as the current market price moves.

---

# Key Takeaways

- A Uniswap V3 pool is made up of many independent liquidity Positions.
- Every LP chooses their own lower and upper Tick (price range).
- During a swap, every active Position contributes liquidity simultaneously.
- The pool behaves like one large liquidity pool during swaps, while each Position remains independently owned.
- Active liquidity is simply the sum of all Positions whose ranges include the current market price.
- Fees are distributed proportionally according to each Position's liquidity.
- Liquidity (`L`) is stored by the protocol.
- Current token balances are **not** stored; they are calculated from:
  - Liquidity (`L`)
  - Current Price (`P`)
  - Lower Price (`Pa`)
  - Upper Price (`Pb`)
- This design greatly reduces gas costs because token balances do not need to be updated after every swap.
- Every Position continuously changes its Token0/Token1 composition as the market price moves.
- Each Position evolves **independently** according to its own price range.
- Two overlapping Positions may be in completely different token compositions if their price ranges are different.
- Two Positions with identical price ranges will transition between Token0 and Token1 together.