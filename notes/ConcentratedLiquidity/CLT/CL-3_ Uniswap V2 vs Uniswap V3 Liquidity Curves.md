# Lesson — Uniswap V2 vs Uniswap V3 Liquidity Curves

Before we begin, I want to ask a question.

Imagine you own a shop.

Suppose today you have exactly:

```text
100 DAI
100 USDC
```

Someone walks in and wants to swap.

Now ask yourself:

> **What makes a trader happy?**

Is it...

- A pool with lots of liquidity?
- Or a pool with very little liquidity?

Obviously,

a pool with lots of liquidity.

But why?

---

# Think Like a Child

Imagine two candy jars.

## Jar A

Contains

```text
10 candies
```

Your little brother takes

```text
5 candies.
```

Half the jar is gone.

The jar looks completely different.

---

## Jar B

Contains

```text
10,000 candies
```

Your little brother again takes

```text
5 candies.
```

Can you even notice?

Almost impossible.

---

Exactly the same thing happens inside an AMM.

A swap is simply someone taking tokens from one side of the pool and adding tokens to the other side.

If the pool is tiny,

every swap changes the pool dramatically.

If the pool is huge,

the same swap barely changes anything.

That is why traders love high liquidity.

---

# Remember Uniswap V2

We already learned that Uniswap V2 follows the equation:

```text
x × y = k
```

Sometimes you'll also see it written as:

```text
x × y = L²
```

where:

- `x` = amount of Token X
- `y` = amount of Token Y
- `L` = Liquidity

Both describe the same constant-product idea.

The notation changes, but the underlying concept remains exactly the same.

---

# Then I Asked...

> **What exactly is a liquidity curve?**

People often think the curve is just a graph drawn in a textbook.

It isn't.

The curve is simply a picture showing **every possible state the pool can be in while still satisfying the constant-product equation.**

Suppose our pool starts with:

```text
100 DAI
100 USDC
```

After some swaps it could become:

```text
110 DAI
90.91 USDC
```

Later it could become:

```text
150 DAI
66.66 USDC
```

Later:

```text
200 DAI
50 USDC
```

Every one of these pool states lies on the same constant-product curve.

The graph is simply a visual representation of every possible reserve combination that satisfies:

```text
x × y = k
```

---

# Then I Asked Another Question

> **Why do people always say "higher liquidity is better"?**

Let's think about it.

Suppose we have two pools.

---

## Pool A

```text
100 DAI
100 USDC
```

Someone swaps:

```text
20 DAI
```

That is a huge portion of the pool.

The price changes significantly.

---

## Pool B

```text
100,000 DAI
100,000 USDC
```

Someone swaps:

```text
20 DAI
```

That swap is tiny compared to the pool.

The price barely moves.

The trader experiences very little slippage.

---

# Child Analogy — Swimming Pools

Imagine two swimming pools.

## Pool A

A tiny inflatable pool.

One person jumps inside.

💦 Water splashes everywhere.

The water level changes noticeably.

---

## Pool B

An Olympic swimming pool.

The same person jumps in.

Does the water level noticeably change?

Almost not at all.

---

The person jumping is the swap.

The water is the liquidity.

More water means the jump has much less effect.

Exactly the same idea applies to Uniswap.

This is what people really mean when they say:

> **Higher liquidity means lower price impact.**

---

# The Course Says Something Interesting

Now suppose we have:

```text
100 DAI
100 USDC
```

The current price is:

```text
P
```

Now I asked:

> **Do I really need my liquidity to work at every possible price?**

Imagine this is a DAI/USDC pool.

Where does almost all trading happen?

Usually around:

```text
0.99

↓

1.00

↓

1.01
```

Very rarely does someone trade when:

```text
1 DAI = 10 USDC
```

or

```text
1 DAI = 50 USDC
```

So another question naturally comes up.

> **If almost everyone trades near the current price, why is my liquidity spread across prices that may never be reached?**

That is exactly the question Uniswap V3 asked.

---

# Uniswap V2

Your liquidity exists everywhere.

```text
0 --------------------------------------------------------- ∞
████████████████████████████████████████████████████████████
```

Whether the price becomes:

```text
0.5

1

2

10

100
```

your liquidity is always supporting the pool.

---

# Uniswap V3

Instead, suppose you tell the protocol:

> **"I only care about prices between..."**

```text
Pa

↓

P

↓

Pb
```

For example:

```text
0.99

↓

1.00

↓

1.01
```

Now something amazing happens.

Your liquidity only exists inside that range.

Outside that range,

your liquidity simply doesn't participate.

---

# Child Analogy — Classroom

Imagine a school has:

```text
100 teachers.
```

The principal tells every teacher:

> "Stand somewhere along the entire 10 km road."

Now each street gets only a few teachers.

Most of them aren't helping anyone.

Now imagine the principal says:

> "All students enter through Gate 3."

Instead of spreading teachers across the whole city,

he places all:

```text
100 teachers
```

at Gate 3.

Did he hire more teachers?

No.

He simply placed them where they are actually needed.

That is Concentrated Liquidity.

---

# Then I Asked...

> **How can the same 100 DAI and 100 USDC suddenly feel like a much larger pool?**

This is the magic of concentration.

In V2,

those 100 tokens are responsible for supporting prices from:

```text
0 → ∞
```

In V3,

the exact same tokens only support:

```text
0.99 → 1.01
```

Since they only have one small job,

they become much more effective inside that range.

Nothing new was created.

No extra DAI appeared.

No extra USDC appeared.

The same capital is simply working much harder.

---

# The Course Mentions 254 Tokens

The instructor says:

> **If we wanted the same trading experience using Uniswap V2, we would need roughly:**

```text
254 Token X

254 Token Y
```

Does this mean Uniswap V3 magically created extra tokens?

No.

It means:

> **To achieve the same liquidity depth within that specific price range using Uniswap V2, you would need approximately 254 tokens of each asset instead of only 100.**

Uniswap V3 achieves the same result because it concentrates liquidity instead of spreading it across every possible price.

We'll derive **why the number is specifically 254** later when we study **Real Reserves** and **Virtual Reserves**.

---

# Then the Course Goes Even Further

The instructor then zooms into an even narrower price range.

Now he says:

A Uniswap V2 pool would require approximately:

```text
20,051 Token X

20,051 Token Y
```

to provide the same trading experience.

Again,

this does **not** mean V3 somehow created 20,051 tokens.

Instead, it means:

> **A Uniswap V2 pool would need about 20,051 tokens of each asset to achieve the same liquidity depth within that tiny price interval that Uniswap V3 achieves with only 100 tokens.**

The narrower the range,

the stronger the concentration.

The stronger the concentration,

the greater the capital efficiency.

---

# Then I Asked One Last Question

> **What happens if I keep making my price range wider and wider?**

Suppose I start with a very narrow range:

```text
0.999 → 1.001
```

Now I widen it.

```text
0.99 → 1.01
```

Wider again.

```text
0.90 → 1.10
```

Even wider.

```text
0.50 → 2.00
```

Finally,

I choose:

```text
0 → ∞
```

Now ask yourself:

> **Where is my liquidity?**

It is supporting every possible price.

Exactly like Uniswap V2.

So the more you widen your chosen price range,

the less concentrated your liquidity becomes.

Eventually,

your Uniswap V3 position behaves exactly like a Uniswap V2 position.

That is why the course says:

> **As the price range becomes wider, the concentrated liquidity curve gradually converges to the Uniswap V2 curve.**

---

# Important Observation

There is a trade-off.

## Very Narrow Range

```text
0.999 → 1.001
```

- Highest capital efficiency
- Lowest price impact
- Highest fee generation (while active)
- But the position goes out of range more easily.

---

## Medium Range

```text
0.99 → 1.01
```

- Good capital efficiency
- Stays active longer
- Lower fee efficiency than an extremely narrow range.

---

## Very Wide Range

```text
0 → ∞
```

- Lowest capital efficiency
- Always active
- Behaves exactly like Uniswap V2.

This is one of the biggest trade-offs in Uniswap V3.

---

# Key Takeaways

- A liquidity curve represents every possible reserve combination that satisfies the constant-product equation.
- Higher liquidity means larger swaps can occur before the price changes significantly.
- Traders prefer high-liquidity pools because they experience lower slippage.
- Uniswap V2 spreads liquidity across the entire price spectrum.
- Uniswap V3 allows LPs to concentrate liquidity inside a chosen price range.
- The same deposited capital becomes much more effective because it only supports prices where trading is expected to occur.
- The narrower the chosen price range, the greater the capital efficiency.
- As the price range becomes wider, a Uniswap V3 position gradually behaves more like a Uniswap V2 position.
- Choosing a range of `0 → ∞` effectively recreates the behavior of Uniswap V2.

---
---

# Lesson — Real Reserves vs Virtual Reserves

This is one of the most important concepts in Uniswap V3.

Everything that comes later—Liquidity Math, TickMath, SwapMath, SqrtPriceMath, and even the swap algorithm—depends on understanding these two ideas.

Before Uniswap V3, we only thought about **reserves**.

With Uniswap V3, we now have **two different types of reserves**:

- Real Reserves
- Virtual Reserves

Understanding the difference between them is the key to understanding how Concentrated Liquidity works.

---

# First Question

Suppose I tell you we have two pools.

## Pool A

```text
100 DAI
100 USDC
```

## Pool B

```text
20,051 DAI
20,051 USDC
```

Which pool has more liquidity?

Obviously,

**Pool B.**

It has far more tokens.

Nothing surprising.

---

# But Here's the Strange Part

Earlier, the instructor said something unbelievable.

He claimed that a Uniswap V3 position containing only

```text
100 DAI
100 USDC
```

can sometimes behave like a Uniswap V2 pool containing

```text
20,051 DAI
20,051 USDC.
```

At first this sounds impossible.

I immediately asked myself:

> **"Where did the extra 19,951 tokens come from?"**

Did Uniswap mint new tokens?

No.

Did someone secretly deposit more liquidity?

No.

So what is happening?

---

# Real Reserves

Real reserves are exactly what they sound like.

They are the **actual tokens** deposited by liquidity providers.

For example,

if an LP deposits

```text
100 DAI
100 USDC
```

then the real reserves are simply

```text
100 DAI
100 USDC
```

Nothing magical.

Nothing hidden.

These tokens physically exist.

They can eventually be withdrawn by the liquidity provider.

Whenever we talk about **real reserves**, we are talking about the actual assets inside the liquidity position.

---

# Virtual Reserves

Virtual reserves are completely different.

They are **not real tokens**.

Nobody deposited them.

Nobody owns them.

They cannot be withdrawn.

They are **imaginary mathematical reserves** that exist only for calculations.

Think of them as the reserves of a much larger Uniswap V2 pool that our concentrated liquidity position is pretending to be part of.

For example,

our real reserves might be

```text
100 DAI
100 USDC
```

while the protocol mathematically treats them as if they belong to a much larger pool, such as

```text
551 DAI
551 USDC
```

or even

```text
20,051 DAI
20,051 USDC
```

depending on the chosen price range.

These larger numbers are called **Virtual Reserves**.

They are never deposited.

They never exist on-chain as balances.

They only exist mathematically.

---

# Child Analogy — Magnifying Glass

Imagine placing a tiny ant under a magnifying glass.

The ant doesn't actually become larger.

It is still exactly the same size.

However,

to your eyes,

it appears much bigger.

The magnifying glass didn't create a larger ant.

It simply changed how the ant appears.

Virtual reserves work in a similar way.

They do not create more liquidity.

They make the existing liquidity behave like a much larger pool.

---

# Child Analogy — Flashlight

Imagine you own a flashlight.

The flashlight produces

```text
100 units
```

of light.

---

## Normal Mode

The light spreads across your entire room.

Everything is illuminated,

but no single area is especially bright.

---

## Focus Mode

Now imagine adjusting the flashlight so that all of the light shines on one small toy.

The flashlight still produces

```text
100 units
```

of light.

Nothing increased.

However,

the toy now appears much brighter because all of the light is concentrated into one small area.

That is exactly what Uniswap V3 does.

It does **not** create more liquidity.

It concentrates the existing liquidity.

---

# Then I Asked...

> **"If no extra liquidity is created, why does everyone say V3 behaves like a much larger pool?"**

Excellent question.

The answer is that the protocol performs its swap mathematics using **Virtual Reserves**, not just the actual deposited tokens.

From the trader's perspective,

swapping inside that concentrated price range feels almost identical to swapping against a much larger Uniswap V2 pool.

The protocol achieves this mathematically,

without creating a single extra token.

---

# Why Does Uniswap Need Virtual Reserves?

Remember Uniswap V2.

The entire protocol assumes one large constant-product curve:

```text
x × y = k
```

In Uniswap V3,

our liquidity only exists between:

```text
Pa

↓

P

↓

Pb
```

However,

the swap algorithm still wants to behave like it is moving along a normal constant-product curve.

Instead of requiring thousands of real tokens,

Uniswap mathematically extends that tiny concentrated segment into the larger curve.

Those imaginary reserves are called **Virtual Reserves**.

This allows Uniswap V3 to preserve the same AMM behavior while using far less actual capital.

---

# Movie Set Analogy

Imagine you're watching a movie.

On screen,

you see a massive castle.

When the camera zooms out,

you discover that only the front wall actually exists.

Everything behind it is empty.

The castle wasn't real.

It only appeared much larger than it actually was.

Real reserves are like the actual front wall.

Virtual reserves are like the rest of the castle.

They exist only to create the illusion needed for the scene.

---

# Important

At this point,

don't worry about:

- Where the numbers **254**, **551**, or **20,051** come from.
- How Virtual Reserves are calculated.
- The mathematical formulas.

Those will be derived in the next lesson.

Right now,

our goal is only to understand **what these two concepts represent**.

---

# Key Takeaways

## Real Reserves

- The actual deposited tokens.
- Physically exist.
- Can be withdrawn by LPs.
- Represent the real assets inside the liquidity position.

---

## Virtual Reserves

- Imaginary mathematical reserves.
- Never deposited.
- Never stored as balances.
- Cannot be withdrawn.
- Represent the larger Uniswap V2 curve that the concentrated liquidity position mathematically behaves like.

---

