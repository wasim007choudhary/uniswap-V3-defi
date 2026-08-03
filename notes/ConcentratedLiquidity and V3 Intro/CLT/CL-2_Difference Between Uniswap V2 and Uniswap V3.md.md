# Difference Between Uniswap V2 and Uniswap V3

## Part 1 — The Biggest Architectural Difference

Before looking at any formulas, I noticed one sentence in the course that is far more important than everything else.

The course says:

> **Uniswap V2 tracks reserves.**

> **Uniswap V3 tracks liquidity and price.**

At first glance, this doesn't seem like a huge difference.

However, this single sentence is actually the foundation of the entire Uniswap V3 protocol.

So instead of moving on, we stopped to understand **why this change was made**.

---

# First, What Did Uniswap V2 Store?

Let's think back to the Pair contract that we completely dissected in Uniswap V2.

The Pair contract stored something like:

```solidity
uint112 reserve0;
uint112 reserve1;
```

Suppose the pool contains:

```text
DAI  = 100

USDC = 100
```

The Pair contract literally stores:

```text
reserve0 = 100

reserve1 = 100
```

Nothing more.

---

# Then What Happens?

Suppose someone asks:

> **"What is the current price?"**

The protocol calculates it using the reserves.

```text
Price = reserve1 / reserve0

      = 100 / 100

      = 1
```

Now suppose someone asks:

> **"What is the liquidity?"**

Again, the protocol calculates it.

```text
Liquidity = √(reserve0 × reserve1)

          = √(100 × 100)

          = 100
```

Notice the flow.

```text
Stored

↓

Reserves

↓

Calculate

Price

Liquidity
```

So in Uniswap V2,

the primary state is:

```text
Reserves
```

Everything else is derived from those reserves.

---

# Child Analogy

Imagine a classroom.

The teacher writes on the board:

```text
Boys  = 20

Girls = 30
```

That's all.

Now a student asks:

> **"How many students are there?"**

The teacher calculates:

```text
20 + 30 = 50
```

Another student asks:

> **"What percentage are girls?"**

Again,

the teacher calculates it.

Notice something.

The teacher never stored:

```text
Total Students

Girl Percentage
```

The teacher only stored:

```text
Boys

Girls
```

Everything else is calculated whenever someone asks.

That is exactly how Uniswap V2 works.

---

# Now Let's Look at Uniswap V3

This is where everything changes.

Instead of storing:

```text
reserve0

reserve1
```

Uniswap V3 primarily stores:

```text
Liquidity (L)

Current Price (P)
```

Then,

using those two values,

the protocol calculates:

```text
reserve0

reserve1
```

for the current active price range.

Notice what happened.

Everything has flipped.

---

# Uniswap V2

```text
Stores

reserve0

reserve1

↓

Calculates

Price

Liquidity
```

---

# Uniswap V3

```text
Stores

Liquidity

Current Price

↓

Calculates

reserve0

reserve1
```

This is the biggest architectural shift between Uniswap V2 and Uniswap V3.

---

# At This Point I Asked...

> **"Why would they redesign the entire protocol? Reserves worked perfectly in V2."**

That's an excellent question.

To answer it,

we need to remember what we learned in the previous lesson about **Concentrated Liquidity**.

---

# Think Back to Concentrated Liquidity

Suppose I provide liquidity only between:

```text
0.99

↓

1.01
```

Now imagine the market price moves to:

```text
5.00
```

Then I asked myself:

> **"What are my reserves now?"**

Can we answer that with one simple number?

No.

Because my token composition changes continuously as the price moves.

For example:

At price:

```text
1.00
```

my position might look like:

```text
100 DAI

100 USDC
```

Move the price slightly higher.

At:

```text
1.005
```

it might become:

```text
90 DAI

110 USDC
```

Move all the way to the upper boundary.

At:

```text
1.01
```

it could become:

```text
0 DAI

200 USDC
```

Notice something.

The reserves are no longer fixed.

They continuously change as the current price moves.

---

# In Uniswap V2

Life was simple.

There was only one pool.

```text
DAI
██████████████

USDC
██████████████
```

The reserves represented the entire pool.

Easy.

---

# In Uniswap V3

Every liquidity provider chooses a different price range.

Imagine three liquidity providers.

LP1

```text
0.90 ------------------ 1.10
████████████████████████
```

LP2

```text
1.00 ----------- 1.20
      █████████████████
```

LP3

```text
1.05 -------- 1.30
           ████████████
```

Now I asked:

> **"What are the pool's reserves?"**

It is no longer obvious.

Why?

Because different liquidity providers become active and inactive depending on the current price.

The active reserves change every time the price moves into a different range.

---

# Child Analogy

Imagine three water tanks connected to the same pipe.

```text
Tank A

████████

Works only from

0.90 → 1.10


Tank B

████████

Works only from

1.00 → 1.20


Tank C

████████

Works only from

1.05 → 1.30
```

Now suppose the current price is:

```text
0.95
```

Only Tank A is connected.

Move to:

```text
1.07
```

Now:

- Tank A
- Tank B
- Tank C

are all connected.

Move again to:

```text
1.25
```

Tank A disconnects.

Tank B disconnects.

Only Tank C remains.

The available liquidity changes automatically as the price moves.

At this point,

asking:

> **"How many reserves does the pool have?"**

is no longer the best question.

A much better question is:

> **"How much liquidity is currently active?"**

---

# This Is Why V3 Stores Liquidity

Liquidity is the thing that actually matters.

Once the protocol knows:

```text
Current Price

+

Active Liquidity
```

it can derive:

```text
Token0 Reserves

Token1 Reserves
```

for that specific price.

Trying to store reserves directly would become much more complicated because the reserves continuously change as liquidity positions become active and inactive.

---

# Google Maps Analogy

Think of Google Maps.

Uniswap V2 is like asking:

> **"Where is every car in the entire country?"**

It stores everything first,

then estimates the traffic.

Uniswap V3 asks a different question.

> **"How many lanes are open right here, right now?"**

Those open lanes represent **Active Liquidity**.

Once you know:

- the current location (Current Price), and
- the number of open lanes (Active Liquidity),

you can determine how much traffic can actually pass through.

The protocol doesn't need to remember where every car is.

---

# Key Takeaways

- Uniswap V2 stores **Reserves** and derives **Price** and **Liquidity**.
- Uniswap V3 stores **Current Price** and **Liquidity**, then derives the active reserves.
- In Uniswap V3, reserves are no longer fixed because liquidity providers can choose different price ranges.
- As the price moves, liquidity positions continuously become active and inactive.
- Active Liquidity becomes the central concept instead of Reserves.
- This architectural change is the foundation for everything else in Uniswap V3, including ticks, liquidity math, fee accounting, and swap execution.

---

---

---

# Additional Discussion — Why ERC20 Became ERC721 and Why V3 Doesn't Simply Store Reserves

During our discussion, two very important questions came up.

Instead of moving forward immediately, we stopped to answer them because they explain **why Uniswap V3 was redesigned** the way it was.

---

# Question 1

At this point, I asked:

> **"Is the change from ERC20 LP tokens to ERC721 NFTs related to this new architecture?"**

The answer is:

> **Yes, indirectly.**

Let's connect everything we've learned so far.

---

# Uniswap V2

The Pair contract stores:

```text
reserve0
reserve1
```

Every liquidity provider simply owns a percentage of those same reserves.

For example:

```text
Pool

100 ETH
100,000 USDC
```

Suppose:

Alice owns:

```text
10%
```

Bob owns:

```text
20%
```

Charlie owns:

```text
5%
```

Everyone owns a proportional slice of the exact same pool.

Alice's 10% is interchangeable with anyone else's 10%.

It is just like owning shares of a company.

Because every LP owns the same type of asset,

an **ERC20 token** is the perfect representation.

---

# Uniswap V3

Now everything changes.

Suppose:

Alice provides liquidity between

```text
0.99 → 1.01
```

Bob provides liquidity between

```text
0.80 → 1.20
```

Charlie provides liquidity between

```text
1.10 → 1.50
```

Now ask yourself:

> **Are these three positions identical?**

No.

Each position behaves differently.

For example:

- Alice only earns fees between `0.99 → 1.01`.
- Bob earns fees across a much wider range.
- Charlie doesn't even become active until the price reaches `1.10`.

Every position has its own:

- Liquidity
- Price range
- Fee earnings
- Time spent active

No two positions are exactly the same.

Because of that,

they can no longer be represented by one interchangeable ERC20 token.

Each liquidity position is unique.

That is why Uniswap V3 represents liquidity positions as **ERC721 NFTs**.

---

# Conclusion

So yes,

the shift from storing **Reserves** to storing **Liquidity + Current Price** is one of the reasons why an ERC20 token no longer makes sense.

Every LP position is now unique.

---

# Question 2

Then another question came up.

I asked:

> **"Instead of storing Liquidity and Price, why don't we simply keep updating the reserves every time the price changes?"**

At first,

this sounds like a perfectly reasonable idea.

You might think:

> **"Whenever the price moves, just recalculate `reserve0` and `reserve1` and store them again."**

Wouldn't that make V3 behave just like V2?

The answer is:

> **No.**

Let's understand why.

---

# Example

Imagine there are three liquidity providers.

Alice

```text
0.90 → 1.10
```

Bob

```text
1.00 → 1.20
```

Charlie

```text
1.10 → 1.30
```

Suppose the current price is

```text
1.05
```

Who is active?

```text
Alice   ✅

Bob     ✅

Charlie ❌
```

Now suppose the price moves to

```text
1.15
```

Who is active now?

```text
Alice   ❌

Bob     ✅

Charlie ✅
```

Notice something.

The thing that changed wasn't just the reserves.

The **set of active liquidity providers also changed.**

---

# Now Imagine 50,000 Liquidity Providers

Instead of just three LPs,

imagine the protocol has thousands of LPs.

```text
LP1

0.90 → 1.05

LP2

0.95 → 1.20

LP3

1.01 → 1.08

LP4

1.15 → 1.60

...
```

Now imagine the price moves from

```text
1.0499

↓

1.0501
```

Even such a tiny movement could cause:

- Some LPs to become inactive.
- Some LPs to become active.
- Liquidity to change.
- Fee accounting to change.
- Token composition to change.

The protocol would potentially need to check thousands of positions every time the price moved.

---

# Child Analogy

Imagine a highway.

Each liquidity provider opens a toll booth for only a specific stretch of the road.

```text
Road

0 ----1----2----3----4----5----6
```

LP A

```text
1 → 3
```

LP B

```text
2 → 5
```

LP C

```text
4 → 6
```

Now imagine your car is moving.

At position

```text
2.5
```

The active toll booths are:

```text
LP A

LP B
```

Move a little further.

At

```text
3.5
```

LP A closes.

Only LP B remains.

Move again.

At

```text
4.5
```

LP C opens.

Now LP B and LP C are active.

Notice what happened.

Every small movement changed which toll booths were open.

Imagine trying to rewrite the entire highway map every single centimeter your car moved.

That would be extremely inefficient.

---

# So What Does Uniswap V3 Store Instead?

Instead of constantly storing reserves,

Uniswap V3 stores:

```text
Current Price

+

Active Liquidity
```

From those two values,

the protocol can derive:

```text
Token0 Reserves

Token1 Reserves
```

for the current active price range.

---

# There Is an Even Bigger Reason

Suppose we still wanted to store reserves.

Then another question appears.

> **"Whose reserves should we store?"**

Alice's?

Bob's?

Charlie's?

Or the combined reserves?

There is no single correct answer.

Each liquidity provider has:

- Different real reserves.
- Different virtual reserves.
- Different active price ranges.

The pool is no longer one giant bucket like it was in Uniswap V2.

Instead,

it behaves more like **thousands of overlapping mini-AMMs**.

---

# Visualizing the Difference

## Uniswap V2

There is only one pool.

```text
        +----------------------+
        |     One Big Pool     |
        |                      |
        | 100 ETH              |
        | 100,000 USDC         |
        +----------------------+
```

Everything is stored inside one shared pool.

Keeping global reserves is simple.

---

## Uniswap V3

There are many overlapping liquidity positions.

```text
          Bucket A
             \
              \
Bucket B ------ Current Price
              /
             /
          Bucket C
```

Only some of these liquidity positions are active at any given moment.

Trying to maintain one global reserve value becomes much less useful than maintaining:

```text
Current Price

+

Current Active Liquidity
```

Those two values are enough to determine the active reserves at the current price.

---

# Looking Ahead

This discussion also explains why Uniswap V3 introduces **Ticks**.

Ticks allow the protocol to efficiently determine:

- Which liquidity positions become active.
- Which liquidity positions become inactive.

as the price moves,

without scanning every liquidity provider on every swap.

We'll study ticks in detail later.

---

# Key Takeaways

- In Uniswap V2, every LP owns a proportional share of one common pool, so ERC20 tokens are sufficient.
- In Uniswap V3, every LP position is unique because each one has its own liquidity amount, price range, fee earnings, and active duration.
- This uniqueness is why V3 represents liquidity positions as ERC721 NFTs.
- Updating reserves every time the price changes would not solve the problem because the active set of liquidity providers changes continuously.
- The protocol therefore stores **Current Price** and **Active Liquidity**, from which the active reserves can be derived.
- Uniswap V3 should be thought of as thousands of overlapping mini-AMMs rather than one giant liquidity pool.
- This architectural decision is also the reason why the protocol introduces **Ticks**, which efficiently track changes in active liquidity as the price moves.