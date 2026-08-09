# Dissection — Uniswap V3 Swap Fee (Part 2 — Exact Out)

---

# 🎯 What Happens After We Understand `A`, `a_in`, and the Fee?

In the previous part, we learned:

- `A` = Original amount sent by the trader (before fees)
- `a_in` = Amount actually used for the swap (after fees)
- `F` = Swap fee percentage

We also derived

```text
Fee = A × F
```

and

```text
a_in = A(1 - F)
```

Now the next question is:

> **How does the pool actually calculate the fee during a swap?**

Before answering that, the lesson introduces two different swap modes.

---

# Two Types Of Swaps

Uniswap V3 supports two ways of swapping.

---

## 1. Exact In

The trader specifies

```text
Exactly how many input tokens they want to send.
```

Example

```text
I will send

100 USDC

↓

How much WETH do I receive?
```

The trader fixes the **input**.

The pool calculates the **output**.

---

## 2. Exact Out

The trader specifies

```text
Exactly how many output tokens they want.
```

Example

```text
I want

1 WETH

↓

How many USDC must I pay?
```

The trader fixes the **output**.

The pool calculates the **input**.

---

# 👶 Child Analogy — Buying Chocolates

Imagine chocolates have changing prices.

---

## Exact In

You walk into the shop and say

```text
I have ₹100.

Give me as many chocolates as possible.
```

The money is fixed.

The shopkeeper calculates the chocolates.

---

## Exact Out

Instead,

you say

```text
I want exactly

10 chocolates.
```

Now,

the chocolates are fixed.

The shopkeeper calculates how much money you must pay.

Exactly the same thing happens in Uniswap.

---

# Why Does The Lesson Suddenly Split Into Two Cases?

Because the fee calculation depends on

> **Which quantity is already known.**

For

```text
Exact In
```

the pool already knows

```text
Amount In
```

and must calculate

```text
Amount Out

↓

Fee
```

---

For

```text
Exact Out
```

the pool already knows

```text
Amount Out
```

and must calculate

```text
Amount In

↓

Fee
```

Notice

the order is reversed.

---

# Why Does The Instructor Start With Exact Out?

Many people expect the lesson to begin with Exact In.

Instead,

the instructor starts with Exact Out.

Why?

Because before calculating the fee,

the pool first needs to determine

> **How much input is required to produce the requested output.**

Only after knowing the required input

can it calculate the fee.

---

# Exact Out — Think Like The Pool

Suppose you tell the pool

```text
I want exactly

50 Y
```

Notice something.

You did NOT say

```text
I'll pay

100 X.
```

Instead,

you fixed the OUTPUT.

---

# 👶 Child Analogy — Buying Mangoes

Imagine going to a fruit shop.

You don't say

```text
I'll spend ₹100.
```

Instead,

you say

```text
I want exactly

5 mangoes.
```

Now,

the shopkeeper has to calculate

how much money you must pay.

Exactly what Uniswap does.

---

# What Does The Pool Already Know?

The pool knows

```text
Trader Wants

50 Y
```

Now it asks

```text
How much X

must I receive?
```

But before answering,

it asks another question.

---

# First Question

Can the current liquidity even provide

```text
50 Y?
```

Earlier,

we learned about

```text
Maximum Amount Out
```

Suppose

```text
Maximum Amount Out

=

80 Y
```

Can the pool provide

```text
50 Y?
```

Yes.

The swap finishes inside the current liquidity range.

---

Now suppose

```text
Maximum Amount Out

=

30 Y
```

Can the pool provide

```text
50 Y?
```

No.

The pool first empties this liquidity,

reaches

```text
Pa
```

crosses the initialized tick,

activates the next liquidity,

and continues the swap.

This is exactly why

Maximum Amount Out

is calculated FIRST.

---

# What Is Maximum Amount Out?

Imagine the current price is

```text
$6
```

inside this liquidity range.

```text
$4 ----------- $6 ----------- $8
                ▲
          Current Price
```

As more Token X enters,

more Token Y leaves.

```text
More X

↓

More Y Leaves

↓

Price Moves LEFT
```

Eventually,

the price reaches

```text
Pa
```

(the lower boundary).

At that moment,

all liquidity has become

```text
Token X
```

There is no Token Y left inside this liquidity range.

Therefore,

there is a maximum amount of Token Y

that can ever leave this liquidity.

That amount is called

```text
Maximum Amount Out
```

---

# 👶 Child Analogy — Juice Box

Imagine a juice box.

```text
🥤
```

You keep drinking.

```text
Sip

↓

Sip

↓

Sip
```

Eventually,

the juice box becomes empty.

Question:

Can you drink more juice from that same box?

No.

There isn't any juice left.

Exactly the same thing happens with Token Y.

Eventually,

all Token Y is swapped out,

and the price reaches

```text
Pa.
```

---

# Another Way To Think About It

Suppose this liquidity currently contains

```text
500 Y
```

Question

Can

```text
600 Y
```

leave?

Impossible.

You cannot remove

more tokens than exist.

So

```text
Maximum Amount Out

≤

Current Token Y Inside This Liquidity
```

---

# What Is The Pool Really Calculating?

Before continuing the swap,

the pool asks

> **How much Token Y can possibly leave THIS liquidity position before I hit Pa?**

That answer is

```text
Maximum Amount Out
```

---

# Why Does The Pool Need This Number?

Suppose the trader wants

```text
50 Y
```

Maximum Amount Out

is

```text
200 Y
```

No problem.

The swap finishes inside this liquidity.

---

Suppose the trader wants

```text
500 Y
```

Maximum Amount Out

is only

```text
200 Y
```

Now,

the pool reaches

```text
Pa
```

before satisfying the trader.

It must

- consume all remaining liquidity,
- cross the initialized tick,
- activate the next liquidity,
- continue the swap.

---

# 👶 Child Analogy — Water Bucket

Imagine a bucket containing

```text
10 Liters
```

Someone asks for

```text
4 Liters
```

Easy.

Water still remains.

---

Now someone asks for

```text
15 Liters.
```

Impossible.

You empty the first bucket.

Then,

if another bucket exists,

you continue taking water from it.

Exactly how Uniswap crosses liquidity ranges.

---

# Once The Pool Knows The Swap Is Possible...

Suppose the trader wants

```text
50 Y
```

The pool now calculates

```text
How much X

must actually be swapped?
```

This amount is

```text
a_in
```

Notice carefully.

It is NOT

```text
A
```

It is

```text
a_in
```

because

this is the amount **AFTER the fee has already been removed.**

This is the amount actually used to perform the swap.

---

# Why Isn't It `A`?

Remember the previous lesson.

```text
Trader Sends

↓

A

↓

Fee Removed

↓

a_in

↓

Swap Happens
```

The swap always uses

```text
a_in
```

Never

```text
A
```

Therefore,

the pool first calculates

```text
a_in
```

because that is the amount actually required to produce

```text
50 Y.
```

---

# 👶 Child Analogy — Pizza Again

Suppose the restaurant needs

```text
₹950
```

to prepare the pizza.

Should the customer pay

```text
₹950?
```

No.

Because

the delivery platform also needs its fee.

Therefore,

the customer must pay

more than

```text
₹950.
```

Exactly the same thing happens here.

---

# The Pool Thinks Like This

"I know I need"

```text
97 X
```

to perform the swap.

"But the trader can't simply send

97 X,

because I still need to collect my fee."

So,

the pool works backwards.

---

# Working Backwards

Earlier,

we derived

```text
a_in = A(1-F)
```

Now notice.

The pool knows

```text
a_in
```

It knows

```text
F
```

Unknown

```text
A
```

So it rearranges the equation.

Divide both sides by

```text
1-F
```

Result

```text
A

=

a_in

/

(1-F)
```

Now,

the pool knows

how much the trader must originally send.

---

# Finally Calculate The Fee

Earlier,

we also derived

```text
Fee = A × F
```

Replace

```text
A
```

using the equation we just found.

Result

```text
Fee

=

(a_in / (1-F))

×

F
```

This is exactly the fee equation shown in the lesson.

---

# 👶 Child Analogy — Reverse Engineering

Suppose,

after tax,

the government receives

```text
₹95.
```

Question

How much money

did the customer originally pay?

You work backwards.

Exactly what the pool is doing.

It already knows

how much is actually needed

for the swap.

Now,

it works backwards

to recover

the trader's original payment.

---

# Why Doesn't The Pool Calculate The Fee First?

Because

it doesn't yet know

how much the trader must pay.

Instead,

the sequence is

```text
Calculate

a_in

↓

Calculate

A

↓

Calculate

Fee
```

The fee comes LAST.

---

# Complete Flow For Exact Out

```text
Trader Says

↓

I Want Exactly

50 Y

↓

Calculate

Maximum Amount Out

↓

Can Current Liquidity Provide It?

↓

YES

↓

Calculate

a_in

↓

Calculate

A

↓

Calculate

Fee

↓

Execute Swap
```

This matches the lesson's statement:

```text
Find Maximum Amount Out

↓

Calculate a_out

↓

Calculate a_in

↓

Calculate Fee
```

The fee is calculated last because only after determining how much input is actually needed (`a_in`) can the pool work backwards to determine the trader's original payment (`A`) and finally compute the fee.

---

# 📝 Key Takeaways

- Uniswap supports **Exact In** and **Exact Out** swaps.
- In **Exact Out**, the trader fixes the output amount.
- Before calculating the fee, the pool first checks the **Maximum Amount Out** available in the current liquidity.
- If the requested output exceeds the maximum available, the pool crosses the next initialized tick and continues with the next liquidity range.
- Once the required output is known, the pool calculates:
  1. `a_in` (actual amount used for the swap)
  2. `A` (original amount the trader must send)
  3. `Fee`
- The fee is calculated using

```text
Fee = (a_in / (1 - F)) × F
```

which is simply the result of working backwards from

```text
a_in = A(1 - F)
```

---

---

---
---

# 💡 A Simpler Way To Think About It

While studying this, I had a question:

> **Shouldn't `A` simply equal `a_in + Fee`?**

Yes!

That is actually the most intuitive way to think about it.

Remember the flow.

```text
Trader Sends

↓

A

↓

Pool Collects Fee

↓

a_in

↓

Swap Happens
```

Since the pool removes the fee from the original amount,

it is obvious that

```text
A = a_in + Fee
```

Example

Suppose

```text
A = 100 X
```

Fee

```text
= 3 X
```

Then

```text
a_in = 97 X
```

Check it.

```text
A

=

a_in + Fee

=

97 + 3

=

100 ✅
```

So why doesn't Uniswap simply use this equation?

Because during the calculation,

the pool **doesn't know the fee yet.**

It only knows:

- `a_in` (the amount actually needed for the swap)
- `F` (the fee percentage)

The fee itself is still unknown.

Writing

```text
A = a_in + Fee
```

doesn't help,

because `Fee` is one of the unknowns we're trying to find.

Instead,

the pool uses another equation that we already know:

```text
Fee = A × F
```

Now substitute it into

```text
A = a_in + Fee
```

```text
A = a_in + A × F
```

Move everything involving `A` to one side.

```text
A - A × F = a_in
```

Factor out `A`.

```text
A(1 - F) = a_in
```

Finally,

divide by

```text
1 - F
```

and we get

```text
A = a_in / (1 - F)
```

This is exactly the equation derived in the lesson.

So there are **two perfectly equivalent ways** to think about it.

### Intuitive View

```text
A = a_in + Fee
```

This is the easiest way to understand what's happening conceptually.

### Mathematical View

```text
A = a_in / (1 - F)
```

This is the version Uniswap actually uses because it can calculate `A` using only the values it already knows (`a_in` and `F`).

So whenever you see

```text
A = a_in / (1 - F)
```

remember that it is simply the mathematical version of the much more intuitive idea:

```text
Original Amount

=

Amount Used For Swap

+

Fee
```

Nothing more.