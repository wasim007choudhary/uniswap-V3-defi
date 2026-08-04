# Binary Architecture & Computation

> A comprehensive guide to understanding binary numbers, bit widths, overflow, positional values, and how computers represent numbers internally.

---

# Table of Contents

1. Maximum Value of an 8-bit Number
2. Can an 8-bit Number Store 400?
3. Binary Representation of 400
4. Understanding Overflow
5. Converting Decimal to Binary (400)
6. What Do the Zeros Mean?
7. Binary Example: Converting 25
8. How Computers Physically Read Bits
9. Two Methods of Finding Binary Numbers
10. Why Placeholder Zeros Matter
11. Example: Binary Representation of 26
12. Understanding 8-bit vs 9-bit Systems
13. Why People Write $2^8$ for 8 Bits

---

# 1. Maximum Value of an 8-bit Number

## ❓ Question

**What is the maximum number an 8-bit binary number can represent?**

## ✅ Answer

The largest value that can be represented using **8 bits** is

**255 (decimal)**

whose binary representation is

```text
11111111
```

---

## Number Types

### Unsigned Integers

Unsigned numbers do **not** reserve any bit for a sign.

Since every bit is available to store the value:

$$
2^8 = 256
$$

possible values exist.

Because counting begins at **0**, the range becomes

```text
0 → 255
```

Therefore,

$$
\boxed{\text{Maximum Unsigned Value}=2^8-1=255}
$$

---

### Signed Integers

Signed integers reserve the left-most bit (Most Significant Bit) as the **sign bit**.

```text
0xxxxxxx → Positive

1xxxxxxx → Negative
```

Only seven bits remain for the magnitude.

Therefore the positive range becomes

```text
0 → 127
```

because

$$
2^7-1=127
$$

---

## Key Takeaway

| Type | Range |
|-------|-------|
| Unsigned 8-bit | 0 → 255 |
| Signed 8-bit | -128 → 127 |

---

# 2. Can an 8-bit Number Store 400?

## ❓ Question

Can an 8-bit binary number store the decimal value **400**?

## ❌ Answer

No.

An 8-bit binary number can only represent numbers from

```text
0 → 255
```

Since

```text
400 > 255
```

there simply are not enough bits available.

---

## Why It Fails

The maximum value representable with 8 bits is

```text
255
```

Attempting to store

```text
400
```

requires an additional bit.

Without that extra bit, the computer cannot represent the complete value.

---

## What Happens?

Depending on the operation being performed:

- the value may overflow,
- the highest bit may be discarded,
- or the language/runtime may report an overflow error.

The important point is that the original value **cannot** be represented correctly inside only 8 bits.

---

## What Bit Width Is Needed?

| Bit Width | Maximum Unsigned Value |
|-----------|-----------------------:|
| 8 bits | 255 |
| 9 bits | 511 |
| 16 bits | 65,535 |

Therefore, **400 requires at least 9 bits.**

---

# 3. Binary Representation of 400

## ❓ Question

How is **400** represented in binary?

## ✅ Answer

The decimal number

```text
400
```

requires **9 bits**.

Its binary representation is

```text
110010000
```

or grouped for readability

```text
1 1001 0000
```

Notice that there are **9 binary digits**, not 8.

---

## Counting the Bits

```text
1 1001 0000
↑ ↑↑↑ ↑↑↑↑
9 total bits
```

This is why an 8-bit storage location cannot hold the number.

---

# 4. Understanding Overflow

## ❓ Question

What happens if we force a 9-bit number into an 8-bit storage location?

## Original Number

```text
1 1001 0000
```

Decimal value:

```text
400
```

---

## Step 1 — Storage Limitation

An 8-bit register only has room for

```text
xxxxxxxx
```

Eight positions.

The left-most ninth bit has nowhere to go.

---

## Step 2 — Highest Bit Gets Dropped

```text
Original

1 1001 0000

↓

Drop the first bit

1001 0000
```

The discarded bit is

```text
1
```

which represented

```text
256
```

---

## Step 3 — Remaining Value

The remaining bits are

```text
10010000
```

Let's calculate their decimal value.

```text
128 + 16 = 144
```

Therefore

```text
10010000 = 144
```

---

## Final Result

Instead of storing

```text
400
```

the computer now stores

```text
144
```

The original information has been lost.

---

> **Key Takeaway**
>
> Overflow is **not** magic.
>
> It simply means there are not enough bits available to represent the number, so the excess bits are discarded (or the operation is rejected, depending on the language and hardware).

---

# 5. Converting Decimal 400 into Binary

## ❓ Question

How do we know that **400 = 110010000**?

There are two common methods.

1. Using **binary place values (powers of 2)**
2. Using the **division-by-2 method**

We'll start with the place value method.

### Step 1 — List the Binary Columns

| Power | 2⁸ | 2⁷ | 2⁶ | 2⁵ | 2⁴ | 2³ | 2² | 2¹ | 2⁰ |
|-------:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Value |256|128|64|32|16|8|4|2|1|

---

### Step 2 — Choose the Columns That Sum to 400

We need

```text
400 = 256 + 128 + 16
```

Therefore:

| Value |256|128|64|32|16|8|4|2|1|
|------:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| Bit |1|1|0|0|1|0|0|0|0|

This gives

```text
110010000
```

---

### Step 3 — Verify

```text
256
+128
+16
----
400
```

Perfect match.

---

**End of Part 1**

---

# 6. What Do the Zeros Represent?

## ❓ Question

What do the **0s** in a binary number actually represent?

## ✅ Answer

A binary digit (**bit**) can only have one of two values:

| Bit | Meaning |
|------|----------|
| **1** | ON — Include this place value in the total |
| **0** | OFF — Do not include this place value |

Unlike decimal numbers, binary doesn't have digits from **0–9**.

Each position can only be:

```text
0
or
1
```

---

## Why Are the Zeros Important?

Although a **0** contributes nothing to the final value, it is still extremely important because it **preserves the position** of every bit.

Without the zeros, the remaining **1s** would shift into different columns and represent an entirely different number.

Think of zeros as **placeholders**.

They tell the computer:

> "Nothing exists in this column, but the column itself still exists."

---

## Example Using 400

The binary representation of **400** is

```text
110010000
```

Let's map every bit to its corresponding power of two.

```text
Value:   256   128    64    32    16     8     4     2     1
Bit:      1      1      0      0      1      0      0      0      0
```

Now calculate the decimal value.

```text
256
+128
+  0
+  0
+ 16
+  0
+  0
+  0
+  0
------
400
```

Notice something important.

The zeros contribute

```text
0
```

to the calculation,

but they still preserve the positions of every other bit.

---

## What If We Removed the Zeros?

Suppose we removed every zero.

Instead of

```text
110010000
```

we would get

```text
111
```

But

```text
111₂
```

equals

```text
7
```

not

```text
400
```

This happens because removing zeros causes every remaining bit to shift into different columns.

The positional values are completely different.

---

## Decimal Analogy

Binary works exactly like decimal numbers.

Consider the decimal number

```text
1,005
```

The zeros mean

- No hundreds
- No tens

If we remove those zeros, we get

```text
15
```

which is a completely different number.

Binary behaves the same way.

The zeros preserve the place values.

---

> **Key Takeaway**
>
> A binary **0** does not increase the value,
> but it preserves the position of every other bit.
>
> Without placeholder zeros, the number changes completely.

---

# 7. Example: Converting 25 into Binary

## ❓ Question

How do we convert **25** into binary?

## Step 1 — List the Available Columns

```text
16     8     4     2     1
```

These are simply powers of two.

| Power | 2⁴ | 2³ | 2² | 2¹ | 2⁰ |
|-------:|---:|---:|---:|---:|---:|
| Value |16|8|4|2|1|

---

## Step 2 — Find the Numbers That Add to 25

We need

```text
25 = 16 + 8 + 1
```

Therefore

- Turn ON 16
- Turn ON 8
- Turn OFF 4
- Turn OFF 2
- Turn ON 1

---

## Step 3 — Write the Bits

```text
Value:   16     8     4     2     1
Bit:      1      1      0      0      1
```

The final binary number is

```text
11001
```

---

## Verification

```text
16
+8
+1
---
25
```

Correct.

---

## Visual Representation

```text
Value : 16     8     4     2     1

Bits  :  1     1     0     0     1
```

Everything marked **1** contributes to the final total.

Everything marked **0** contributes nothing.

---

# 8. How Computers Physically Read Bits

## ❓ Question

How does a computer actually understand the binary number **11001**?

## ✅ Answer

Computers do **not** understand:

- Numbers
- Mathematics
- Symbols
- Text

Instead, computers are built from billions of microscopic electronic switches called **transistors**.

Each transistor has only two possible physical states.

| Binary | Physical State |
|---------|----------------|
| **1** | ON (electricity flows) |
| **0** | OFF (electricity blocked) |

---

## Visual Representation

```text
Bit

1      1      0      0      1

↓

Switch

[ON]  [ON]  [OFF]  [OFF]  [ON]
```

When the processor reads

```text
11001
```

it is **not reading the number twenty-five**.

Instead it observes a pattern of electrical signals.

```text
Pulse

Pulse

No Pulse

No Pulse

Pulse
```

Only after interpreting those electrical states does the processor understand that the value represented is

```text
25
```

---

> **Important**
>
> Binary is simply a convenient way for humans to describe electrical ON/OFF states.
>
> The hardware itself only sees voltage levels.

---

# 9. Two Methods for Finding Binary Numbers

## ❓ Question

When converting **25**, why does the division method begin with

```text
25 ÷ 2 = 12 remainder 1
```

instead of

```text
16
```

How do both methods produce the same answer?

---

## Method 1 — Division by 2

Repeatedly divide the number by 2.

Record each remainder.

```text
25 ÷ 2 = 12 remainder 1

12 ÷ 2 = 6 remainder 0

6 ÷ 2 = 3 remainder 0

3 ÷ 2 = 1 remainder 1

1 ÷ 2 = 0 remainder 1
```

Now read the remainders **from bottom to top**.

```text
11001
```

That is the binary representation of **25**.

---

## Method 2 — Place Value Method

Instead of dividing,

look at the powers of two.

```text
16

8

4

2

1
```

Choose the values that sum to

```text
25
```

```text
16 + 8 + 1 = 25
```

Now write

```text
16    8    4    2    1

 1    1    0    0    1
```

Result

```text
11001
```

---

## Why Do Both Methods Work?

Although the procedures are different,

both are describing the exact same binary representation.

| Division Method | Place Value Method |
|-----------------|--------------------|
| Divide by 2 repeatedly | Add powers of two |
| Record remainders | Choose columns |
| Read upward | Write ON/OFF bits |
| Result = `11001` | Result = `11001` |

Both methods always produce the same binary number.

---

> **Key Takeaway**
>
> The **division method** is an algorithm.
>
> The **place-value method** is a visual explanation.
>
> They solve the same problem using different approaches.

---

#  Why Do We Put `0` in Unused Columns?

## ❓ Question

If a column is **not needed** when representing a number, why do we put a **0** there instead of removing the column?

## ✅ Answer

In binary, **every column represents a fixed power of 2**.

Even if a particular column is not needed, it **still exists**. Instead of removing it, we place a **0** in that position to indicate that the value from that column is **not included**.

Removing the column would shift all the remaining bits to different positions, changing the value completely.

---

## Example — Representing 26

Let's represent the decimal number **26** using binary.

### Step 1 — Choose the Required Columns

We need:

```text
26 = 16 + 8 + 2
```

Looking at our binary columns:

| Value | 16 | 8 | 4 | 2 | 1 |
|------:|---:|--:|--:|--:|--:|
| Bit   | 1  | 1 | 0 | 1 | 0 |

---

### Step 2 — Write the Binary Number

```text
Value : 16    8    4    2    1

Bits  :  1    1    0    1    0
```

Therefore, the binary representation of **26** is

```text
11010
```

---

## Why Isn't the Last Column Removed?

Notice that we didn't need the **1** column.

Instead of deleting it, we write:

```text
0
```

This tells the computer:

> "The 1's place exists, but it is turned OFF."

If we removed that column completely, the remaining bits would shift to the right and represent a different number.

---

> **Key Takeaway**
>
> Binary columns are **fixed positions**. You never remove a column simply because its value isn't needed. Instead, you place a **0** in that position to indicate that the column is **OFF** while preserving the correct place values for every other bit.