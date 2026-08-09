# Dissection — Uniswap V3 Swap Fee (Part 1)

---

# 🎯 What Is This Lesson Trying To Teach?

In previous lessons, we learned how Uniswap V3 calculates:

- The next price
- The amount of token X coming in
- The amount of token Y going out

Now a new question appears.

> **How does Uniswap charge the swap fee?**

At first glance, the code inside `SwapMath.computeSwapStep()` can look confusing because there are multiple variables related to the input amount.

This lesson is all about understanding **what those variables mean and how the swap fee is calculated.**

---

# Forget Every Formula

Pretend these don't exist.

```text
fee = ...

amountIn = ...

amountOut = ...
```

Forget them.

Let's think exactly like Uniswap.

---

# Imagine This

There is only **one LP**.

```text
Price Range

$4 ----------------------------- $8

Liquidity = L
```

Current price is somewhere inside the range.

```text
$4 ----------- $6 ----------- $8
                ▲
          Current Price
```

Now a trader arrives.

---

# You Are The Trader

You tell the pool

```text
I want to swap Token X.
```

Then you send

```text
100 X
```

Question:

> **Does the pool immediately use all 100 X for the swap?**

No.

---

# 👶 Child Analogy — Buying A Chocolate

Suppose a chocolate costs

```text
₹95
```

You give the shopkeeper

```text
₹100
```

Does the shopkeeper immediately use all ₹100 to buy the chocolate?

No.

First,

he removes

```text
₹5
```

as tax.

Only

```text
₹95
```

is actually used to buy the chocolate.

Uniswap behaves the same way.

---

# How Uniswap Thinks

You send

```text
100 X
```

The pool says

> "Wait..."

> "Before I perform the swap, I first collect my fee."

Only after collecting the fee does the pool perform the swap.

So the flow is

```text
Trader Sends

100 X

↓

Pool Collects Fee

↓

Remaining Tokens

↓

Swap Happens
```

Notice something important.

There are actually **two different "amount in" values.**

This is the main idea of this lesson.

---

# Two Different Input Amounts

The lesson introduces two variables.

```text
A
```

and

```text
a_in
```

These names look confusing at first,

but they are actually describing two different moments in time.

---

# What Is Capital A?

Capital

```text
A
```

represents

> **The amount of tokens the trader originally sends before any fee is deducted.**

Example

```text
Trader sends

100 X
```

Therefore

```text
A = 100
```

Nothing has happened yet.

No fee has been collected.

No swap has been performed.

This is simply the trader's original input.

---

# What Is `a_in`?

Now the pool collects its fee.

Suppose the fee is

```text
3 X
```

Now the amount that is actually used for swapping becomes

```text
97 X
```

The lesson calls this

```text
a_in
```

So

```text
Trader Sends

100 X

↓

Pool Takes Fee

3 X

↓

Actually Used For Swap

97 X
```

Therefore

```text
A = 100
```

while

```text
a_in = 97
```

---

# ⭐ The Biggest Idea Of This Lesson

Many beginners think the swap looks like this.

```text
Trader sends

100

↓

Pool swaps

100
```

That is **not** what happens.

The real process is

```text
Trader sends

100

↓

Pool collects fee

↓

Pool swaps the remaining amount
```

This is why the lesson introduces two different variables.

One represents

> **The original amount sent.**

The other represents

> **The amount remaining after the fee has been deducted.**

---

# 👶 Child Analogy — Pizza Delivery App

Imagine ordering pizza.

You pay

```text
₹1000
```

The delivery app immediately takes

```text
₹50
```

as its platform fee.

The restaurant only receives

```text
₹950
```

Notice

```text
₹1000
```

and

```text
₹950
```

are different numbers.

Exactly the same thing happens here.

```text
A

↓

Fee

↓

a_in
```

---

# What Is `F`?

The lesson now introduces another variable.

```text
F
```

This simply means

> **Swap Fee Percentage**

Examples

If the fee is

```text
0.3%
```

then

```text
F = 0.003
```

If the fee is

```text
1%
```

then

```text
F = 0.01
```

Nothing complicated.

It is simply the fee percentage expressed as a decimal.

---

# How Much Fee Does The Pool Collect?

Suppose the trader sends

```text
100 X
```

Suppose the fee is

```text
1%
```

Question

How much fee should the pool collect?

Easy.

```text
100 × 1%

=

1
```

So

```text
Fee = 1 X
```

---

# General Fee Formula

Instead of writing

```text
100
```

the lesson uses

```text
A
```

Instead of writing

```text
1%
```

the lesson uses

```text
F
```

Therefore

```text
Fee = A × F
```

That's all the formula means.

It literally says

> **Fee = Original Amount × Fee Percentage**

---

# How Much Is Actually Swapped?

Originally,

the trader sent

```text
A
```

Then,

the pool removed

```text
Fee
```

Therefore,

the amount actually used for the swap is

```text
A

-

Fee
```

The lesson gives this remaining amount a name.

```text
a_in
```

Therefore

```text
a_in

=

A

-

Fee
```

---

# Replace Fee Using The Formula

Earlier we derived

```text
Fee = A × F
```

Substitute it into the equation.

```text
a_in

=

A

-

A × F
```

Now factor out

```text
A
```

Result

```text
a_in

=

A(1 - F)
```

This is one of the most important equations in the lesson.

It simply says

> **The amount actually swapped equals the original amount multiplied by the portion remaining after the fee is removed.**

---

# Does This Formula Make Sense?

Let's test it.

### Case 1 — No Fee

Suppose

```text
F = 0
```

Then

```text
1 - F = 1
```

Therefore

```text
a_in

=

A
```

Nothing was deducted.

Perfect.

---

### Case 2 — 100% Fee

This would never happen in practice,

but imagine

```text
F = 1
```

Then

```text
1 - F = 0
```

Result

```text
a_in

=

0
```

Everything was taken as the fee.

Again,

the equation behaves exactly as we expect.

---

# 📝 Mental Model

Whenever you see

```text
A
```

think

> **The trader's original input before fees.**

Whenever you see

```text
a_in
```

think

> **The amount remaining after the fee has been deducted.**

Whenever you see

```text
F
```

think

> **Swap fee percentage.**

And whenever you see

```text
Fee = A × F
```

remember

> **The fee is always calculated from the trader's original input amount, not from the remaining amount after the fee has been removed.**

---

# 📝 Key Takeaways

- This lesson explains **how Uniswap V3 calculates the swap fee**.
- The pool **does not immediately swap** the full amount sent by the trader.
- It first **collects the swap fee**, then swaps the remaining tokens.
- `A` = Original amount sent by the trader (before fees).
- `a_in` = Amount remaining after the fee is deducted.
- `F` = Swap fee percentage.
- The fee is calculated as:

```text
Fee = A × F
```

- The amount actually used for the swap is:

```text
a_in = A - Fee
```

or equivalently,

```text
a_in = A(1 - F)
```

These variables are the foundation for understanding the fee calculations later inside `SwapMath.computeSwapStep()`.