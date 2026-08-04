# Why Does `mulDivRoundingUp()` Return `17` Instead of `16`?
>**Important:** Check the comments and natspecs added in the functions also for ones own betterment

One question often comes up:

> **If the exact answer is `16.1`, why does `mulDivRoundingUp()` return `17`? Isn't that wrong?**

The answer is **no**.

It is doing exactly what it was designed to do.

---

# There Are Three Different Answers

Suppose the exact mathematical result is

```text
16.1
```

There are three possible ways to represent this value.

### 1. Real Mathematics

```text
16.1
```

This is the exact answer.

However, Solidity cannot represent decimal numbers like `16.1`.

---

### 2. Floor (Round Down)

This is what `mulDiv()` returns.

```text
floor(16.1)

=

16
```

It always returns the **largest whole integer less than or equal to the exact value.**

---

### 3. Ceiling (Round Up)

This is what `mulDivRoundingUp()` returns.

```text
ceil(16.1)

=

17
```

It always returns the **smallest whole integer greater than or equal to the exact value.**

---

# So Is `17` Wrong?

No.

It is mathematically correct because

```text
ceil(16.1)

=

17
```

Just as

```text
floor(16.1)

=

16
```

Both are correct.

They simply answer different questions.

---

# Child Analogy

Imagine each box can hold

```text
10 apples.
```

You have

```text
161 apples.
```

The calculation becomes

```text
161 ÷ 10

=

16.1
```

Can you buy

```text
16.1 boxes?
```

No.

Boxes must be whole numbers.

---

## If You Want To Know How Many Full Boxes Exist

You count only the completely filled boxes.

```text
16.1

↓

16 full boxes
```

This is exactly what

```text
mulDiv()
```

returns.

---

## If You Want To Know How Many Boxes You Must Buy

Buying only

```text
16
```

boxes holds only

```text
160 apples.
```

One apple has nowhere to go.

Therefore you must buy

```text
17 boxes.
```

This is exactly what

```text
mulDivRoundingUp()
```

returns.

---

# Why Does Uniswap Need Both?

Different calculations require different rounding directions.

Sometimes the protocol needs

```text
Round Down (Floor)
```

to count only complete units.

Other times it needs

```text
Round Up (Ceiling)
```

to ensure enough value, liquidity, or tokens are accounted for.

Neither function is "more correct."

They simply solve different problems.

---

# Key Takeaways

* `mulDiv()` returns:

```text
floor(a × b ÷ denominator)
```

* `mulDivRoundingUp()` returns:

```text
ceil(a × b ÷ denominator)
```

* If the exact answer is

```text
16.1
```

then

```text
floor(16.1) = 16
```

and

```text
ceil(16.1) = 17
```

Both are mathematically correct.

The only difference is the rounding direction.
---
---
# Why `result++` Does **Not** Mean `16.9 → 17.9`

A common misunderstanding is thinking that

```solidity
result++;
```

adds `1` to the original decimal value.

For example:

> If the exact answer is `16.9`, doesn't `result++` make it `17.9`?

The answer is **No**.

This is because **`result` never stores the decimal value in the first place.**

---

# Step 1 — The Exact Mathematical Answer

Suppose the real mathematical result is

```text
16.9
```

This is the true value of

```text
a × b ÷ denominator
```

However,

Solidity cannot store decimal numbers like

```text
16.9
```

It only stores integers.

---

# Step 2 — `mulDiv()` Is Called

The first line inside `mulDivRoundingUp()` is

```solidity
result = mulDiv(a, b, denominator);
```

Recall that

```text
mulDiv()
```

always returns the **floor**.

So instead of storing

```text
16.9
```

it stores

```text
16
```

The decimal part

```text
0.9
```

is discarded because integers cannot represent fractions.

At this point,

```text
result = 16
```

---

# Step 3 — Check For A Remainder

Next,

the function checks

```solidity
if (mulmod(a, b, denominator) > 0)
```

This simply asks

> **"Was there any fractional part?"**

For our example,

the answer is

```text
Yes
```

because the exact result was

```text
16.9
```

---

# Step 4 — Increment The Integer

Now the function executes

```solidity
result++;
```

Remember,

`result` currently contains

```text
16
```

Therefore,

the increment becomes

```text
16

↓

17
```

Notice something important.

The function is **not** doing

```text
16.9

↓

17.9
```

because

```text
16.9
```

never existed inside

```text
result.
```

The decimal value was already converted into

```text
16
```

by `mulDiv()`.

---

# Complete Flow

Suppose the exact answer is

```text
16.9
```

The execution becomes

```text
Exact Answer

16.9

↓

mulDiv()

↓

16

↓

Remainder Exists?

↓

Yes

↓

result++

↓

17
```

At no point does the variable

```text
result
```

contain

```text
16.9.
```

---

# Another Example

Suppose the exact answer is

```text
16.1
```

Execution:

```text
Exact Answer

16.1

↓

mulDiv()

↓

16

↓

Remainder Exists?

↓

Yes

↓

result++

↓

17
```

Again,

the function simply moves from the current integer

```text
16
```

to the next integer

```text
17.
```

---

# Child Analogy

Imagine a staircase.

The exact answer is somewhere between two steps.

Example:

```text
16.9
```

It lies between

```text
Step 16

and

Step 17.
```

`mulDiv()` places you on

```text
Step 16.
```

Now `result++` simply tells you

> **"Climb one more step."**

So you move to

```text
Step 17.
```

You were never standing at

```text
16.9
```

because the staircase only has whole-number steps.

---

# Key Takeaways

* `result++` always adds **1** to an **integer**.
* `result` never stores the exact decimal value.
* `mulDiv()` already converted the exact result into its floor.
* Therefore:

```text
16.9

↓

mulDiv()

↓

16

↓

result++

↓

17
```

* The function does **not** perform:

```text
16.9

↓

17.9
```

because decimals are never stored inside `result`.
