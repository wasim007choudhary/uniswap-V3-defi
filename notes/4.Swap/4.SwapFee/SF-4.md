# Dissection — Uniswap V3 Swap Fee (Part 4 — Exact In: `a_in < Maximum Amount In`)

---

# 🎯 The Last Case

We now arrive at the **last and most important case** in this lesson.

This case explains why Uniswap uses the following code:

```solidity
feeAmount = amountRemaining - amountIn;
```

instead of

```text
Fee = (a_in / (1 - F)) × F
```

Let's derive **why**.

---

# Exact In — Case 2

```text
a_in < Maximum Amount In
```

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

Again,

you are swapping

```text
Token X

↓

Token Y
```

---

# This Time...

Instead of sending enough Token X to reach

```text
Pa
```

you send much less.

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

Notice

```text
40

<

100
```

---

# What Happens?

The swap begins.

```text
More X

↓

More Y Leaves

↓

Price Moves LEFT
```

But something different happens this time.

The price stops

before reaching

```text
Pa
```

Graphically

```text
$4 ------- $5.2 ------- $6 ------- $8
             ▲
        New Price
```

The liquidity is **not** completely consumed.

---

# 👶 Child Analogy — Filling Half A Glass

Imagine a glass that can hold

```text
100 mL
```

You pour

```text
40 mL
```

Question:

Did you completely fill the glass?

No.

There is still space left.

Exactly the same thing happens here.

The liquidity still has unused capacity.

---

# What Does The Pool Already Know?

Remember,

this is an **Exact In** swap.

The trader already told the pool

```text
I will send

40 X
```

So the pool already knows

the total amount the trader is willing to spend.

Inside the code,

this value is stored in

```text
amountRemaining
```

At this point,

```text
amountRemaining

=

40 X
```

---

# But Wait...

Does all

```text
40 X
```

actually perform the swap?

No.

Remember,

the swap fee must first be deducted.

Only the remaining amount is actually used for the swap.

Suppose,

after calculating the new price,

the pool discovers

```text
amountIn

=

39.88 X
```

This means

only

```text
39.88 X
```

was actually needed

to perform the swap.

---

# What's Left?

Originally,

the trader supplied

```text
40 X
```

The swap actually used

```text
39.88 X
```

Question:

What's the difference?

Easy.

```text
40

-

39.88

=

0.12 X
```

That difference

is exactly

the swap fee.

---

# Wait...

Why Is It That Simple?

Because in this situation,

the trader already decided

exactly how much

they were willing to spend.

The pool simply didn't need all of it

to perform the swap.

The unused portion naturally becomes

the fee.

Nothing needs to be reverse engineered.

---

# 👶 Child Analogy — Grocery Store

Imagine you tell the cashier

```text
I have

₹100
```

The groceries cost

```text
₹97
```

Question:

How much money remains?

```text
₹3
```

That remaining amount

can immediately become

the service fee.

You don't need

any algebra.

You simply subtract.

That is exactly what Uniswap does.

---

# Compare With Case 1

## Case 1

```text
Trader Input

↓

Exactly Enough

to Reach Pa

↓

Everything Gets Consumed

↓

Need Algebra

↓

Work Backwards
```

---

## Case 2

```text
Trader Input

↓

Price Stops Early

↓

Pool Already Knows

How Much Was Actually Used

↓

Subtract

↓

Fee
```

Notice the difference.

---

# Why Doesn't The Pool Use The Percentage Formula Again?

It certainly could.

Mathematically,

both methods produce

almost the same result.

However,

one method is much cheaper.

Instead of performing

```text
Divide

↓

Multiply

↓

Round
```

the pool simply performs

```text
Subtract
```

One subtraction.

Done.

That is cheaper,

simpler,

and consumes less gas.

---

# This Is Exactly The Solidity Code

Now the Solidity suddenly becomes obvious.

```solidity
feeAmount = amountRemaining - amountIn;
```

Read it like English.

```text
Fee

=

Original Trader Input

-

Amount Actually Used
```

That's all.

Nothing more.

---

# Why Is This Only Used Here?

Because only in this situation

the swap finishes

before reaching

the target price.

Since the pool already knows

both values

```text
amountRemaining

and

amountIn
```

the fee is simply

their difference.

If the swap reaches

```text
Pa
```

instead,

the pool must use

the mathematical derivation

to calculate the fee.


---

# 💡 Why Doesn't Exact Out Have This Optimization?

While studying the previous section, I had an interesting question.

> **If Exact In can calculate the fee using**
>
> ```text
> fee = amountRemaining - amountIn
> ```
>
> **then why doesn't Exact Out do the same thing?**

At first, it seems like both situations should be identical.

However,

there is one subtle difference.

That difference is exactly why the lesson separates these cases.

Let's compare them.

---

# Exact Out

The user says

```text
I want

50 Y
```

Notice something.

The user never specifies

how much Token X

they are willing to spend.

Instead,

they only specify

the desired output.

So the pool must first calculate

```text
a_in
```

Then,

it works backwards.

```text
a_in

↓

A

↓

Fee
```

Why?

Because the pool does **not** know

the trader's original input amount.

It must discover it.

---

# Exact In — Case 1

Now consider

Exact In.

The user says

```text
I will spend

100 X
```

Suppose,

after removing the fee,

the remaining input is **exactly** enough to reach

```text
Pa
```

Again,

the pool ends up knowing

```text
a_in
```

Then it works backwards.

```text
a_in

↓

A

↓

Fee
```

So yes...

This situation is mathematically identical to Exact Out.

That is exactly why Uniswap uses

the same fee formula.

---

# Exact In — Case 2

Now everything changes.

Suppose the trader says

```text
I will spend

100 X
```

But after calculating the swap,

the pool discovers that only

```text
97 X
```

was actually needed.

Now the pool already knows

```text
amountRemaining = 100
```

and

```text
amountIn = 97
```

Question:

Why solve

```text
A = a_in / (1 - F)
```

again?

There is no need.

The pool already has

both numbers.

Simply subtract.

```text
Fee

=

100

-

97

=

3
```

Done.

---

# So What Is The Real Difference?

The difference is **not**

```text
Exact In

vs

Exact Out
```

The real difference is

```text
Did we consume

the ENTIRE liquidity step?
```

Everything revolves around that question.

---

## If The Answer Is YES

```text
YES
```

then

the current liquidity has been completely consumed.

The price reached

```text
Pa
```

There is no leftover trader input sitting around.

Therefore,

the pool must work backwards.

```text
Fee

=

(a_in / (1 - F))

×

F
```

This happens in

- Exact Out
- Exact In (Case 1)

---

## If The Answer Is NO

```text
NO
```

then

the price stopped

before reaching

```text
Pa
```

Some of the trader's original input

was never needed.

That unused portion naturally becomes

the fee.

```text
Fee

=

amountRemaining

-

amountIn
```

This happens only in

Exact In (Case 2).

---

# That's Exactly Why The Solidity Says

```solidity
if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96)
```

Notice what the code is checking.

It is **NOT** checking

```text
Exact Out?
```

Instead,

it checks two conditions together.

```text
Exact In

AND

Didn't Reach Target Price?
```

Only then

does it use

simple subtraction.

Otherwise,

it uses

the percentage formula.

---

# 👶 Child Analogy

## Exact In

Imagine you walk into a shop

and immediately hand the cashier

```text
₹100
```

The items only cost

```text
₹97
```

The cashier already has

your original payment.

So finding the fee is easy.

```text
100

-

97

=

3
```

No extra calculations are needed.

---

## Exact Out

Now imagine

you walk into the same shop

and simply say

```text
I want exactly

5 chocolates.
```

You haven't handed over

any money yet.

The cashier first needs to calculate

```text
How much money

should you pay?
```

Only after figuring that out

can the fee be calculated.

There is no "leftover money"

to subtract,

because you never handed over

any money in the first place.

---

# Even Simpler Mental Model

There are really only

**two mathematical situations.**

---

## Situation A — Price Reaches The Target Tick

Examples

```text
Exact Out ✅

Exact In (Case 1) ✅
```

Both use

```text
Fee

=

(a_in / (1 - F))

×

F
```

because the liquidity was completely consumed.

---

## Situation B — Price Stops Before The Target Tick

Example

```text
Exact In (Case 2)
```

Uses

```text
Fee

=

amountRemaining

-

amountIn
```

because the unused input is already sitting there waiting.

It naturally becomes

the fee.

---

# Final Mental Model

At first,

it looks like

Uniswap has

two completely different

fee systems.

It doesn't.

Both branches calculate

the exact same fee.

The only difference is

**what information is already available.**

If the liquidity is

**completely consumed**,

the pool only knows

```text
a_in
```

so it must work backwards.

If the liquidity is

**not completely consumed**,

the pool already knows

both

```text
amountRemaining
```

and

```text
amountIn
```

so a simple subtraction is enough.

That is why

`computeSwapStep()`

contains two different code paths.

It is **not** using two different fee systems.

It is simply choosing

the cheapest and most efficient way

to compute the exact same fee.

---

---

# 🧠 Entire Swap Fee Decision Flow

After understanding all three scenarios, the fee calculation inside `computeSwapStep()` becomes very straightforward.

```text
Swap Starts

↓

Exact Out?
│
├── Yes
│     ↓
│  Calculate amountIn
│     ↓
│  Work backwards
│     ↓
│  Percentage Formula
│
└── No (Exact In)
      ↓
      Did we reach the target tick?
      │
      ├── Yes
      │      ↓
      │   Liquidity Fully Consumed
      │      ↓
      │   Work backwards
      │      ↓
      │   Percentage Formula
      │
      └── No
             ↓
      Liquidity NOT Fully Consumed
             ↓
      Original Input Already Known
             ↓
      Actual Input Used Already Known
             ↓
      Fee = amountRemaining - amountIn
```

---

# 🎯 Final Takeaway

Notice something interesting.

The decision is **not** really based on whether the swap is **Exact In** or **Exact Out**.

Instead, it is based on **what information the pool already knows**.

If the current liquidity is **completely consumed**, the pool must work backwards using the fee percentage.

```text
Fee

=

(a_in / (1 - F))

×

F
```

This happens in:

- Exact Out
- Exact In (when the target price is reached)

However, if the current liquidity is **not completely consumed**, the pool already knows:

- the trader's original input (`amountRemaining`)
- the amount actually used for the swap (`amountIn`)

Therefore, the fee is simply the leftover amount.

```text
Fee

=

amountRemaining

-

amountIn
```

This situation only occurs in **Exact In** when the swap stops **before** reaching the target price.

So, `computeSwapStep()` is **not using two different fee systems**.

It is simply choosing the **most efficient way** to calculate the **exact same fee**, depending on which values are already available.