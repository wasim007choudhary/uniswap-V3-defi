# Dissection — Uniswap V3 Swap Fee (Part 3 — Exact In: `a_in = Maximum Amount In`)

---

# 🎯 Where Are We?

So far, we have studied:

- What `A` is.
- What `a_in` is.
- How swap fees are calculated.
- The difference between **Exact In** and **Exact Out**.
- What **Maximum Amount In** and **Maximum Amount Out** mean.

Now the lesson moves to **Exact In**.

However, it immediately introduces something that confuses almost everyone.

> **For Exact In, there are TWO cases.**

```text
1. a_in = Maximum Amount In

2. a_in < Maximum Amount In
```

Before looking at the fee formulas, let's first understand **why these two cases even exist.**

---

# Imagine The Same Liquidity

```text
Price Range

$4 ----------------------------- $8

Liquidity = L
```

Current price

```text
$6
```

```text
$4 ----------- $6 ----------- $8
                ▲
          Current Price
```

You are swapping

```text
Token X

↓

Token Y
```

As you already know,

adding Token X causes the price to move **LEFT**.

---

# This Time You Use Exact In

Now you tell the pool

```text
I will send

100 X
```

Notice the difference.

Unlike **Exact Out**,

the input amount is already fixed.

The pool's job is now to answer

```text
How much Token Y

should I give back?
```

---

# The Pool's First Question

Before doing anything else,

the pool asks

> **Can all of this input fit inside the current liquidity range?**

This is the key question.

---

# 👶 Child Analogy — Filling A Bottle

Imagine you have a bottle.

```text
Bottle Capacity

10 Liters
```

You arrive carrying

```text
4 Liters
```

Question:

Can the bottle hold all

```text
4 Liters?
```

Yes.

No problem.

---

Now imagine you arrive carrying

```text
20 Liters
```

Can the bottle hold everything?

No.

Eventually,

the bottle becomes full.

The remaining water must go

into another bottle.

Exactly the same thing happens in Uniswap.

---

# What Is Maximum Amount In?

Earlier,

for Exact Out,

we learned about

```text
Maximum Amount Out
```

Now,

for Exact In,

we learn about

```text
Maximum Amount In
```

What does it mean?

It simply means

> **The maximum amount of Token X that can enter this liquidity before the current price reaches `Pa`.**

Nothing more.

---

# Why Is There A Maximum?

Imagine continuously adding Token X.

```text
More X

↓

Price Moves LEFT

↓

More X

↓

Price Moves LEFT

↓

More X

↓

Eventually

Price = Pa
```

At this point,

all of the liquidity has become

```text
Token X
```

This liquidity cannot accept

any more Token X.

It is finished.

Therefore,

there is a limit.

That limit is called

```text
Maximum Amount In
```

---

# Two Possible Situations

The pool now compares

```text
Trader's Input
```

against

```text
Maximum Amount In
```

Only two outcomes are possible.

---

## Situation 1 — Trader Sends LESS Than The Maximum

Example

```text
Maximum Amount In

=

100 X
```

Trader sends

```text
40 X
```

Question:

Can the current liquidity absorb everything?

Yes.

The swap finishes

inside this liquidity.

The price moves LEFT,

but

never reaches

```text
Pa
```

Graphically

```text
$4 -------- $5.4 -------- $6 -------- $8
             ▲
        New Price
```

No initialized tick is crossed.

The liquidity is **not** completely consumed.

---

## Situation 2 — Trader Sends EXACTLY The Maximum

Example

```text
Maximum Amount In

=

100 X
```

Trader sends

```text
100 X
```

Now,

the price moves

all the way

to

```text
Pa
```

Graphically

```text
$4 ----------- $6 ----------- $8
▲
New Price
```

The liquidity has been completely consumed.

Every possible Token Y has left.

Every possible Token X has entered.

The swap ends

exactly at the initialized tick.

This is the first Exact In case that the lesson analyzes.

---

# Wait...

What If The Trader Sends MORE Than The Maximum?

Example

```text
Maximum Amount In

=

100 X
```

Trader sends

```text
150 X
```

Does the lesson discuss this?

Not yet.

Why?

Because

`computeSwapStep()`

only computes

**one liquidity step at a time.**

Inside one step,

the pool can consume

at most

```text
100 X
```

Then

the price reaches

```text
Pa
```

the pool crosses the initialized tick,

activates the next liquidity,

and another call to

```text
computeSwapStep()
```

handles the remaining

```text
50 X
```

So every call to

```text
computeSwapStep()
```

only sees one of these two situations:

```text
a_in < Maximum Amount In
```

or

```text
a_in = Maximum Amount In
```

It never needs to handle

```text
a_in > Maximum Amount In
```

because the extra input is processed by the **next iteration** of the swap loop.

---

# Why Does The Lesson Separate These Two Cases?

Because

the fee calculation

is different.

If

```text
a_in = Maximum Amount In
```

the current liquidity

is completely consumed,

the price reaches

```text
Pa
```

and the fee is calculated one way.

If

```text
a_in < Maximum Amount In
```

the price never reaches

```text
Pa
```

the swap finishes early,

and the fee is calculated differently.

Now let's study the first case.

---

# Exact In — Case 1

```text
a_in = Maximum Amount In
```

---

# Imagine The Same Liquidity Again

```text
Price Range

$4 ----------------------------- $8

Liquidity = L
```

Current price

```text
$6
```

```text
$4 ----------- $6 ----------- $8
                ▲
          Current Price
```

The trader says

```text
I will send

100 X
```

Suppose

```text
100 X
```

is **exactly** the amount required to move the current price from

```text
Current Price

↓

Pa
```

No more.

No less.

---

# What Happens?

As Token X enters,

Token Y leaves.

```text
More X

↓

Less Y

↓

Price Moves LEFT
```

Eventually,

the price reaches

```text
Pa
```

exactly.

```text
$4 ----------- $6 ----------- $8
▲
Price Stops Here
```

---

# What Does This Mean?

It means

this liquidity has been completely consumed.

Everything that could happen inside this liquidity has already happened.

Every possible

```text
Token Y
```

has left.

Every possible

```text
Token X
```

has entered.

There is nothing more this liquidity can do.

---

# 👶 Child Analogy — Filling A Glass

Imagine a glass.

```text
Capacity

100 mL
```

Now pour

```text
100 mL
```

Question:

Did you fill it completely?

Yes.

Not

```text
99 mL
```

Not

```text
101 mL
```

Exactly

```text
100 mL
```

That is exactly what happens here.

The liquidity has been consumed **perfectly** to its limit.

---

# What Does The Pool Already Know?

The pool has already calculated

```text
Maximum Amount In
```

And now

```text
a_in

=

Maximum Amount In
```

Therefore,

the pool already knows

how much Token X

was actually used

for the swap.

---

# What Is Still Unknown?

Only one thing remains.

```text
Fee
```

Remember,

```text
a_in
```

already excludes

the fee.

So the pool simply works backwards,

exactly like it did in **Exact Out**.

---

# The Same Derivation

Earlier,

we proved

```text
a_in = A(1 - F)
```

Solve for

```text
A
```

```text
A

=

a_in

/

(1 - F)
```

Then,

using

```text
Fee = A × F
```

substitute

```text
A
```

Result

```text
Fee

=

(a_in / (1 - F))

×

F
```

Exactly

the same equation.

---

# Wait...

Why Is It Exactly The Same?

Because

the mathematics hasn't changed.

Whether you're performing

an **Exact Out** swap

or

an **Exact In** swap,

if

the swap reaches

the target price,

the pool already knows

```text
a_in
```

It simply works backwards

to recover

```text
A
```

and then calculates the fee.

Nothing new happened.

---

# 👶 Child Analogy

Suppose,

after tax,

a restaurant receives

```text
₹950
```

Whether

you ordered

pizza,

a burger,

or pasta

doesn't matter.

If the restaurant received

```text
₹950
```

you can always calculate

how much the customer originally paid.

Exactly the same mathematics is happening here.

---

# So Why Does The Lesson Need Another Case?

Because everything we've discussed so far assumes

```text
Price reaches Pa
```

But what if

the trader sends

LESS

than required?

Example

```text
Maximum Amount In

=

100 X
```

Trader sends

```text
40 X
```

Now,

the price stops

somewhere

inside

the liquidity.

```text
$4 ------- $5.2 ------- $6 ------- $8
             ▲
        New Price
```

Notice

the price never reaches

```text
Pa
```

Now something interesting happens.

The pool no longer needs

to reverse engineer

anything.

Instead,

it already knows

everything it needs.

This leads to the much simpler fee calculation used inside

```solidity
feeAmount = amountRemaining - amountIn;
```

We'll derive exactly **why** this works in the next section.

---

# Mental Picture

## Case 1

```text
Trader Input

↓

Enough To Reach

Pa

↓

Liquidity Completely Consumed

↓

Use

Fee = (a_in / (1 - F)) × F
```

---

## Case 2

```text
Trader Input

↓

NOT Enough To Reach

Pa

↓

Price Stops Early

↓

Different Fee Calculation
```

This second case is the reason the Solidity implementation contains an `if` statement instead of always using the percentage-based fee formula.

---

# 📝 Key Takeaways

- Exact In has **two possible scenarios**:
  - `a_in = Maximum Amount In`
  - `a_in < Maximum Amount In`
- `computeSwapStep()` processes **only one liquidity range at a time**, so it never encounters `a_in > Maximum Amount In`.
- When `a_in = Maximum Amount In`, the liquidity is completely consumed and the price reaches `Pa`.
- In this case, the fee is calculated exactly like Exact Out:

```text
Fee

=

(a_in / (1 - F))

×

F
```

- When `a_in < Maximum Amount In`, the price stops before reaching `Pa`, and Uniswap uses a different, more efficient fee calculation. That is the final case we'll study next.